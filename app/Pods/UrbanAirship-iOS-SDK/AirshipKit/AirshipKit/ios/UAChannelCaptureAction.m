/* Copyright 2017 Urban Airship and Contributors */

#import "UAChannelCaptureAction.h"
#import "UAChannelCapture.h"
#import "UAirship.h"


@implementation UAChannelCaptureAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    switch (arguments.situation) {
        case UASituationManualInvocation:
        case UASituationBackgroundPush:
            return [arguments.value isKindOfClass:[NSNumber class]];
        case UASituationAutomation:
        case UASituationWebViewInvocation:
        case UASituationLaunchedFromPush:
        case UASituationBackgroundInteractiveButton:
        case UASituationForegroundInteractiveButton:
        case UASituationForegroundPush:
            return NO;
    }
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {
    NSTimeInterval duration = [arguments.value doubleValue];
    if (duration > 0) {
        [[UAirship shared].channelCapture enable:duration];
    } else {
        [[UAirship shared].channelCapture disable];
    }
    
    completionHandler([UAActionResult emptyResult]);
}

@end
