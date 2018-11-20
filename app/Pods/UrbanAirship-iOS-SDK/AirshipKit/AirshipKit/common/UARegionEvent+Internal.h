/* Copyright 2017 Urban Airship and Contributors */

#import "UARegionEvent.h"

#define kUARegionEventType @"region_event"

#define kUARegionEventMaxLatitude 90
#define kUARegionEventMinLatitude -90
#define kUARegionEventMaxLongitude 180
#define kUARegionEventMinLongitude -180
#define kUARegionEventMaxCharacters 255
#define kUARegionEventMinCharacters 1

#define kUARegionSourceKey @"source"
#define kUARegionIDKey @"region_id"
#define kUARegionBoundaryEventKey @"action"
#define kUARegionBoundaryEventEnterValue @"enter"
#define kUARegionBoundaryEventExitValue @"exit"
#define kUARegionLatitudeKey @"latitude"
#define kUARegionLongitudeKey @"longitude"

#define kUAProximityRegionKey @"proximity"
#define kUAProximityRegionIDKey @"proximity_id"
#define kUAProximityRegionMajorKey @"major"
#define kUAProximityRegionMinorKey @"minor"
#define kUAProximityRegionRSSIKey @"rssi"

#define kUACircularRegionKey @"circular_region"
#define kUACircularRegionRadiusKey @"radius"

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UARegionEvent
 */
@interface UARegionEvent ()

/**
 * The source of the event.
 */
@property (nonatomic, copy) NSString *source;

/**
 * The region's identifier.
 */
@property (nonatomic, copy) NSString *regionID;

/**
 * The type of boundary event - enter, exit or unknown.
 */
@property (nonatomic, assign) UABoundaryEvent boundaryEvent;

/**
 * Validates region event RSSI.
 */
+ (BOOL)regionEventRSSIIsValid:(nullable NSNumber *)RSSI;

/**
 * Validates region event radius.
 */
+ (BOOL)regionEventRadiusIsValid:(nullable NSNumber *)radius;

/**
 * Validates region event latitude.
 */
+ (BOOL)regionEventLatitudeIsValid:(nullable NSNumber *)latitude;

/**
 * Validates region event longitude.
 */
+ (BOOL)regionEventLongitudeIsValid:(nullable NSNumber *)longitude;

/**
 * Validates region event character count.
 */
+ (BOOL)regionEventCharacterCountIsValid:(nullable NSString *)string;

/**
 * The event's JSON payload. Used for automation.
 */
@property (nonatomic, readonly) NSDictionary *payload;

@end

NS_ASSUME_NONNULL_END
