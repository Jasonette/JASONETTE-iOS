/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A UAProximityRegion defines a proximity region with an identifier, major and minor.
 */
@interface UAProximityRegion : NSObject

///---------------------------------------------------------------------------------------
/// @name Proximity Region Properties
///---------------------------------------------------------------------------------------

/**
 * The proximity region's latitude in degress.
 */
@property (nonatomic, strong, nullable) NSNumber *latitude;

/**
 * The proximity region's longitude in degrees.
 */
@property (nonatomic, strong, nullable) NSNumber *longitude;

/**
 * The proximity region's received signal strength indication in dBm.
 */
@property (nonatomic, strong, nullable) NSNumber *RSSI;

///---------------------------------------------------------------------------------------
/// @name Proximity Region Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method for creating a proximity region.
 *
 * @param proximityID The ID of the proximity region.
 * @param major The major.
 * @param minor The minor.
 *
 * @return Proximity region object or `nil` if error occurs.
 */
+ (nullable instancetype)proximityRegionWithID:(NSString *)proximityID
                                         major:(NSNumber *)major
                                         minor:(NSNumber *)minor;

@end

NS_ASSUME_NONNULL_END
