/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import "UAWKWebViewDelegate.h"
#import "UABaseNativeBridge.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A WKWebView native bridge that automatically injects the Urban Airship
 * Javascript interface on whitelisted URLs.
 */
@interface UAWKWebViewNativeBridge : UABaseNativeBridge <UAWKWebViewDelegate>

///---------------------------------------------------------------------------------------
/// @name UA WKWebView Bridge Properties
///---------------------------------------------------------------------------------------

/**
 * Optional delegate to forward any UAWKWebViewDelegate calls.
 */
@property (nonatomic, weak, nullable) id <UAWKWebViewDelegate> forwardDelegate;

@end

NS_ASSUME_NONNULL_END
