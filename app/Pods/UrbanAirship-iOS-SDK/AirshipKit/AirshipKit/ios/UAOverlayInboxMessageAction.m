/* Copyright 2017 Urban Airship and Contributors */

#import "UAOverlayInboxMessageAction.h"
#import "UAActionArguments.h"
#import "UAirship.h"
#import "UAInbox.h"
#import "UAInboxMessage.h"
#import "UAInboxMessageList.h"
#import "UAInboxUtils.h"
#import "UALandingPageOverlayController.h"
#import "UAOverlayViewController.h"
#import "UAConfig.h"

#define kUAOverlayInboxMessageActionMessageIDPlaceHolder @"auto"

NSString * const UAOverlayInboxMessageActionErrorDomain = @"UAOverlayInboxMessageActionError";

@implementation UAOverlayInboxMessageAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {

    switch (arguments.situation) {
        case UASituationManualInvocation:
        case UASituationWebViewInvocation:
        case UASituationLaunchedFromPush:
        case UASituationForegroundInteractiveButton:
        case UASituationForegroundPush:
        case UASituationAutomation:
            if (![arguments.value isKindOfClass:[NSString class]]) {
                return NO;
            }

            if ([[arguments.value lowercaseString] isEqualToString:kUAOverlayInboxMessageActionMessageIDPlaceHolder]) {
                return arguments.metadata[UAActionMetadataPushPayloadKey] ||
                arguments.metadata[UAActionMetadataInboxMessageKey];
            }
            
            return YES;
        case UASituationBackgroundPush:
        case UASituationBackgroundInteractiveButton:
            return NO;
    }
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    [self fetchMessage:arguments.value arguments:arguments completionHandler:^(UAInboxMessage *message, UAActionFetchResult result) {
        if (message) {
            // Fall back to overlay controller
            if (UAirship.shared.config.useWKWebView) {
                [UAOverlayViewController showMessage:message];
            } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                [UALandingPageOverlayController showMessage:message];
#pragma GCC diagnostic pop
            }
            completionHandler([UAActionResult resultWithValue:nil withFetchResult:result]);
        } else {
            NSError *error = [NSError errorWithDomain:UAOverlayInboxMessageActionErrorDomain
                                                 code:UAOverlayInboxMessageActionErrorCodeMessageUnavailable
                                             userInfo:@{NSLocalizedDescriptionKey:@"Message unavailable"}];

            completionHandler([UAActionResult resultWithError:error withFetchResult:result]);
        }

    }];
}

/**
 * Fetches the specified message. If the messageID is "auto", either
 * the UAActionMetadataInboxMessageKey will be returned or the ID of the message
 * will be taken from the UAActionMetadataPushPayloadKey. If the message is not
 * available in the message list, the list will be refreshed.
 * 
 * Note: A copy of this method exists in UADisplayInboxAction
 * 
 * @param messageID The message ID.
 * @param arguments The action arguments.
 * @param completionHandler Completion handler to call when the operation is complete.
 */
- (void)fetchMessage:(NSString *)messageID
           arguments:(UAActionArguments *)arguments
   completionHandler:(void (^)(UAInboxMessage *, UAActionFetchResult))completionHandler {

    if (messageID == nil) {
        completionHandler(nil, UAActionFetchResultNoData);
        return;
    }

    if ([[messageID lowercaseString] isEqualToString:kUAOverlayInboxMessageActionMessageIDPlaceHolder]) {
        // If we have InboxMessage metadata show the message
        if (arguments.metadata[UAActionMetadataInboxMessageKey]) {
            UAInboxMessage *message = arguments.metadata[UAActionMetadataInboxMessageKey];
            completionHandler(message, UAActionFetchResultNoData);
            return;
        }

        // Try getting the message ID from the push notification
        NSDictionary *notification = arguments.metadata[UAActionMetadataPushPayloadKey];
        messageID = [UAInboxUtils inboxMessageIDFromNotification:notification];
    }

    UAInboxMessage *message = [[UAirship inbox].messageList messageForID:messageID];
    if (message) {
        completionHandler(message, UAActionFetchResultNoData);
        return;
    }

    // Refresh the list to see if the message is available
    [[UAirship inbox].messageList retrieveMessageListWithSuccessBlock:^{
        completionHandler([[UAirship inbox].messageList messageForID:messageID], UAActionFetchResultNewData);
    } withFailureBlock:^{
        completionHandler(nil, UAActionFetchResultFailed);
    }];
}

@end
