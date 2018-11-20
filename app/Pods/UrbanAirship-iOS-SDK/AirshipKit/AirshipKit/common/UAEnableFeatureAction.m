/* Copyright 2017 Urban Airship and Contributors */

#import "UAEnableFeatureAction.h"
#import "UAirship.h"
#import "UALocation.h"
#import "UAPush.h"


NSString *const UAEnableUserNotificationsActionValue = @"user_notifications";
NSString *const UAEnableLocationActionValue = @"location";
NSString *const UAEnableBackgroundLocationActionValue = @"background_location";

@implementation UAEnableFeatureAction


- (BOOL)acceptsArguments:(UAActionArguments *)arguments {

    if (arguments.situation == UASituationBackgroundPush || arguments.situation == UASituationBackgroundInteractiveButton) {
        return NO;
    }

    if (![arguments.value isKindOfClass:[NSString class]]) {
        return NO;
    }

    NSString *value = arguments.value;
    if ([value isEqualToString:UAEnableUserNotificationsActionValue] || [value isEqualToString:UAEnableLocationActionValue] || [value isEqualToString:UAEnableBackgroundLocationActionValue]) {
        return YES;
    }

    return NO;
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {
    if ([arguments.value isEqualToString:UAEnableUserNotificationsActionValue]) {
        [UAirship push].userPushNotificationsEnabled = YES;
    } else if ([arguments.value isEqualToString:UAEnableBackgroundLocationActionValue]) {
        [UAirship location].locationUpdatesEnabled = YES;
        [UAirship location].backgroundLocationUpdatesAllowed = YES;
    } else if ([arguments.value isEqualToString:UAEnableLocationActionValue]) {
        [UAirship location].locationUpdatesEnabled = YES;
    }

    completionHandler([UAActionResult emptyResult]);
}

@end
