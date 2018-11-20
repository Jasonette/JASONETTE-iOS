/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "UAEvent.h"

@class UAProximityRegion;
@class UACircularRegion;

/**
 * Represents the boundary crossing event type.
 */
typedef NS_ENUM(NSInteger, UABoundaryEvent) {
    /**
     * Enter event
     */
    UABoundaryEventEnter = 1,

    /**
     * Exit event
     */
    UABoundaryEventExit = 2,
};

NS_ASSUME_NONNULL_BEGIN

/**
 * A UARegion event captures information regarding a region event for
 * UAAnalytics.
 */
@interface UARegionEvent : UAEvent

///---------------------------------------------------------------------------------------
/// @name Region Event Properties
///---------------------------------------------------------------------------------------

/**
 * A proximity region with an identifier, major and minor.
 */
@property (nonatomic, strong, nullable) UAProximityRegion *proximityRegion;

/**
 * A circular region with a radius, and latitude/longitude from its center.
 */
@property (nonatomic, strong, nullable) UACircularRegion *circularRegion;

///---------------------------------------------------------------------------------------
/// @name Region Event Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method for creating a region event.
 *
 * @param regionID The ID of the region.
 * @param source The source of the event.
 * @param boundaryEvent The type of boundary crossing event.
 *
 * @return Region event object or `nil` if error occurs.
 */
+ (nullable instancetype)regionEventWithRegionID:(NSString *)regionID
                                          source:(NSString *)source
                                   boundaryEvent:(UABoundaryEvent)boundaryEvent;

@end

NS_ASSUME_NONNULL_END
