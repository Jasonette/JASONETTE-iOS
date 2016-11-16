// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSQueryResult.h"

@implementation MSQueryResult
@synthesize totalCount = totalCount_;
@synthesize items = items_;
@synthesize nextLink = nextLink_;

-(id)initWithItems:(NSArray<NSDictionary *> *)items
        totalCount:(NSInteger) totalCount
          nextLink: (NSString *) nextLink
{
    self = [super init];
    if (self) {
        totalCount_ = totalCount;
        items_ = items;
        nextLink_ = nextLink;
    }
    
    return self;
}

@end
