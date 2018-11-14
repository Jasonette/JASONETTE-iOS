/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class UAInboxMessage;

NS_ASSUME_NONNULL_BEGIN

/**
 * This class provides an interface for displaying overlay window over
 * the app's UI without totally obscuring it, which loads a landing
 * page in an embedded UIWebView.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController
 */

DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController")
@interface UALandingPageOverlayController : NSObject

/**
 * Creates and displays a landing page overlay from a URL.
 * @param url The URL of the landing page to display.
 * @param headers The headers to include with the request.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController
 */
+ (void)showURL:(NSURL *)url withHeaders:(nullable NSDictionary *)headers DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController");

/**
 * Creates and displays a landing page overlay from a URL.
 * @param url The URL of the landing page to display.
 * @param headers The headers to include with the request.
 * @param size The size of the landing page in points, full screen by default.
 * @param aspectLock Locks messages to provided size's aspect ratio.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController
 */
+ (void)showURL:(NSURL *)url withHeaders:(nullable NSDictionary *)headers size:(CGSize)size aspectLock:(BOOL)aspectLock DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController");

/**
 * Creates and displays a landing page overlay from a Rich Push message.
 * @param message The Rich Push message to display.
 * @param headers The headers to include with the request.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController
 */
+ (void)showMessage:(UAInboxMessage *)message withHeaders:(nullable NSDictionary *)headers DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController");

/**
 * Creates and displays a landing page overlay from a Rich Push message.
 * @param message The Rich Push message to display.
 * @param headers The headers to include with the request.
 * @param size The size of the message in points, full screen by default.
 * @param aspectLock Locks messages to provided size's aspect ratio.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController
 */
+ (void)showMessage:(UAInboxMessage *)message withHeaders:(nullable NSDictionary *)headers size:(CGSize)size aspectLock:(BOOL)aspectLock DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController");

/**
 * Creates and displays a landing page overlay from a Rich Push message.
 * @param message The Rich Push message to display.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController
 */
+ (void)showMessage:(UAInboxMessage *)message DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController");

/**
 * Closes all currently displayed overlays.
 * @param animated Indicates whether to animate the close transition.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController
 */
+ (void)closeAll:(BOOL)animated DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAOverlayViewController");

@end

NS_ASSUME_NONNULL_END
