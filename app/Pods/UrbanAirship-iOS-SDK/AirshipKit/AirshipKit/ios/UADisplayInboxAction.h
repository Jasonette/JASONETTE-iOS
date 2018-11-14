/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

NS_ASSUME_NONNULL_BEGIN

@class UAInboxMessage;

#define kUADisplayInboxActionDefaultRegistryName @"open_mc_action"
#define kUADisplayInboxActionDefaultRegistryAlias @"^mc"

/**
 * Requests the inbox be displayed.
 *
 * The action will call the UAInboxDelegate showInboxMessage: if the specified message
 * for every accepted situation except UASituationForegroundPush where
 * richPushMessageAvailable: will be called instead.
 *
 * If the message is unavailable because the message is not in the message list or
 * the message ID was not supplied then showInbox will be called for every situation
 * except for UASituationForegroundPush.
 *
 * This action is registered under the names open_mc_action and ^mc.
 *
 * Expected argument value is an inbox message ID as an NSString, nil, or "auto"
 * to look for the message in the argument's metadata.
 *
 * Valid situations: UASituationForegroundPush, UASituationLaunchedFromPush,
 * UASituationWebViewInvocation, UASituationManualInvocation,
 * UASituationForegroundInteractiveButton, and UASituationAutomation
 *
 * Result value: nil
 */
@interface UADisplayInboxAction : UAAction

///---------------------------------------------------------------------------------------
/// @name Display Inbox Action Methods
///---------------------------------------------------------------------------------------

/**
 * Called when the action attempts to display the inbox message.
 * This method should not ordinarily be called directly.
 *
 * @param message The inbox message.
 * @param situation The argument's situation.
 */
- (void)displayInboxMessage:(UAInboxMessage *)message situation:(UASituation)situation;

/**
 * Called when the action attempts to display the inbox.
 * This method should not ordinarily be called directly.
 *
 * @param situation The argument's situation.
 */
- (void)displayInboxWithSituation:(UASituation)situation;

@end

NS_ASSUME_NONNULL_END
