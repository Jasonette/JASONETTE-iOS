/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UARichContentWindow.h"

@protocol UAUIWebViewDelegate <UIWebViewDelegate>

@optional

///---------------------------------------------------------------------------------------
/// @name Core Methods
///---------------------------------------------------------------------------------------

/**
 * Closes the window.
 *
 * @param animated Indicates whether to animate the transition.
 */
- (void)closeWindowAnimated:(BOOL)animated;

@end
