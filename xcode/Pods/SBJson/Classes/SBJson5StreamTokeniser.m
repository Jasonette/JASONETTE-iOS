//
// Created by SuperPappi on 09/01/2013.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SBJson5StreamTokeniser.h"

#define SBStringIsIllegalSurrogateHighCharacter(character) (((character) >= 0xD800UL) && ((character) <= 0xDFFFUL))
#define SBStringIsSurrogateLowCharacter(character) ((character >= 0xDC00UL) && (character <= 0xDFFFUL))
#define SBStringIsSurrogateHighCharacter(character) ((character >= 0xD800UL) && (character <= 0xDBFFUL))

@implementation SBJson5StreamTokeniser {
    NSMutableData *data;
    const char *bytes;
    NSUInteger index;
    NSUInteger offset;
}

- (void)setError:(NSString *)error {
    _error = [NSString stringWithFormat:@"%@ at index %lu", error, (unsigned long)(offset + index)];
}

- (void)appendData:(NSData *)data_ {
    if (!data) {
        data = [data_ mutableCopy];

    } else if (index) {
        // Discard data we've already parsed
        [data replaceBytesInRange:NSMakeRange(0, index) withBytes:"" length:0];
        [data appendData:data_];

        // Add to the offset for reporting
        offset += index;

        // Reset index to point to current position
        index = 0u;

    }
    else {
       [data appendData:data_];
    }

    bytes = [data bytes];
}

- (void)skipWhitespace {
    while (index < data.length) {
        switch (bytes[index]) {
            case ' ':
            case '\t':
            case '\r':
            case '\n':
                index++;
            break;
            default:
                return;
        }
    }
}

- (BOOL)getUnichar:(unichar *)ch {
    if ([self haveRemainingBytes:1]) {
        *ch = (unichar) bytes[index];
        return YES;
    }
    return NO;
}

- (BOOL)haveOneMoreByte {
    return [self haveRemainingBytes:1];
}

- (BOOL)haveRemainingBytes:(NSUInteger)length {
    return data.length - index >= length;
}

- (sbjson5_token_t)match:(char *)str retval:(sbjson5_token_t)tok token:(char **)token length:(NSUInteger *)length {
    NSUInteger len = strlen(str);
    if ([self haveRemainingBytes:len]) {
        if (!memcmp(bytes + index, str, len)) {
            *token = str;
            *length = len;
            index += len;
            return tok;
        }
        [self setError: [NSString stringWithFormat:@"Expected '%s' after initial '%.1s'", str, str]];
        return sbjson5_token_error;
    }

    return sbjson5_token_eof;
}

- (BOOL)decodeHexQuad:(unichar*)quad {
    unichar tmp = 0;

    for (int i = 0; i < 4; i++, index++) {
        unichar c = (unichar)bytes[index];
        tmp *= 16;
        switch (c) {
            case '0' ... '9':
                tmp += c - '0';
                break;

            case 'a' ... 'f':
                tmp += 10 + c - 'a';
                break;

            case 'A' ... 'F':
                tmp += 10 + c - 'A';
                break;

            default:
                return NO;
        }
    }
    *quad = tmp;
    return YES;
}

