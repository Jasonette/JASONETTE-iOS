/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "UAUIWebViewDelegate.h"
#import "UARichContentWindow.h"
#import "UABaseNativeBridge.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A UIWebView native bridge that automatically injects the Urban Airship
 * Javascript interface on whitelisted URLs.
 */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
@interface UAWebViewDelegate : UABaseNativeBridge <UAUIWebViewDelegate, UARichContentWindow>
#pragma GCC diagnostic pop

/**
 * Optional delegate to forward any UAUIWebViewDelegate calls.
 */
@property (nonatomic, weak, nullable) id <UAUIWebViewDelegate> forwardDelegate;

/**
 * The rich content window. Optional, needed to support closing the webview from
 * the Urban Airship Javascript interface.
 */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, weak, nullable) id <UARichContentWindow> richContentWindow;
#pragma GCC diagnostic pop

@end

NS_ASSUME_NONNULL_END
