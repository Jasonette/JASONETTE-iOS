/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A collection of utilities for converting UIColors to and from various string representations.
 */
@interface UAColorUtils : NSObject

///---------------------------------------------------------------------------------------
/// @name Color Utils Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Converts a hex color string of type #aarrggbb or
 * #rrggbb into a UIColor.
 *
 * @param hexString A hex color string of type #aarrggbb or
 * #rrggbb.
 * @return An instance of UIColor, or `nil` if the color could
 * not be correctly parsed.
 */
+ (nullable UIColor *)colorWithHexString:(NSString *)hexString;

/**
 * Converts a UIColor into a hex color string of type #aarrggbb.
 *
 * @param color An instance of UIColor.
 * @return An NSString of type #aarrggbb representing the passed color, or
 * nil if the UIColor cannot be converted to the RGBA colorspace.
 */
+ (nullable NSString *)hexStringWithColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
