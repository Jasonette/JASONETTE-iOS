/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

@class UAWebViewCallData;

NS_ASSUME_NONNULL_BEGIN

/**
 * A completion handler used to pass the result of a UAJavaScriptDelegate call.
 * The value passed may be nil.
 */
typedef void (^UAJavaScriptDelegateCompletionHandler)(NSString * __nullable script);

/**
 * A standard protocol for accessing native Objective-C functionality from webview
 * content.
 *
 * UADefaultJSDelegate is a reference implementation of this protocol.
 */
@protocol UAJavaScriptDelegate <NSObject>

@required

///---------------------------------------------------------------------------------------
/// @name JavaScript Delegate Required Methods
///---------------------------------------------------------------------------------------

/**
 * Delegates must implement this method. Implementations take a model object representing
 * call data, which includes the command name, an array of string arguments,
 * and a dictionary of key-value pairs (all strings). After processing them, they pass a string
 * containing Javascript that will be evaluated in a message's UIWebView.
 *
 * If the passed command name is not one the delegate responds to, or if no JavaScript side effect
 * is desired, it implementations should pass nil.
 *
 * To pass information to the delegate from a webview, insert links with a "uairship" scheme,
 * args in the path and key-value option pairs in the query string. The host
 * portion of the URL is treated as the command name.
 *
 * The basic URL format:
 * uairship://command-name/<args>?<key/value options>
 *
 * For example, to invoke a command named "foo", and pass in three args (arg1, arg2 and arg3)
 * and three key-value options {option1:one, option2:two, option3:three}:
 *
 * uairship://foo/arg1/arg2/arg3?option1=one&amp;option2=two&amp;option3=three
 *
 * The default, internal implementation of this protocol is UAActionJSDelegate.
 * UAActionJSDelegate reserves command names associated with running Actions, and
 * handles those commands exclusively.
 *
 * @param data An instance of `UAWebViewCallData`
 * @param completionHandler A completion handler to be called with the resulting
 * string to be executed back in the JS environment.
 */
- (void)callWithData:(UAWebViewCallData *)data
   withCompletionHandler:(UAJavaScriptDelegateCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
