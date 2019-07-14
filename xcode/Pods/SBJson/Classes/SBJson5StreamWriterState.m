/*
 Copyright (c) 2010, Stig Brautaset.
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

#import "SBJson5StreamWriterState.h"
#import "SBJson5StreamWriter.h"

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


@implementation SBJson5StreamWriterState
+ (id)sharedInstance { return nil; }
- (BOOL)isInvalidState:(SBJson5StreamWriter *)writer { return NO; }
- (void)appendSeparator:(SBJson5StreamWriter *)writer {}
- (BOOL)expectingKey:(SBJson5StreamWriter *)writer { return NO; }
- (void)transitionState:(SBJson5StreamWriter *)writer {}
- (void)appendWhitespace:(SBJson5StreamWriter *)writer {
    [writer appendBytes:"\n" length:1];
    for (NSUInteger i = 0; i < writer.stateStack.count; i++)
        [writer appendBytes:"  " length:2];
}
@end

@implementation SBJson5StreamWriterStateObjectStart

SINGLETON

- (void)transitionState:(SBJson5StreamWriter *)writer {
    writer.state = [SBJson5StreamWriterStateObjectValue sharedInstance];
}
- (BOOL)expectingKey:(SBJson5StreamWriter *)writer {
    writer.error = @"JSON object key must be string";
    return YES;
}
@end

@implementation SBJson5StreamWriterStateObjectKey

SINGLETON

- (void)appendSeparator:(SBJson5StreamWriter *)writer {
    [writer appendBytes:"," length:1];
}
@end

@implementation SBJson5StreamWriterStateObjectValue

SINGLETON

- (void)appendSeparator:(SBJson5StreamWriter *)writer {
    [writer appendBytes:":" length:1];
}
- (void)transitionState:(SBJson5StreamWriter *)writer {
    writer.state = [SBJson5StreamWriterStateObjectKey sharedInstance];
}
- (void)appendWhitespace:(SBJson5StreamWriter *)writer {
    [writer appendBytes:" " length:1];
}
@end

@implementation SBJson5StreamWriterStateArrayStart

SINGLETON

- (void)transitionState:(SBJson5StreamWriter *)writer {
    writer.state = [SBJson5StreamWriterStateArrayValue sharedInstance];
}
@end

@implementation SBJson5StreamWriterStateArrayValue

SINGLETON

- (void)appendSeparator:(SBJson5StreamWriter *)writer {
    [writer appendBytes:"," length:1];
}
@end

@implementation SBJson5StreamWriterStateStart

SINGLETON


- (void)transitionState:(SBJson5StreamWriter *)writer {
    writer.state = [SBJson5StreamWriterStateComplete sharedInstance];
}
- (void)appendSeparator:(SBJson5StreamWriter *)writer {
}
@end

@implementation SBJson5StreamWriterStateComplete

SINGLETON

- (BOOL)isInvalidState:(SBJson5StreamWriter *)writer {
	writer.error = @"Stream is closed";
	return YES;
}
@end

@implementation SBJson5StreamWriterStateError

SINGLETON

@end

