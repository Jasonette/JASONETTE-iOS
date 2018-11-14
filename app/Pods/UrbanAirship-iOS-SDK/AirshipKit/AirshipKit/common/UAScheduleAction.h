/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

#define kUAScheduleActionDefaultRegistryName @"schedule_actions"
#define kUAScheduleActionDefaultRegistryAlias @"^sa"

/**
 * Action to schedule other actions.
 *
 * This action is registered under the names schedule_actions and ^sa.
 *
 * Expected argument values: NSDictionary representing a schedule info JSON.
 *
 * Valid situations: UASituationBackgroundPush, UASituationForegroundPush
 * UASituationWebViewInvocation, UASituationManualInvocation, and UASituationAutomation
 *
 * Result value: Schedule ID or nil if the schedule failed.
 */
@interface UAScheduleAction : UAAction

@end
