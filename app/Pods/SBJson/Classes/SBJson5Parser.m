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

#import "SBJson5Parser.h"

@interface SBJson5Parser () <SBJson5StreamParserDelegate>

- (void)pop;

@end

typedef enum {
    SBJson5ChunkNone,
    SBJson5ChunkArray,
    SBJson5ChunkObject,
} SBJson5ChunkType;

@implementation SBJson5Parser {
    SBJson5StreamParser *_parser;
    NSUInteger depth;
    NSMutableArray *array;
    NSMutableDictionary *dict;
    NSMutableArray *keyStack;
    NSMutableArray *stack;
    SBJson5ErrorBlock errorHandler;
    SBJson5ValueBlock valueBlock;
    SBJson5ChunkType currentType;
    BOOL supportManyDocuments;
    BOOL supportPartialDocuments;
    NSUInteger _maxDepth;
}

#pragma mark Housekeeping

- (id)init {
    @throw @"Not Implemented";
}

+ (id)parserWithBlock:(SBJson5ValueBlock)block
         errorHandler:(SBJson5ErrorBlock)eh {
    return [self parserWithBlock:block
                  allowMultiRoot:NO
                 unwrapRootArray:NO
                        maxDepth:32
                    errorHandler:eh];
}

+ (id)multiRootParserWithBlock:(SBJson5ValueBlock)block
                  errorHandler:(SBJson5ErrorBlock)eh {
    return [self parserWithBlock:block
                  allowMultiRoot:YES
                 unwrapRootArray:NO
                        maxDepth:32
                    errorHandler:eh];
}

+ (id)unwrapRootArrayParserWithBlock:(SBJson5ValueBlock)block
                        errorHandler:(SBJson5ErrorBlock)eh {
    return [self parserWithBlock:block
                  allowMultiRoot:NO
                 unwrapRootArray:YES
                        maxDepth:32
                    errorHandler:eh];
}

+ (id)parserWithBlock:(SBJson5ValueBlock)block
       allowMultiRoot:(BOOL)allowMultiRoot
      unwrapRootArray:(BOOL)unwrapRootArray
             maxDepth:(NSUInteger)maxDepth
         errorHandler:(SBJson5ErrorBlock)eh {
    return [[self alloc] initWithBlock:block
                        allowMultiRoot:allowMultiRoot
                       unwrapRootArray:unwrapRootArray
                              maxDepth:maxDepth
                          errorHandler:eh];
}

- (id)initWithBlock:(SBJson5ValueBlock)block
     allowMultiRoot:(BOOL)multiRoot
    unwrapRootArray:(BOOL)unwrapRootArray
           maxDepth:(NSUInteger)maxDepth
       errorHandler:(SBJson5ErrorBlock)eh {

	self = [super init];
	if (self) {
        _parser = [SBJson5StreamParser parserWithDelegate:self];

        supportManyDocuments = multiRoot;
        supportPartialDocuments = unwrapRootArray;

        valueBlock = block;
		keyStack = [[NSMutableArray alloc] initWithCapacity:32];
		stack = [[NSMutableArray alloc] initWithCapacity:32];
        errorHandler = eh ? eh : ^(NSError*err) { NSLog(@"%@", err); };
		currentType = SBJson5ChunkNone;
        _maxDepth = maxDepth;
	}
	return self;
}


#pragma mark Private methods

- (void)pop {
	[stack removeLastObject];
	array = nil;
	dict = nil;
	currentType = SBJson5ChunkNone;

	id value = [stack lastObject];

	if ([value isKindOfClass:[NSArray class]]) {
		array = value;
		currentType = SBJson5ChunkArray;
	} else if ([value isKindOfClass:[NSDictionary class]]) {
		dict = value;
		currentType = SBJson5ChunkObject;
	}
}

- (void)parserFound:(id)obj isValue:(BOOL)isValue {
    NSParameterAssert(obj);

    switch (currentType) {
    case SBJson5ChunkArray:
        [array addObject:obj];
        break;

    case SBJson5ChunkObject:
        NSParameterAssert(keyStack.count);
        [dict setObject:obj forKey:[keyStack lastObject]];
        [keyStack removeLastObject];
        break;

    case SBJson5ChunkNone: {
        __block BOOL stop = NO;
        valueBlock(obj, &stop);
        if (stop) [_parser stop];
    }
        break;

    default:
        break;
    }
}


#pragma mark Delegate methods

- (void)parserFoundObjectStart {
    ++depth;
    if (depth > _maxDepth)
        [self maxDepthError];

    dict = [NSMutableDictionary new];
	[stack addObject:dict];
    currentType = SBJson5ChunkObject;
}

- (void)parserFoundObjectKey:(NSString *)key_ {
    [keyStack addObject:key_];
}

- (void)parserFoundObjectEnd {
    depth--;
	id value = dict;
	[self pop];
    [self parserFound:value isValue:NO ];
}

- (void)parserFoundArrayStart {
    depth++;
    if (depth > _maxDepth)
        [self maxDepthError];

    if (depth > 1 || !supportPartialDocuments) {
		array = [NSMutableArray new];
		[stack addObject:array];
		currentType = SBJson5ChunkArray;
    }
}

- (void)parserFoundArrayEnd {
    depth--;
    if (depth > 0 || !supportPartialDocuments) {
		id value = array;
		[self pop];
        [self parserFound:value isValue:NO ];
    }
}

- (void)maxDepthError {
    id ui = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Input depth exceeds max depth of %lu", (unsigned long)_maxDepth]};
    errorHandler([NSError errorWithDomain:@"org.sbjson.parser" code:3 userInfo:ui]);
    [_parser stop];
}

- (void)parserFoundBoolean:(BOOL)x {
	[self parserFound:[NSNumber numberWithBool:x] isValue:YES ];
}

- (void)parserFoundNull {
    [self parserFound:[NSNull null] isValue:YES ];
}

- (void)parserFoundNumber:(NSNumber *)num {
    [self parserFound:num isValue:YES ];
}

- (void)parserFoundString:(NSString *)string {
    [self parserFound:string isValue:YES ];
}

- (void)parserFoundError:(NSError *)err {
    errorHandler(err);
}

- (BOOL)parserShouldSupportManyDocuments {
    return supportManyDocuments;
}

- (SBJson5ParserStatus)parse:(NSData *)data {
    return [_parser parse:data];
}

@end
