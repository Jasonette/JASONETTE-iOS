/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for mediating the display of rich content pages
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAUIWebViewDelegate
 */
DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAUIWebViewDelegate")
@protocol UARichContentWindow <NSObject>

@optional

/**
 * Closes the webview.
 *
 * @param webView The UIWebView to close.
 * @param animated Indicates whether to animate the transition.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAUIWebViewDelegate's closeWindowAnimated:
 */
- (void)closeWebView:(UIWebView *)webView animated:(BOOL)animated DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAUIWebViewDelegate's closeWindowAnimated:");

@end

NS_ASSUME_NONNULL_END
