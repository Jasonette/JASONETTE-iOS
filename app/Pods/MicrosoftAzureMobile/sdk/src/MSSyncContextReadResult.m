// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSSyncContextReadResult.h"

@implementation MSSyncContextReadResult

@synthesize totalCount = totalCount_;
@synthesize items = items_;

- (id)initWithCount:(NSInteger)count items:(NSArray<NSDictionary *> *)items;
{
    self = [super init];
    if (self) {
        totalCount_ = count;
        items_ = items;
    }
    
    return self;
}

@end
