/*
 Copyright (c) 2010-2013, Stig Brautaset.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

   Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

   Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

   Neither the name of the the author nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if !__has_feature(objc_arc)
#error "This source file must be compiled with ARC enabled!"
#endif

#import "SBJson5StreamParserState.h"

#define SINGLETON                                           \
    + (id)sharedInstance {                                  \
        static id state = nil;                              \
        if (!state) {                                       \
            @synchronized(self) {                           \
                if (!state) state = [[self alloc] init];    \
            }                                               \
        }                                                   \
        return state;                                       \
    }

@implementation SBJson5StreamParserState

+ (id)sharedInstance { return nil; }

- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
    return NO;
}

- (SBJson5ParserStatus)parserShouldReturn:(SBJson5StreamParser *)parser {
    return SBJson5ParserWaitingForData;
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {}

- (BOOL)needKey {
    return NO;
}

- (NSString*)name {
    return @"<aaiie!>";
}

- (BOOL)isError {
    return NO;
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateStart

SINGLETON

- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
    switch (token) {
    case sbjson5_token_object_open:
    case sbjson5_token_array_open:
    case sbjson5_token_bool:
    case sbjson5_token_null:
    case sbjson5_token_integer:
    case sbjson5_token_real:
    case sbjson5_token_string:
    case sbjson5_token_encoded:
        return YES;

    default:
        return NO;
	}
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {

    SBJson5StreamParserState *state = nil;
    switch (tok) {
    case sbjson5_token_array_open:
        state = [SBJson5StreamParserStateArrayStart sharedInstance];
        break;

    case sbjson5_token_object_open:
        state = [SBJson5StreamParserStateObjectStart sharedInstance];
        break;

    case sbjson5_token_array_close:
    case sbjson5_token_object_close:
        if ([parser.delegate respondsToSelector:@selector(parserShouldSupportManyDocuments)] && [parser.delegate parserShouldSupportManyDocuments])
            state = parser.state;
        else
            state = [SBJson5StreamParserStateComplete sharedInstance];
        break;

    case sbjson5_token_eof:
        return;

    default:
        break;
    }

	parser.state = state;
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateComplete

SINGLETON

- (NSString*)name { return @"after complete json"; }

- (SBJson5ParserStatus)parserShouldReturn:(SBJson5StreamParser *)parser {
	return SBJson5ParserComplete;
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateError

SINGLETON

- (NSString*)name { return @"in error"; }

- (SBJson5ParserStatus)parserShouldReturn:(SBJson5StreamParser *)parser {
	return SBJson5ParserError;
}

- (BOOL)isError {
    return YES;
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateObjectStart

SINGLETON

- (NSString*)name { return @"at beginning of object"; }

- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
	switch (token) {
		case sbjson5_token_object_close:
		case sbjson5_token_string:
        case sbjson5_token_encoded:
			return YES;
		default:
			return NO;
	}
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {
	parser.state = [SBJson5StreamParserStateObjectGotKey sharedInstance];
}

- (BOOL)needKey {
	return YES;
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateObjectGotKey

SINGLETON

- (NSString*)name { return @"after object key"; }

- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
	return token == sbjson5_token_entry_sep;
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {
	parser.state = [SBJson5StreamParserStateObjectSeparator sharedInstance];
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateObjectSeparator

SINGLETON

- (NSString*)name { return @"as object value"; }

- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
	switch (token) {
		case sbjson5_token_object_open:
		case sbjson5_token_array_open:
		case sbjson5_token_bool:
		case sbjson5_token_null:
        case sbjson5_token_integer:
        case sbjson5_token_real:
        case sbjson5_token_string:
        case sbjson5_token_encoded:
			return YES;

		default:
			return NO;
	}
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {
	parser.state = [SBJson5StreamParserStateObjectGotValue sharedInstance];
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateObjectGotValue

SINGLETON

- (NSString*)name { return @"after object value"; }

- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
	switch (token) {
		case sbjson5_token_object_close:
        case sbjson5_token_value_sep:
			return YES;

		default:
			return NO;
	}
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {
	parser.state = [SBJson5StreamParserStateObjectNeedKey sharedInstance];
}


@end

#pragma mark -

@implementation SBJson5StreamParserStateObjectNeedKey

SINGLETON

- (NSString*)name { return @"in place of object key"; }

- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
    return sbjson5_token_string == token || sbjson5_token_encoded == token;
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {
	parser.state = [SBJson5StreamParserStateObjectGotKey sharedInstance];
}

- (BOOL)needKey {
	return YES;
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateArrayStart

SINGLETON

- (NSString*)name { return @"at array start"; }

- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
	switch (token) {
		case sbjson5_token_object_close:
        case sbjson5_token_entry_sep:
        case sbjson5_token_value_sep:
			return NO;

		default:
			return YES;
	}
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {
	parser.state = [SBJson5StreamParserStateArrayGotValue sharedInstance];
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateArrayGotValue

SINGLETON

- (NSString*)name { return @"after array value"; }


- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
	return token == sbjson5_token_array_close || token == sbjson5_token_value_sep;
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {
	if (tok == sbjson5_token_value_sep)
		parser.state = [SBJson5StreamParserStateArrayNeedValue sharedInstance];
}

@end

#pragma mark -

@implementation SBJson5StreamParserStateArrayNeedValue

SINGLETON

- (NSString*)name { return @"as array value"; }


- (BOOL)parser:(SBJson5StreamParser *)parser shouldAcceptToken:(sbjson5_token_t)token {
	switch (token) {
		case sbjson5_token_array_close:
        case sbjson5_token_entry_sep:
		case sbjson5_token_object_close:
		case sbjson5_token_value_sep:
			return NO;

		default:
			return YES;
	}
}

- (void)parser:(SBJson5StreamParser *)parser shouldTransitionTo:(sbjson5_token_t)tok {
	parser.state = [SBJson5StreamParserStateArrayGotValue sharedInstance];
}

@end

