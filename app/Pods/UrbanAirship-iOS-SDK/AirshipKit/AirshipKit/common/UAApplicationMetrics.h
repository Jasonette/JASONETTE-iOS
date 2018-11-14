/* Copyright 2017 Urban Airship and Contributors */


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class UAPreferenceDataStore;

NS_ASSUME_NONNULL_BEGIN

/**
 * The UAApplicationMetrics class keeps track of application-related metrics.
 */
@interface UAApplicationMetrics : NSObject

///---------------------------------------------------------------------------------------
/// @name Application Metrics Properties
///---------------------------------------------------------------------------------------

/**
 * The date of the last time the application was active.
 */
@property (nonatomic, readonly, strong, nullable) NSDate *lastApplicationOpenDate;

///---------------------------------------------------------------------------------------
/// @name Application Metrics Core Methods
///---------------------------------------------------------------------------------------

/**
 * Triggers an analytics event.
 * @param dataStore The dataStore.
 * @return An application metrics instance.
 */
+ (instancetype)applicationMetricsWithDataStore:(UAPreferenceDataStore *)dataStore;

@end

NS_ASSUME_NONNULL_END
