/* Copyright 2017 Urban Airship and Contributors */

#import "UACircularRegion.h"

#define kUACircularRegionMaxRadius 100000 // 100 kilometers
#define kUACircularRegionMinRadius .1 // 100 millimeters

NS_ASSUME_NONNULL_BEGIN

@interface UACircularRegion ()

///---------------------------------------------------------------------------------------
/// @name Circular Region Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The latitude of the circular region's center
 */
@property (nonatomic, strong) NSNumber *latitude;
/**
 * The longitude of the circular region's center
 */
@property (nonatomic, strong) NSNumber *longitude;
/**
 * The circular region's radius in meters
 */
@property (nonatomic, strong) NSNumber *radius;

///---------------------------------------------------------------------------------------
/// @name Circular Region Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Validates circular region
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