- (sbjson5_token_t)getStringToken:(char **)token length:(NSUInteger *)length {

    // Skip initial "
    index++;

    NSUInteger string_start = index;
    sbjson5_token_t tok = sbjson5_token_string;

    for (;;) {
        if (![self haveOneMoreByte])
            return sbjson5_token_eof;

        switch ((uint8_t)bytes[index]) {
            case 0 ... 0x1F:
                [self setError:[NSString stringWithFormat:@"Unescaped control character [0x%0.2hhX] in string", bytes[index]]];
                return sbjson5_token_error;

            case '"':
                *token = (char *)(bytes + string_start);
                *length = index - string_start;
                index++;
                return tok;

            case '\\':
                tok = sbjson5_token_encoded;
                index++;
                if (![self haveOneMoreByte])
                    return sbjson5_token_eof;

                if (bytes[index] == 'u') {
                    index++;
                    if (![self haveRemainingBytes:4])
                        return sbjson5_token_eof;

                    unichar hi;
                    if (![self decodeHexQuad:&hi]) {
                        [self setError:@"Invalid hex quad"];
                        return sbjson5_token_error;
                    }

                    if (SBStringIsSurrogateHighCharacter(hi)) {
                        if (![self haveRemainingBytes:6])
                            return sbjson5_token_eof;

                        unichar lo;
                        if (bytes[index++] != '\\' || bytes[index++] != 'u' || ![self decodeHexQuad:&lo]) {
                            [self setError:@"Missing low character in surrogate pair"];
                            return sbjson5_token_error;
                        }

                        if (!SBStringIsSurrogateLowCharacter(lo)) {
                            [self setError:@"Invalid low character in surrogate pair"];
                            return sbjson5_token_error;
                        }

                    } else if (SBStringIsIllegalSurrogateHighCharacter(hi)) {
                        [self setError:@"Invalid high character in surrogate pair"];
                        return sbjson5_token_error;

                    }


                } else {
                    switch (bytes[index]) {
                        case '\\':
                        case '/':
                        case '"':
                        case 'b':
                        case 'n':
                        case 'r':
                        case 't':
                        case 'f':
                            index++;
                            break;

                        default:
                            [self setError:[NSString stringWithFormat:@"Illegal escape character [0x%0.2hhX]", bytes[index]]];
                            return sbjson5_token_error;
                    }
                }

                break;

            case 0x80 ... 0xBF:
                [self setError:[NSString stringWithFormat: @"Unexpected UTF-8 continuation byte [0x%0.2hhX]", bytes[index]]];
                return sbjson5_token_error;

            case 0xC0 ... 0xC1:
            case 0xF5 ... 0xFF:
                // Flat out illegal UTF-8 bytes, see
                // https://en.wikipedia.org/wiki/UTF-8#Codepage_layout
                [self setError:[NSString stringWithFormat: @"Illegal UTF-8 byte [0x%0.2hhX]", bytes[index]]];
                return sbjson5_token_error;
                break;

            case 0xC2 ... 0xDF:
                // Expecting 1 continuation byte
                index++;
                if (![self haveOneMoreByte]) return sbjson5_token_eof;
                if (![self isContinuationByte]) return sbjson5_token_error;
                index++;
                break;

            case 0xE0 ... 0xEF: {
                // Expecting 2 continuation bytes
                long cp = bytes[index] & 0x0F;
                index++;
                for (NSUInteger i = 0; i < 2; i++) {
                    if (![self haveOneMoreByte]) return sbjson5_token_eof;
                    if (![self isContinuationByte]) return sbjson5_token_error;
                    cp = cp << 6 | (bytes[index] & 0x3F);
                    index++;
                }

                if (!(cp & 0b1111100000000000)) {
                    [self setError:[NSString stringWithFormat:@"Illegal overlong encoding [0x%0.2hhX %0.2hhX %0.2hhX]",
                                    bytes[index-3], bytes[index-2], bytes[index-1]]];
                    return sbjson5_token_error;
                }

                if ([self isInvalidCodePoint:cp])
                    return sbjson5_token_error;

                break;
            }

            case 0xF0 ... 0xF4: {
                // Expecting 3 continuation bytes
                long cp = bytes[index] & 0x07;
                index++;
                for (NSUInteger i = 0; i < 3; i++) {
                    if (![self haveOneMoreByte]) return sbjson5_token_eof;
                    if (![self isContinuationByte]) return sbjson5_token_error;
                    cp = cp << 6 | (bytes[index] & 0x3F);
                    index++;
                }

                if (!(cp & 0b111110000000000000000)) {
                    [self setError:[NSString stringWithFormat:@"Illegal overlong encoding [0x%0.2hhX %0.2hhX %0.2hhX %0.2hhX]",
                                    bytes[index-4], bytes[index-3], bytes[index-2], bytes[index-1]]];
                    return sbjson5_token_error;
                }

                if ([self isInvalidCodePoint:cp])
                    return sbjson5_token_error;

                break;
            }

            default:
                index++;
                break;
        }
    }
}

- (BOOL)isInvalidCodePoint:(long)cp {
    if (cp > 0x10FFFF || SBStringIsSurrogateLowCharacter(cp) || SBStringIsSurrogateHighCharacter(cp)) {
        [self setError:[NSString stringWithFormat:@"Illegal Unicode code point [0x%lX]", cp]];
        return YES;
    }
    return NO;
}

