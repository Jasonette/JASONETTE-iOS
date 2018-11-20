/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

NS_ASSUME_NONNULL_BEGIN

#define kUAOverlayInboxMessageActionDefaultRegistryAlias @"open_mc_overlay_action"
#define kUAOverlayInboxMessageActionDefaultRegistryName @"^mco"

/**
 * Requests an inbox message to be displayed in an overlay.
 *
 * This action is registered under the names open_mc_overlay_action and ^mco.
 *
 * Expected argument value is an inbox message ID as an NSString or "MESSAGE_ID"
 * to look for the message in the argument's metadata.
 *
 * Valid situations: UASituationForegroundPush, UASituationLaunchedFromPush, UASituationWebViewInvocation,
 * UASituationManualInvocation, UASituationForegroundInteractiveButton, and
 * UASituationAutomation.
 *
 * Result value: nil
 *
 * Default predicate: Rejects situation UASituationForegroundPush.
 */
@interface UAOverlayInboxMessageAction : UAAction

@end

/**
 * Represents the possible error conditions
 * when running a `UAOverlayInboxMessageAction`.
 */
typedef NS_ENUM(NSInteger, UAOverlayInboxMessageActionErrorCode) {
    /**
     * Indicates that the message was unavailable.
     */
    UAOverlayInboxMessageActionErrorCodeMessageUnavailable
};

/**
 * The domain for errors encountered when running a `UAOverlayInboxMessageAction`.
 */
extern NSString * const UAOverlayInboxMessageActionErrorDomain;

NS_ASSUME_NONNULL_END
