/* Copyright 2017 Urban Airship and Contributors */

NS_ASSUME_NONNULL_BEGIN

@class UADefaultMessageCenterListViewController;
@class UAInboxMessage;

/**
 * Protocol to be implemented by internal message center message view controllers.
 */
@protocol UAMessageCenterMessageViewProtocol

/**
 * The UAInboxMessage being displayed.
 */
@property (nonatomic, strong, readonly) UAInboxMessage *message;

/**
 * Block that will be invoked when this class receives a closeWindow message from the webView.
 */
@property (nonatomic, copy) void (^closeBlock)(BOOL animated);

/**
 * Load a UAInboxMessage.
 * @param message The message to load and display.
 * @param onlyIfChanged Only load the message if it is different from the currently displayed message
 *
 * @deprecated Deprecated - to be removed in SDK version 10.0
 */

- (void)loadMessage:(nullable UAInboxMessage *)message onlyIfChanged:(BOOL)onlyIfChanged  DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 10.0");

/**
 * Load a UAInboxMessage by message ID.
 *
 * @param messageID The message ID of the message.
 * @param onlyIfChanged Only load the message if the message has changed
 * @param errorCompletion Called on loading error
 */
- (void)loadMessageForID:(NSString *)messageID onlyIfChanged:(BOOL)onlyIfChanged onError:(nullable void (^)(void))errorCompletion;

@end

NS_ASSUME_NONNULL_END
