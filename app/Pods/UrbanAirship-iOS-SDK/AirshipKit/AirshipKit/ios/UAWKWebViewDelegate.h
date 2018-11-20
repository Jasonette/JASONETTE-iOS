/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol UAWKWebViewDelegate <WKNavigationDelegate>

@optional

/**
 * Closes the window.
 *
 * @param animated Indicates whether to animate the transition.
 */
- (void)closeWindowAnimated:(BOOL)animated;

@end
