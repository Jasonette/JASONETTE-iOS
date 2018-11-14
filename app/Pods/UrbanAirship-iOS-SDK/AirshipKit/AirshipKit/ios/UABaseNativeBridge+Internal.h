/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import "UAWebViewCallData.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Base class for UIWebView & WKWebView native bridges that automatically inject the 
 * Urban Airship Javascript interface on whitelisted URLs.
 */
@interface UABaseNativeBridge()

///---------------------------------------------------------------------------------------
/// @name Base Native Bridge Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Populate Javascript environment if the webView is showing a whitelisted URL.
 *
 * @param webView The UIWebView or WKWebView.
 */
- (void)populateJavascriptEnvironmentIfWhitelisted:(UIView *)webView requestURL:(NSURL *)url;

/**
 * Call the appropriate Javascript delegate with the call data and evaluate the returned Javascript.
 *
 * @param data The object holding the data associated with JS delegate calls .
 * @param webView The UIWebView or WKWebView.
 */
- (void)performJSDelegateWithData:(UAWebViewCallData *)data webView:(UIView *)webView;

/**
 * Handles a link click.
 *
 * @param url The link's URL.
 * @returns YES if the link was handled, otherwise NO.
 */
- (BOOL)handleLinkClick:(NSURL *)url;

/**
 * Test if request's URL is an Airship URL and is whitelisted.
 *
 * @param request The request.
 * @returns YES if the request is both an Airship URL and is whitelisted, otherwise NO.
 */
- (BOOL)isWhiteListedAirshipRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
