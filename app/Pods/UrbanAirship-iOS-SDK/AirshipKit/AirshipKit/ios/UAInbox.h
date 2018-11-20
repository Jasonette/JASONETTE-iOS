/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

#import "UAGlobal.h"

@class UAInboxMessageList;
@class UAInboxAPIClient;
@class UAInboxMessage;

NS_ASSUME_NONNULL_BEGIN

/**
 * Delegate protocol for receiving callbacks related to
 * Rich Push message delivery and display.
 */
@protocol UAInboxDelegate <NSObject>

@optional

///---------------------------------------------------------------------------------------
/// @name Inbox Delegate Optional Methods
///---------------------------------------------------------------------------------------

/**
 * Called when the UADisplayInboxAction was triggered from a foreground notification.
 *
 * @param richPushMessage The Rich Push message
 */
- (void)richPushMessageAvailable:(UAInboxMessage *)richPushMessage;

/**
 * Called when the inbox is requested to be displayed by the UADisplayInboxAction.
 *
 * @param message The Rich Push message
 *
 * @deprecated Deprecated - to be removed in SDK version 10.0
 */
- (void)showInboxMessage:(UAInboxMessage *)message DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 10.0");

/**
 * Called when the inbox is requested to be displayed by the UADisplayInboxAction.
 *
 * @param messageID The message ID of the Rich Push message
 */
- (void)showMessageForID:(NSString *)messageID;

@required

///---------------------------------------------------------------------------------------
/// @name Inbox Delegate Required Methods
///---------------------------------------------------------------------------------------

/**
 * Called when the inbox is requested to be displayed by the UADisplayInboxAction.
 */
- (void)showInbox;

@end

/**
 * The main class for interacting with the Rich Push Inbox.
 *
 * This class bridges library functionality with the UI and is the main point of interaction.
 * Most implementations will only use functionality found in this class.
 */
@interface UAInbox : NSObject

///---------------------------------------------------------------------------------------
/// @name Inbox Properties
///---------------------------------------------------------------------------------------

/**
 * The list of Rich Push Inbox messages.
 */
@property (nonatomic, strong) UAInboxMessageList *messageList;

/**
 * The Inbox API Client
 */
@property (nonatomic, readonly, strong) UAInboxAPIClient *client;

/**
 * The delegate that should be notified when an incoming push is handled,
 * as an object conforming to the UAInboxDelegate protocol.
 * NOTE: The delegate is not retained.
 */
@property (nonatomic, weak, nullable) id <UAInboxDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
