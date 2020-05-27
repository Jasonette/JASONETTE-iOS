/*
 Copyright (C) 2009 Stig Brautaset. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if !__has_feature(objc_arc)
#error "This source file must be compiled with ARC enabled!"
#endif

#import "SBJson5Writer.h"
#import "SBJson5StreamWriter.h"


@interface SBJson5Writer () < SBJson5StreamWriterDelegate >
@property (nonatomic, copy) NSString *error;
@property (nonatomic, strong) NSMutableData *acc;
@end

@implementation SBJson5Writer {
    NSUInteger _maxDepth;
    BOOL _sortKeys;
    NSComparator _sortKeysComparator;
    BOOL _humanReadable;
}

- (id)init {
    return [self initWithMaxDepth:32
                    humanReadable:NO
                         sortKeys:NO
               sortKeysComparator:nil];
}

- (id)initWithMaxDepth:(NSUInteger)maxDepth
         humanReadable:(BOOL)humanReadable
              sortKeys:(BOOL)sortKeys
    sortKeysComparator:(NSComparator)sortKeysComparator {
    self = [super init];
    if (self) {
        _maxDepth = maxDepth;
        _humanReadable = humanReadable;
        _sortKeys = sortKeys;
        _sortKeysComparator = sortKeysComparator;
    }
    return self;
}

+ (id)writerWithMaxDepth:(NSUInteger)maxDepth
           humanReadable:(BOOL)humanReadable
                sortKeys:(BOOL)sortKeys {
    return [[self alloc] initWithMaxDepth:maxDepth
                            humanReadable:humanReadable
                                 sortKeys:sortKeys
                       sortKeysComparator:nil];
}

+ (id)writerWithMaxDepth:(NSUInteger)maxDepth
           humanReadable:(BOOL)humanReadable
      sortKeysComparator:(NSComparator)keyComparator {
    return [[self alloc] initWithMaxDepth:maxDepth
                            humanReadable:humanReadable
                                 sortKeys:YES
                       sortKeysComparator:keyComparator];
}

- (NSString*)stringWithObject:(id)value {
	NSData *data = [self dataWithObject:value];
	if (data)
		return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return nil;
}

- (NSData*)dataWithObject:(id)object {
    self.error = nil;

    self.acc = [[NSMutableData alloc] initWithCapacity:8096u];

    SBJson5StreamWriter *streamWriter = [SBJson5StreamWriter writerWithDelegate:self
                                                                       maxDepth:_maxDepth
                                                                  humanReadable:_humanReadable
                                                                       sortKeys:_sortKeys
                                                             sortKeysComparator:_sortKeysComparator];

	if ([streamWriter writeValue:object])
		return self.acc;

	self.error = streamWriter.error;
	return nil;
}

#pragma mark SBJson5StreamWriterDelegate

- (void)writer:(SBJson5StreamWriter *)writer appendBytes:(const void *)bytes length:(NSUInteger)length {
    [self.acc appendBytes:bytes length:length];
}



@end
