/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

#import "UAWKWebViewDelegate.h"

@class UAInboxMessage;

NS_ASSUME_NONNULL_BEGIN

/**
 * This class provides an interface for displaying overlay window over
 * the app's UI without totally obscuring it, which loads a landing
 * page in an embedded WKWebView.
 */
@interface UAOverlayViewController : NSObject <UAWKWebViewDelegate>

///---------------------------------------------------------------------------------------
/// @name Overlay View Controller Display
///---------------------------------------------------------------------------------------

/**
 * Creates and displays a landing page overlay from a URL.
 * @param url The URL of the landing page to display.
 * @param headers The headers to include with the request.
 */
+ (void)showURL:(NSURL *)url withHeaders:(nullable NSDictionary *)headers;

/**
 * Creates and displays a landing page overlay from a URL.
 * @param url The URL of the landing page to display.
 * @param headers The headers to include with the request.
 * @param size The size of the landing page in points, full screen by default.
 * @param aspectLock Locks messages to provided size's aspect ratio.
 */
+ (void)showURL:(NSURL *)url withHeaders:(nullable NSDictionary *)headers size:(CGSize)size aspectLock:(BOOL)aspectLock;

/**
 * Creates and displays a landing page overlay from a Rich Push message.
 * @param message The Rich Push message to display.
 * @param headers The headers to include with the request.
 */
+ (void)showMessage:(UAInboxMessage *)message withHeaders:(nullable NSDictionary *)headers;

/**
 * Creates and displays a landing page overlay from a Rich Push message.
 * @param message The Rich Push message to display.
 * @param headers The headers to include with the request.
 * @param size The size of the message in points, full screen by default.
 * @param aspectLock Locks messages to provided size's aspect ratio.
 */
+ (void)showMessage:(UAInboxMessage *)message withHeaders:(nullable NSDictionary *)headers size:(CGSize)size aspectLock:(BOOL)aspectLock;

/**
 * Creates and displays a landing page overlay from a Rich Push message.
 * @param message The Rich Push message to display.
 */
+ (void)showMessage:(UAInboxMessage *)message;

///---------------------------------------------------------------------------------------
/// @name Overlay View Controller Management
///---------------------------------------------------------------------------------------

/**
 * Closes all currently displayed overlays.
 * @param animated Indicates whether to animate the close transition.
 */
+ (void)closeAll:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
