/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

#define kUALandingPageActionDefaultRegistryName @"landing_page_action"
#define kUALandingPageActionDefaultRegistryAlias @"^p"

#define kUALandingPageActionLastOpenTimeLimitInSeconds @(7 * 86400) // 1 week

/**
 * Opens a landing page URL in a rich content window.
 *
 * This action is registered under the names landing_page_action and ^p.
 *
 * Expected argument values:
 * ``url``: NSString or NSURL. Short url formats are in the form
 * of "u:<content-id>" and will be used to construct a new URL using the content-id.
 * ``width``: Optional Int or String. Width should be specified in points or
 * as "fill" to fill current screen. Defaults to fill.
 * ``height``: Optional Int or String. Height should be specified in points or
 * ``fill`` to fill current screen. Defaults to fill.
 * ``aspect_lock``: Optional Boolean. Determines if aspect ratio is maintained during resizing
 * to fit screen size. Defaults to false.
 *
 * Valid situations: UASituationForegroundPush, UASituationLaunchedFromPush,
 * UASituationWebViewInvocation, UASituationManualInvocation, UASituationBackgroundPush,
 * UASituationForegroundInteractiveButton, and UASituationAutomation
 *
 * In situation UASituationBackgroundPush, the action will attempt to pre-fetch
 * the data and cache it for later use.
 *
 * Result value: nil
 *
 * Fetch result: UAActionFetchResultNewData, or UAActionFetchResultFailed if the data could not be fetched.
 *
 */
@interface UALandingPageAction : UAAction

/**
 * The URL key.
 */
extern NSString *const UALandingPageURLKey;

/**
 * The height key.
 */
extern NSString *const UALandingPageHeightKey;

/**
 * The width key.
 */
extern NSString *const UALandingPageWidthKey;

/**
 * The aspect lock key.
 */
extern NSString *const UALandingPageAspectLockKey;

/**
 * The fill constant.
 */
extern NSString *const UALandingPageFill;


@end
