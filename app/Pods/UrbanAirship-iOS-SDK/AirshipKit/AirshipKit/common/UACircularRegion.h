/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A UACircularRegion defines a circular region with a radius, and latitude and longitude from its center.
 */
@interface UACircularRegion : NSObject

///---------------------------------------------------------------------------------------
/// @name Circular Region Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method for creating a circular region.
 *
 * @param radius The radius of the circular region in meters.
 * @param latitude The latitude of the circular region's center point in degress.
 * @param longitude The longitude of the circular region's center point in degrees.
 *
 * @return Circular region object or `nil` if error occurs
 */
+ (nullable instancetype)circularRegionWithRadius:(NSNumber *)radius latitude:(NSNumber *)latitude longitude:(NSNumber *)longitude;

@end

NS_ASSUME_NONNULL_END
