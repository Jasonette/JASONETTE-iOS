/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "UAWKWebViewDelegate.h"
#import "UAMessageCenterMessageViewProtocol.h"

/**
 * Default implementation of a view controller for reading Message Center messages.
 */
@interface UAMessageCenterMessageViewController : UIViewController <UAWKWebViewDelegate, UAMessageCenterMessageViewProtocol>

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end
