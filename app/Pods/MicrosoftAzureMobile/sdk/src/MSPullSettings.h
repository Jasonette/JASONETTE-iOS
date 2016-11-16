// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

/** Settings that control the pull behavior */

@interface MSPullSettings : NSObject

#pragma mark * Initializer method(s)

/** @name Initializing the MSPullSettings object */

/** 
 Initializes the MSPullSettings object with the specified page size 
 
 @param pageSize controls how many records are asked for at a time from the server during a pull
                 operation
 @returns a new MSPullSettings object
 */
- (instancetype)initWithPageSize:(NSInteger)pageSize;

#pragma mark * Properties

/** @name Controlling the pull behavior */

/** Number of records requested from the server at a time (via $top) */
@property (nonatomic) NSInteger pageSize;

@end
