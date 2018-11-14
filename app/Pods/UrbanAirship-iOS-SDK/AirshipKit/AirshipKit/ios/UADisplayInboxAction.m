/* Copyright 2017 Urban Airship and Contributors */

#import "UADisplayInboxAction.h"
#import "UAActionArguments.h"
#import "UAirship.h"
#import "UAInbox.h"
#import "UAInboxMessage.h"
#import "UAInboxMessageList.h"
#import "UAInboxUtils.h"
#import "UADefaultMessageCenter.h"

#define kUADisplayInboxActionMessageIDPlaceHolder @"auto"

@implementation UADisplayInboxAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {

    switch (arguments.situation) {
        case UASituationManualInvocation:
        case UASituationWebViewInvocation:
        case UASituationForegroundPush:
        case UASituationLaunchedFromPush:
        case UASituationForegroundInteractiveButton:
        case UASituationAutomation:
            return YES;
        case UASituationBackgroundPush:
        case UASituationBackgroundInteractiveButton:
            return NO;
    }
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    // parse the message id (or possibly the entire message) from the arguments
    NSString *messageID = [UAInboxUtils inboxMessageIDFromValue:arguments.value];
    
    // if there is no messageID, or it is an empty string, just show the inbox
    if (!messageID || [messageID lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 0) {
        [self displayInboxWithSituation:arguments.situation];
        completionHandler([UAActionResult resultWithValue:nil withFetchResult:UAActionFetchResultNoData]);
        return;
    }
    
    // look on the device for the message that matches this message ID
    UAInboxMessage *message = nil;
    if ([[messageID lowercaseString] isEqualToString:kUADisplayInboxActionMessageIDPlaceHolder]) {
        // If we have InboxMessage metadata show the message
        if (arguments.metadata[UAActionMetadataInboxMessageKey]) {
            message = arguments.metadata[UAActionMetadataInboxMessageKey];
        } else {
            // Try getting the message ID from the push notification
            NSDictionary *notification = arguments.metadata[UAActionMetadataPushPayloadKey];
            messageID = [UAInboxUtils inboxMessageIDFromNotification:notification];
        }
    }
    if (!message) {
        message = [[UAirship inbox].messageList messageForID:messageID];
    }

    if (message) {
        // message is available on the device
        [self displayInboxMessage:message situation:arguments.situation];
        completionHandler([UAActionResult resultWithValue:nil withFetchResult:UAActionFetchResultNoData]);
    } else {
        // message wasn't available on the device
        if (arguments.situation == UASituationLaunchedFromPush) {
            id<UAInboxDelegate> inboxDelegate = [UAirship inbox].delegate;
            if ([inboxDelegate respondsToSelector:@selector(showMessageForID:)]) {
                [inboxDelegate showMessageForID:messageID];
                completionHandler([UAActionResult resultWithValue:nil withFetchResult:UAActionFetchResultNoData]);
                return;
            }
        }
        
        // Refresh the list to see if the message is available in the cloud
        [[UAirship inbox].messageList retrieveMessageListWithSuccessBlock:^{
            UAInboxMessage *message = [[UAirship inbox].messageList messageForID:messageID];
            if (message) {
                [self displayInboxMessage:message situation:arguments.situation];
                completionHandler([UAActionResult resultWithValue:nil withFetchResult:UAActionFetchResultNewData]);
            } else {
                [self displayInboxWithSituation:arguments.situation];
                completionHandler([UAActionResult resultWithValue:nil withFetchResult:UAActionFetchResultNoData]);
            }
        } withFailureBlock:^{
            [self displayInboxWithSituation:arguments.situation];
            completionHandler([UAActionResult resultWithValue:nil withFetchResult:UAActionFetchResultFailed]);
        }];
    }
}

/**
 * Called when the action attempts to display the inbox message.
 * @param message The inbox message.
 * @param situation The argument's situation.
 */
- (void)displayInboxMessage:(UAInboxMessage *)message situation:(UASituation)situation {
    id<UAInboxDelegate> inboxDelegate = [UAirship inbox].delegate;

    switch (situation) {
        case UASituationForegroundPush:
            if ([inboxDelegate respondsToSelector:@selector(richPushMessageAvailable:)]) {
                [inboxDelegate richPushMessageAvailable:message];
            }
            break;
        case UASituationLaunchedFromPush:
            if ([inboxDelegate respondsToSelector:@selector(showMessageForID:)]) {
                [inboxDelegate showMessageForID:message.messageID];
            } else if ([inboxDelegate respondsToSelector:@selector(showInboxMessage:)]) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                [inboxDelegate showInboxMessage:message];
#pragma GCC diagnostic pop
            } else if ([[UAirship defaultMessageCenter] respondsToSelector:@selector(displayMessageForID:)]) {
                [[UAirship defaultMessageCenter] displayMessageForID:message.messageID];
            } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                [[UAirship defaultMessageCenter] displayMessage:message];
#pragma GCC diagnostic pop
            }
            break;
        case UASituationManualInvocation:
        case UASituationWebViewInvocation:
        case UASituationForegroundInteractiveButton:
            if ([inboxDelegate respondsToSelector:@selector(showMessageForID:)]) {
                [inboxDelegate showMessageForID:message.messageID];
            } else if ([inboxDelegate respondsToSelector:@selector(showInboxMessage:)]) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                [inboxDelegate showInboxMessage:message];
#pragma GCC diagnostic pop
            } else if ([[UAirship defaultMessageCenter] respondsToSelector:@selector(displayMessageForID:)]) {
                [[UAirship defaultMessageCenter] displayMessageForID:message.messageID];
            } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                [[UAirship defaultMessageCenter] displayMessage:message];
#pragma GCC diagnostic pop
            }
            break;
        case UASituationBackgroundPush:
        case UASituationBackgroundInteractiveButton:
        case UASituationAutomation:
            // noop
            return;
    }
}

/**
 * Called when the action attempts to display the inbox.
 * @param situation The argument's situation.
 */
- (void)displayInboxWithSituation:(UASituation)situation {
    if (situation == UASituationForegroundPush) {
        // Avoid interrupting the user to view the inbox
        return;
    }

    id<UAInboxDelegate> inboxDelegate = [UAirship inbox].delegate;
    if ([inboxDelegate respondsToSelector:@selector(showInbox)]) {
        [inboxDelegate showInbox];
    } else {
        [[UAirship defaultMessageCenter] display];
    }
}


@end
