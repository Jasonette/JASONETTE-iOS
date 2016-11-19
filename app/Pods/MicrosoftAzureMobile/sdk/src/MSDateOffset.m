// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSDateOffset.h"

@implementation MSDateOffset

-(id)initWithDate:(NSDate *)date
{
    self = [super init];
    if(self)
    {
        _date = date;
    }
    return self;
}

+(id)offsetFromDate:(NSDate *)date
{
    return [[MSDateOffset alloc] initWithDate:date];;
}

@end
