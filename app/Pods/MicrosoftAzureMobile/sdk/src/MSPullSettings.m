// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

//#import "MSPullSettings.h"
#import "MSPullSettingsInternal.h"

#pragma mark * MSPullSettings Implementation

@implementation MSPullSettings

static NSInteger const MSDefaultPageSize = 50;

#pragma mark * Initializer method(s)

- (instancetype)init {
    return [self initWithPageSize:MSDefaultPageSize];
}

- (instancetype)initWithPageSize:(NSInteger)pageSize {

    self = [super init];
    
    if (self) {
        _pageSize = [MSPullSettings validatedPageSizeFromPageSize:pageSize];
    }
    
    return self;
}

#pragma mark * Accessor method(s)

- (void)setPageSize:(NSInteger)pageSize {
    _pageSize = [MSPullSettings validatedPageSizeFromPageSize:pageSize];
}

#pragma mark * Internal method(s)

+ (NSInteger)defaultPageSize {
    return MSDefaultPageSize;
}

#pragma mark * Private methods

+ (NSInteger)validatedPageSizeFromPageSize:(NSInteger)pageSize {
    return pageSize > 0 ? pageSize : MSDefaultPageSize;
}

@end

