/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

#define kUAAddCustomEventActionDefaultRegistryName @"add_custom_event_action"

/**
 * Represents the possible error conditions
 * when running a `UAAddCustomEventAction`.
 */
typedef NS_ENUM(NSInteger, UAAddCustomEventActionErrorCode) {
    /**
     * Indicates that the eventName is invalid.
     */
    UAAddCustomEventActionErrorCodeInvalidEventName
};

NS_ASSUME_NONNULL_BEGIN

/**
 * The domain for errors encountered when running a `UAAddCustomEventAction`.
 */
extern NSString * const UAAddCustomEventActionErrorDomain;

/**
 * An action that adds a custom event.
 *
 * This action is registered under the name "add_custom_event_action".
 *
 * Expected argument values: A dictionary of keys for the custom event. When a
 * custom event action is triggered from a Message Center Rich Push Message,
 * the interaction type and ID will automatically be filled for the message if
 * they are left blank.
 *
 * Valid situations: UASituationForegroundPush, UASituationLaunchedFromPush,
 * UASituationWebViewInvocation, UASituationManualInvocation, UASituationBackgroundPush,
 * UASituationForegroundInteractiveButton, UASituationBackgroundInteractiveButton,
 * and UASituationAutomation
 *
 * 
 * Result value: nil
 *
 * Fetch result: UAActionFetchResultNoData
 *
 * Default predicate: Only accepts UASituationWebViewInvocation and UASituationManualInvocation
 *
 */
@interface UAAddCustomEventAction : UAAction

@end

NS_ASSUME_NONNULL_END
