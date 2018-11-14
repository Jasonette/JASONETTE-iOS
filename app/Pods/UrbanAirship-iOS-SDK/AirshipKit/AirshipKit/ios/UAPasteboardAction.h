/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

#define kUAPasteboardActionDefaultRegistryName @"clipboard_action"
#define kUAPasteboardActionDefaultRegistryAlias @"^c"

/**
 * Sets the pasteboard's string.
 *
 * This action is registered under the names clipboard_action and ^c.
 *
 * Expected argument values: NSString or an NSDictionary with the pasteboard's string
 * under the 'text' key.
 *
 * Valid situations: UASituationLaunchedFromPush,
 * UASituationWebViewInvocation, UASituationManualInvocation,
 * UASituationForegroundInteractiveButton, UASituationBackgroundInteractiveButton,
 * and UASituationAutomation
 *
 * Result value: The arguments value.
 *
 */
@interface UAPasteboardAction : UAAction

@end
