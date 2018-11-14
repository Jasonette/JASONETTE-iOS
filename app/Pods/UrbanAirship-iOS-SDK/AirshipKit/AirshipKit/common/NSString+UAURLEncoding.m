/* Copyright 2017 Urban Airship and Contributors */

#import "NSString+UAURLEncoding.h"

@implementation NSString(UAURLEncoding)

- (NSString *)urlDecodedStringWithEncoding:(NSStringEncoding)encoding {
    /*
     * Taken from http://madebymany.com/blog/url-encoding-an-nsstring-on-ios
     */
    CFStringRef result = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                 (CFStringRef)self,
                                                                                 CFSTR(""),
                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding));

    /* autoreleased string */
    NSString *value = [NSString stringWithString:(NSString *)CFBridgingRelease(result)];

    return value;
}

- (NSString *)urlEncodedStringWithEncoding:(NSStringEncoding)encoding {
    CFStringRef result = CFURLCreateStringByAddingPercentEscapes(
                                                                 NULL,
                                                                 (CFStringRef)self,
                                                                 NULL,
                                                                 (CFStringRef)@"~!*\"'();:@&=+$,/?%#[]",
                                                                 CFStringConvertNSStringEncodingToEncoding(encoding));

    NSString *value = [NSString stringWithString:(NSString *)CFBridgingRelease(result)];
    return value;
}

- (nullable NSString *)urlDecodedString {
    return [self stringByRemovingPercentEncoding];
}

- (nullable NSString *)urlEncodedString {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}

@end
