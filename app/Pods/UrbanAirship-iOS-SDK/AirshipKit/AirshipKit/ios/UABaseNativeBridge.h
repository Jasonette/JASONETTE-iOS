/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import "UAWebViewCallData.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Base class for UIWebView & WKWebView delegates that automatically inject the 
 * Urban Airship Javascript interface on whitelisted URLs.
 */
@interface UABaseNativeBridge : NSObject

@end

NS_ASSUME_NONNULL_END
