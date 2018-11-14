/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An abstraction around a nicer looking
 * loading indicator that embeds a UIActivityIndicatorView
 * in a translucent black beveled rect.
 */
@interface UABeveledLoadingIndicator : UIView

///---------------------------------------------------------------------------------------
/// @name Beveled Loading Indicator Display
///---------------------------------------------------------------------------------------

/**
 * Show and animate the indicator
 */
- (void)show;

/**
 * Hide the indicator.
 */
- (void)hide;

@end

NS_ASSUME_NONNULL_END
