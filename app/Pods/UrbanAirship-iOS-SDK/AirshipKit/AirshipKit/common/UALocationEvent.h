/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "UAEvent.h"

@protocol UALocationProviderProtocol;

NS_ASSUME_NONNULL_BEGIN

/** Keys and values for location analytics */
typedef NSString UALocationEventAnalyticsKey;
extern UALocationEventAnalyticsKey * const UALocationEventForegroundKey;
extern UALocationEventAnalyticsKey * const UALocationEventLatitudeKey;
extern UALocationEventAnalyticsKey * const UALocationEventLongitudeKey;
extern UALocationEventAnalyticsKey * const UALocationEventDesiredAccuracyKey;
extern UALocationEventAnalyticsKey * const UALocationEventUpdateTypeKey;
extern UALocationEventAnalyticsKey * const UALocationEventProviderKey;
extern UALocationEventAnalyticsKey * const UALocationEventDistanceFilterKey;
extern UALocationEventAnalyticsKey * const UALocationEventHorizontalAccuracyKey;
extern UALocationEventAnalyticsKey * const UALocationEventVerticalAccuracyKey;

typedef NSString UALocationEventUpdateType;
extern UALocationEventUpdateType * const UALocationEventAnalyticsType;
extern UALocationEventUpdateType * const UALocationEventUpdateTypeChange;
extern UALocationEventUpdateType * const UALocationEventUpdateTypeContinuous;
extern UALocationEventUpdateType * const UALocationEventUpdateTypeSingle;
extern UALocationEventUpdateType * const UALocationEventUpdateTypeNone;

typedef NSString UALocationServiceProviderType;
extern UALocationServiceProviderType *const UALocationServiceProviderGps;
extern UALocationServiceProviderType *const UALocationServiceProviderNetwork;
extern UALocationServiceProviderType *const UALocationServiceProviderUnknown;

extern NSString * const UAAnalyticsValueNone;

/** 
 * A UALocationEvent captures all the necessary information for
 * UAAnalytics.
 */
@interface UALocationEvent : UAEvent

///---------------------------------------------------------------------------------------
/// @name Location Event Factories
///---------------------------------------------------------------------------------------

/**
 * Creates a UALocationEvent.
 *
 * @param location Location going to UAAnalytics
 * @param providerType The type of provider that produced the location
 * @param desiredAccuracy The requested accuracy.
 * @param distanceFilter The requested distance filter.
 * @return UALocationEvent populated with the necessary values
 */
+ (UALocationEvent *)locationEventWithLocation:(CLLocation *)location
                                  providerType:(nullable UALocationServiceProviderType *)providerType
                               desiredAccuracy:(nullable NSNumber *)desiredAccuracy
                                distanceFilter:(nullable NSNumber *)distanceFilter;


/**
 * Creates a UALocationEvent for a single location update.
 *
 * @param location Location going to UAAnalytics
 * @param providerType The type of provider that produced the location
 * @param desiredAccuracy The requested accuracy.
 * @param distanceFilter The requested distance filter.
 * @return UALocationEvent populated with the necessary values
 */
+ (UALocationEvent *)singleLocationEventWithLocation:(CLLocation *)location
                                        providerType:(nullable UALocationServiceProviderType *)providerType
                                     desiredAccuracy:(nullable NSNumber *)desiredAccuracy
                                      distanceFilter:(nullable NSNumber *)distanceFilter;


/**
 * Creates a UALocationEvent for a significant location change.
 *
 * @param location Location going to UAAnalytics
 * @param providerType The type of provider that produced the location
 * @return UALocationEvent populated with the necessary values
 */
+ (UALocationEvent *)significantChangeLocationEventWithLocation:(CLLocation *)location
                                                   providerType:(nullable UALocationServiceProviderType *)providerType;

/**
 * Creates a UALocationEvent for a standard location change.
 *
 * @param location Location going to UAAnalytics
 * @param providerType The type of provider that produced the location
 * @param desiredAccuracy The requested accuracy.
 * @param distanceFilter The requested distance filter.
 * @return UALocationEvent populated with the necessary values
 */
+ (UALocationEvent *)standardLocationEventWithLocation:(CLLocation *)location
                                          providerType:(nullable UALocationServiceProviderType *)providerType
                                       desiredAccuracy:(nullable NSNumber *)desiredAccuracy
                                        distanceFilter:(nullable NSNumber *)distanceFilter;


NS_ASSUME_NONNULL_END

@end
