/* Copyright 2017 Urban Airship and Contributors */

#import "UAScheduleAction.h"
#import "UAirship.h"
#import "UAAutomation.h"
#import "UAActionScheduleInfo.h"
#import "UAActionSchedule.h"

@implementation UAScheduleAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    switch (arguments.situation) {
        case UASituationManualInvocation:
        case UASituationWebViewInvocation:
        case UASituationBackgroundPush:
        case UASituationForegroundPush:
        case UASituationAutomation:
            return [arguments.value isKindOfClass:[NSDictionary class]];
        case UASituationLaunchedFromPush:
        case UASituationBackgroundInteractiveButton:
        case UASituationForegroundInteractiveButton:
            return NO;
    }
}


- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    NSError *error = nil;

    UAActionScheduleInfo *scheduleInfo = [UAActionScheduleInfo actionScheduleInfoWithJSON:arguments.value error:&error];
    if (!scheduleInfo) {
        UA_LWARN(@"Unable to schedule actions. Invalid schedule payload: %@", scheduleInfo);
        completionHandler([UAActionResult resultWithError:error]);
        return;
    }

    [[UAirship automation] scheduleActions:scheduleInfo completionHandler:^(UAActionSchedule *schedule) {
        completionHandler([UAActionResult resultWithValue:schedule.identifier]);
    }];
}

@end