- (BOOL)isContinuationByte {
    if ((bytes[index] & 0b11000000) != 0b10000000) {
        [self setError:[NSString stringWithFormat:@"Missing UTF-8 continuation byte; found [0x%0.2hhX]", bytes[index]]];
        return NO;
    }
    return YES;
}

- (sbjson5_token_t)getNumberToken:(char **)token length:(NSUInteger *)length {
    NSUInteger num_start = index;
    if (bytes[index] == '-') {
        index++;

        if (![self haveOneMoreByte])
            return sbjson5_token_eof;
    }

    sbjson5_token_t tok = sbjson5_token_integer;
    if (bytes[index] == '0') {
        index++;

        if (![self haveOneMoreByte])
            return sbjson5_token_eof;

        if (isdigit(bytes[index])) {
            [self setError:@"Leading zero is illegal in number"];
            return sbjson5_token_error;
        }
    }

    while (isdigit(bytes[index])) {
        index++;
        if (![self haveOneMoreByte])
            return sbjson5_token_eof;
    }

    if (![self haveOneMoreByte])
        return sbjson5_token_eof;


    if (bytes[index] == '.') {
        index++;
        tok = sbjson5_token_real;

        if (![self haveOneMoreByte])
            return sbjson5_token_eof;

        NSUInteger fraction_start = index;
        while (isdigit(bytes[index])) {
            index++;
            if (![self haveOneMoreByte])
                return sbjson5_token_eof;
        }

        if (fraction_start == index) {
            [self setError:@"No digits after decimal point"];
            return sbjson5_token_error;
        }
    }

    if (bytes[index] == 'e' || bytes[index] == 'E') {
        index++;
        tok = sbjson5_token_real;

        if (![self haveOneMoreByte])
            return sbjson5_token_eof;

        if (bytes[index] == '-' || bytes[index] == '+') {
            index++;
            if (![self haveOneMoreByte])
                return sbjson5_token_eof;
        }

        NSUInteger exp_start = index;
        while (isdigit(bytes[index])) {
            index++;
            if (![self haveOneMoreByte])
                return sbjson5_token_eof;
        }

        if (exp_start == index) {
            [self setError:@"No digits in exponent"];
            return sbjson5_token_error;
        }

    }

    if (num_start + 1 == index && bytes[num_start] == '-') {
        [self setError:@"No digits after initial minus"];
        return sbjson5_token_error;
    }

    *token = (char *)(bytes + num_start);
    *length = index - num_start;
    return tok;
}


- (sbjson5_token_t)getToken:(char **)token length:(NSUInteger *)length {
    [self skipWhitespace];
    NSUInteger copyOfIndex = index;

    unichar ch;
    if (![self getUnichar:&ch])
        return sbjson5_token_eof;

    sbjson5_token_t tok;
    switch (ch) {
        case '{': {
            index++;
            tok = sbjson5_token_object_open;
            break;
        }
        case '}': {
            index++;
            tok = sbjson5_token_object_close;
            break;

        }
        case '[': {
            index++;
            tok = sbjson5_token_array_open;
            break;

        }
        case ']': {
            index++;
            tok = sbjson5_token_array_close;
            break;

        }
        case 't': {
            tok = [self match:"true" retval:sbjson5_token_bool token:token length:length];
            break;

        }
        case 'f': {
            tok = [self match:"false" retval:sbjson5_token_bool token:token length:length];
            break;

        }
        case 'n': {
            tok = [self match:"null" retval:sbjson5_token_null token:token length:length];
            break;

        }
        case ',': {
            index++;
            tok = sbjson5_token_value_sep;
            break;

        }
        case ':': {
            index++;
            tok = sbjson5_token_entry_sep;
            break;

        }
        case '"': {
            tok = [self getStringToken:token length:length];
            break;

        }
        case '-':
        case '0' ... '9': {
            tok = [self getNumberToken:token length:length];
            break;

        }
        case '+': {
            self.error = @"Leading + is illegal in number";
            tok = sbjson5_token_error;
            break;

        }
        default: {
            self.error = [NSString stringWithFormat:@"Illegal start of token [%c]", ch];
            tok = sbjson5_token_error;
            break;
        }
    }

    if (tok == sbjson5_token_eof) {
        // We ran out of bytes before we could finish parsing the current token.
        // Back up to the start & wait for more data.
        index = copyOfIndex;
    }

    return tok;
}

@end
