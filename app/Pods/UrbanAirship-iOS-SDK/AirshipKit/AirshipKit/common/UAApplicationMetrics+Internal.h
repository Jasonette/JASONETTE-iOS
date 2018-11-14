/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAApplicationMetrics.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to Application Metrics
 */
@interface UAApplicationMetrics ()

///---------------------------------------------------------------------------------------
/// @name Application Metrics Internal Properties
///---------------------------------------------------------------------------------------

@property (nonatomic, strong, nullable) NSDate *lastApplicationOpenDate;

///---------------------------------------------------------------------------------------
/// @name Application Metrics Internal Methods
///---------------------------------------------------------------------------------------

- (void)didBecomeActive;

@end

NS_ASSUME_NONNULL_END
