// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <UIKit/UIKit.h>

@class MSClient;


#pragma mark * MSLoginViewErrorDomain


// The error domain for the MSLoginView errors
extern NSString *const MSLoginViewErrorDomain;


#pragma mark * UserInfo Keys


// The key to use with the |NSError| userInfo dictionary to retrieve the
// data that was returned from a failed attempt to navigate to the end URL.
extern NSString *const MSLoginViewErrorResponseData;


#pragma mark * MSLoginView Error Codes


// Indicates that MSLoginView failed to navigate to the end URL
#define MSLoginViewFailed                   -9001

// Indicates that MSLoginView was canceled
#define MSLoginViewCanceled                 -9002


#pragma mark * Block Type Definitions


// Callback for the |MSLoginView| when it has either navigated to the |endURL|
// or failed to do so because of the given |error|.
typedef void (^MSLoginViewBlock)(NSURL *endURL, NSError *error);


#pragma mark * MSLoginView Public Interface


// The |MSLoginView| class encapsulates all of the UI needed for login
// scenarios. It includes a |WKWebView| and a |UIToolbar| with a cancel button
// and an activity indicator.  The toolbar can be configured.  The |MSLoginView|
// is designed to start a given URL and allow the user to navigate until a
// specific end URL is reached or an error has occurred.
@interface MSLoginView : UIView


#pragma mark * Public Readonly Properties


// The client associated with this |MSLoginView|.
@property (nonatomic, strong, readonly) MSClient* client;

// The URL at which the |MSLoginView| started.
@property (nonatomic, strong, readonly) NSURL* startURL;

// The URL at which the the |MSLoginView| will stop navigating.
@property (nonatomic, strong, readonly) NSURL* endURL;

// The |UIToolbar| associated with the |MSLoginView|.
@property (nonatomic, strong, readonly) UIToolbar *toolbar;

// The |UIActivityIndicatorView| on the |UIToolbar| associated with the
// |MSLoginView|. If the toolbar is visible, the actvivity indicator
// will become active whenever the end user is navigating to a new URL during
// the login flow.
@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicator;


#pragma mark * Public Readwrite Properties


// Indicates if the |toolbar| show be displayed. By default, |showToolbar| is
// YES.
@property (nonatomic, readwrite)        BOOL showToolbar;

// Indicates if the |toolbar| should be positioned at the top or bottom of
// login view.  By default, the |toolbarPosition| is |UIToolbarPositionBottom|.
@property (nonatomic, readwrite)        UIToolbarPosition toolbarPosition;


#pragma  mark * Public Initializer Methods


// Initializes a new instance of the |MSLoginView|
-(id)initWithFrame:(CGRect)frame
            client:(MSClient *)client
          startURL:(NSURL *)startURL
            endURL:(NSURL *)endURL
        completion:(MSLoginViewBlock)completion;

@end
