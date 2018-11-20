/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

#define kUARateAppActionDefaultRegistryName @"rate_app_action"
#define kUARateAppActionDefaultRegistryAlias @"^ra"

/**
 * Links directly to app store review page or opens an app rating prompt.
 *
 * This action is registered under the names rate_app_action and ^ra.
 *
 * The rate app action requires your application's itunes ID to be set directly on the UAConfig
 * instance used for takeoff or in the AirshipConfig.plist under the key ``itunesID``.
 *
 * Expected argument values:
 * ``show_link_prompt``:Required Boolean. If NO action will link directly to the iTunes app
 * review page, if YES action will display a rating prompt. Defaults to NO if nil.
 * ``link_prompt_title``: Optional String. String to override the link prompt's title.
 *   Title over 24 characters will be rejected. Header defaults to "Enjoying <CFBundleDisplayName>?" if nil.
 * ``link_prompt_body``: Optional String. String to override the link prompt's body.
 *  Bodies over 50 characters will be rejected. Body defaults to "Tap Rate App to rate it on the
 *  App Store." if nil.
 *
 * Valid situations: UASituationForegroundPush, UASituationLaunchedFromPush, UASituationWebViewInvocation
 * UASituationManualInvocation, UASituationForegroundInteractiveButton, and UASituationAutomation
 *
 * Result value: nil
 */
@interface UARateAppAction : UAAction

/**
 * The show link prompt key.
 */
extern NSString *const UARateAppShowLinkPromptKey;

/**
 * The link prompt's title key.
 */
extern NSString *const UARateAppLinkPromptTitleKey;

/**
 * The link prompt's body key.
 */
extern NSString *const UARateAppLinkPromptBodyKey;

/**
 * Returns an NSArray of NSNumbers representing the time intervals for each call to display the link prompt since epoch.
 * Timestamps older than 1 year are automatically removed. Timestamps will only be collected for release builds.
 */
-(NSArray *)rateAppLinkPromptTimestamps;

/**
 * Returns an NSArray of NSNumbers representing the time intervals for each call to display the system prompt since epoch.
 * Timestamps older than 1 year are automatically removed. Timestamps for debug and release builds will be collected in separate stores.
 */
-(NSArray *)rateAppPromptTimestamps;

@end
