/* Copyright 2017 Urban Airship and Contributors */

#import "UAEvent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Event to track install attributions.
 */
@interface UAInstallAttributionEvent : UAEvent

///---------------------------------------------------------------------------------------
/// @name Install Attribution Event Factories
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAInstallAttributionEvent.
 * @return UAInstallAttributionEvent instance.
 */
+ (instancetype)event;

/**
 * Factory method to create a UAInstallAttributionEvent.
 * @param appPurchaseDate The app purchase date.
 * @param iAdImpressionDate The iAD impression date.
 * @return UAInstallAttributionEvent instance.
 */
+ (instancetype)eventWithAppPurchaseDate:(NSDate *)appPurchaseDate
                       iAdImpressionDate:(NSDate *)iAdImpressionDate;

@end

NS_ASSUME_NONNULL_END
