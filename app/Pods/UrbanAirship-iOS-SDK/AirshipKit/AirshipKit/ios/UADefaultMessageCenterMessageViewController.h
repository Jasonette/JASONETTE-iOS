/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UARichContentWindow.h"
#import "UAUIWebViewDelegate.h"
#import "UAMessageCenterMessageViewProtocol.h"

@class UAInboxMessage;
@class UADefaultMessageCenterStyle;

/**
 * Default implementation of a view controller for reading Message Center messages.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0 - please use UAMessageCenterMessageViewController
 */

DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0 - please use UAMessageCenterMessageViewController")
@interface UADefaultMessageCenterMessageViewController : UIViewController <UAUIWebViewDelegate, UARichContentWindow, UAMessageCenterMessageViewProtocol>

/**
 * The UAInboxMessage being displayed.
 */
@property (nonatomic, strong) UAInboxMessage *message;

/**
 * An optional predicate for filtering messages.
 */
@property (nonatomic, strong) NSPredicate *filter;

/**
 * Block that will be invoked when this class receives a closeWindow message from the webView.
 */
@property (nonatomic, copy) void (^closeBlock)(BOOL animated);

/**
 * Load a UAInboxMessage at a particular index in the message list.
 *
 * @param index The corresponding index in the message list as an integer.
 */
- (void)loadMessageAtIndex:(NSUInteger)index;

/**
 * Load a UAInboxMessage by message ID.
 *
 * @param messageID The message ID of the message.
 */
- (void)loadMessageForID:(NSString *)messageID;

@end
