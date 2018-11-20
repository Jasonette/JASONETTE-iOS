/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

#define kUAChannelCaptureActionDefaultRegistryName @"channel_capture_action"
#define kUAChannelCaptureActionDefaultRegistryAlias @"^cc"

/**
 * Enables channel capture for a set period of time.
 *
 * This action is registered under the names channel_capture_action and ^cc.
 *
 * Expected argument values: NSNumber specifying the number of seconds to enable 
 * channel capture for.
 *
 * Valid situations: UASituationBackgroundPush and UASituationManualInvocation
 *
 * Result value: nil
 */
@interface UAChannelCaptureAction : UAAction

@end
