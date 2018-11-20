/* Copyright 2017 Urban Airship and Contributors */

#import "UAAppIntegration.h"
#import "UAirship.h"
#import "UAAnalytics+Internal.h"
#import "UAPush+Internal.h"

#import "UADeviceRegistrationEvent+Internal.h"
#import "UAPushReceivedEvent+Internal.h"
#import "UAInteractiveNotificationEvent+Internal.h"
#import "UANotificationAction.h"
#import "UANotificationCategory.h"
#import "UAActionArguments.h"
#import "UAUtils.h"
#import "UAConfig.h"
#import "UAActionRunner+Internal.h"
#import "UAActionRegistry+Internal.h"

#if !TARGET_OS_TV
#import "UAInboxUtils.h"
#import "UAOverlayInboxMessageAction.h"
#import "UADisplayInboxAction.h"
#import "UAInbox+Internal.h"
#import "UAInboxMessageList+Internal.h"
#import "UAInAppMessaging+Internal.h"
#endif

#define kUANotificationActionKey @"com.urbanairship.interactive_actions"

@implementation UAAppIntegration

#pragma mark -
#pragma mark AppDelegate methods

+ (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    UA_LINFO(@"Application received backgound app refresh");

    [[UAirship push] updateAuthorizedNotificationTypes];
    completionHandler(UIBackgroundFetchResultNoData);
}

+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    UA_LINFO(@"Application registered device token: %@", [UAUtils deviceTokenStringFromDeviceToken:deviceToken]);

    [[UAirship shared].analytics addEvent:[UADeviceRegistrationEvent event]];

    [[UAirship push] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    UA_LERR(@"Application failed to register for remote notifications with error %@", error);
    
    [[UAirship push] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

#if !TARGET_OS_TV   // UIUserNotificationSettings is not available on tvOS
+ (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [[UAirship push] application:application didRegisterUserNotificationSettings:notificationSettings];
}
#endif

+ (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    switch(application.applicationState) {
        case UIApplicationStateActive:
            if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}] && ![UAUtils isSilentPush:userInfo]) {
                // Handled by the new userNotificationCenter:willPresentNotification:withCompletionHandler:
                completionHandler(UIBackgroundFetchResultNoData);
                break;
            }

            // Foreground push
            [self handleIncomingNotification:[UANotificationContent notificationWithNotificationInfo:userInfo]
                      foregroundPresentation:NO
                           completionHandler:completionHandler];

            break;

        case UIApplicationStateBackground:
            // Background push
            [self handleIncomingNotification:[UANotificationContent notificationWithNotificationInfo:userInfo]
                      foregroundPresentation:NO
                           completionHandler:completionHandler];
            break;

        case UIApplicationStateInactive:

            /*
             * iOS 10+ will only ever call application:receivedRemoteNotification:fetchCompletion as a result of content-available push
             */
            if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}] || [UAUtils isSilentPush:userInfo]) {
                [self handleIncomingNotification:[UANotificationContent notificationWithNotificationInfo:userInfo]
                          foregroundPresentation:NO
                               completionHandler:completionHandler];
            } else {
                UANotificationResponse *response = [UANotificationResponse notificationResponseWithNotificationInfo:userInfo
                                                                                                   actionIdentifier:UANotificationDefaultActionIdentifier
                                                                                                       responseText:nil];

                [self handleNotificationResponse:response
                               completionHandler:^() {
                                   completionHandler(UIBackgroundFetchResultNoData);
                               }];
            }
    }

}

#if !TARGET_OS_TV   // Delegate methods unavailable in tvOS
+ (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))handler {
    [self application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:nil completionHandler:handler];
}

+ (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))handler {
    NSString *responseText = responseInfo ? responseInfo[UIUserNotificationActionResponseTypedTextKey] : nil;
    UANotificationResponse *response = [UANotificationResponse notificationResponseWithNotificationInfo:userInfo
                                                                                       actionIdentifier:identifier
                                                                                        responseText:responseText];
   [self handleNotificationResponse:response completionHandler:^(void) {
       handler();
   }];
}
#endif


#pragma mark -
#pragma mark NSNotification methods

+ (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    UA_LDEBUG(@"Notification center will present notification: %@", notification);

    UNNotificationPresentationOptions options = [[UAirship push] presentationOptionsForNotification:notification];
    completionHandler(options);

    if (![UAirship shared].config.automaticSetupEnabled) {
        [self handleForegroundNotification:notification mergedOptions:options withCompletionHandler:^{
            completionHandler(options);
        }];
    } else {
        // UAAutoIntegration will call handleForegroundNotification:mergedOptions:withCompletionHandler:
        completionHandler(options);
    }
}

#if !TARGET_OS_TV   // UNNotificationResponse not available on tvOS
+ (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    UANotificationResponse *airshipResponse = [UANotificationResponse notificationResponseWithUNNotificationResponse:response];

    [self handleNotificationResponse:airshipResponse completionHandler:^(void) {
        completionHandler();
    }];
}
#endif

#pragma mark -
#pragma mark Notification handling

+ (void)handleForegroundNotification:(UNNotification *)notification mergedOptions:(UNNotificationPresentationOptions)options withCompletionHandler:(void(^)(void))completionHandler {
    BOOL foregroundPresentation = (options & UNNotificationPresentationOptionAlert) > 0;

    UANotificationContent *notificationContent = [UANotificationContent notificationWithUNNotification:notification];

    [self handleIncomingNotification:notificationContent
              foregroundPresentation:foregroundPresentation
                   completionHandler:^(UIBackgroundFetchResult result) {
                       completionHandler();
                   }];
}

+ (void)handleNotificationResponse:(UANotificationResponse *)response
                 completionHandler:(void (^)(void))completionHandler {

    UA_LINFO(@"Received notification response: %@", response);

    // Clear any in-app messages (nibs unavailable in tvOS)
#if !TARGET_OS_TV
    [[UAirship inAppMessaging] handleNotificationResponse:response];
#endif
    UASituation situation;
    NSDictionary *actionsPayload = [self actionsPayloadForNotificationContent:response.notificationContent actionIdentifier:response.actionIdentifier];

    if ([response.actionIdentifier isEqualToString:UANotificationDefaultActionIdentifier]) {
        [[UAirship shared].analytics launchedFromNotification:response.notificationContent.notificationInfo];
        situation = UASituationLaunchedFromPush;
    } else {
        UANotificationAction *notificationAction = [self notificationActionForCategory:response.notificationContent.categoryIdentifier
                                                                      actionIdentifier:response.actionIdentifier];


        if (!notificationAction) {
            [[UAirship push] handleNotificationResponse:response completionHandler:completionHandler];
            return;
        }

        if (notificationAction.options & UANotificationActionOptionForeground) {
            [[UAirship shared].analytics launchedFromNotification:response.notificationContent.notificationInfo];
            situation = UASituationForegroundInteractiveButton;
        } else {
            situation = UASituationBackgroundInteractiveButton;
        }

        id event = [UAInteractiveNotificationEvent eventWithNotificationAction:notificationAction
                                                                    categoryID:response.notificationContent.categoryIdentifier
                                                                  notification:response.notificationContent.notificationInfo
                                                                  responseText:response.responseText];

        [[UAirship shared].analytics addEvent:event];
    }

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    [metadata setValue:response.actionIdentifier forKey:UAActionMetadataUserNotificationActionIDKey];
    [metadata setValue:response.notificationContent.notificationInfo forKey:UAActionMetadataPushPayloadKey];
    [metadata setValue:response.responseText forKey:UAActionMetadataResponseInfoKey];

    // Run the actions
    [UAActionRunner runActionsWithActionValues:actionsPayload
                                     situation:situation
                                      metadata:metadata
                             completionHandler:^(UAActionResult *result) {
                                 [[UAirship push] handleNotificationResponse:response completionHandler:completionHandler];
                             }];
}

+ (void)handleIncomingNotification:(UANotificationContent *)notificationContent
            foregroundPresentation:(BOOL)foregroundPresentation
                 completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {

    UA_LINFO(@"Received notification: %@", notificationContent);

    // Process any in-app messages (nibs unavailable in tvOS)
#if !TARGET_OS_TV
    [[UAirship inAppMessaging] handleRemoteNotification:notificationContent];
#endif

    UASituation situation = [UIApplication sharedApplication].applicationState == UIApplicationStateActive ? UASituationForegroundPush : UASituationBackgroundPush;
    NSDictionary *actionsPayload = [self actionsPayloadForNotificationContent:notificationContent actionIdentifier:nil];

    NSDictionary *metadata = @{ UAActionMetadataForegroundPresentationKey: @(foregroundPresentation),
                                UAActionMetadataPushPayloadKey: notificationContent.notificationInfo };

    __block NSUInteger resultCount = 0;
    __block NSUInteger expectedCount = 1;
    __block NSMutableArray *fetchResults = [NSMutableArray array];

#if !TARGET_OS_TV   // Message Center not supported on tvOS
    // Refresh the message center, call completion block when finished
    if ([UAInboxUtils inboxMessageIDFromNotification:notificationContent.notificationInfo]) {
        expectedCount = 2;

        [[UAirship inbox].messageList retrieveMessageListWithSuccessBlock:^{
            [fetchResults addObject:[NSNumber numberWithInt:UIBackgroundFetchResultNewData]];

            dispatch_async(dispatch_get_main_queue(), ^{
                resultCount++;

                if (expectedCount == resultCount) {
                    completionHandler([UAUtils mergeFetchResults:fetchResults]);
                }
            });
        } withFailureBlock:^{
            [fetchResults addObject:[NSNumber numberWithInt:UIBackgroundFetchResultFailed]];

            dispatch_async(dispatch_get_main_queue(), ^{
                resultCount++;

                if (expectedCount == resultCount) {
                    completionHandler([UAUtils mergeFetchResults:fetchResults]);
                }
            });
        }];
    }
#endif

    // Run the actions
    [UAActionRunner runActionsWithActionValues:actionsPayload
                                     situation:situation
                                      metadata:metadata
                             completionHandler:^(UAActionResult *result) {
                                 [fetchResults addObject:[NSNumber numberWithInt:(UIBackgroundFetchResult)[result fetchResult]]];

                                 [[UAirship push] handleRemoteNotification:notificationContent
                                                                foreground:(situation == UASituationForegroundPush)
                                                         completionHandler:^(UIBackgroundFetchResult fetchResult) {
                                                             [fetchResults addObject:[NSNumber numberWithInt:fetchResult]];

                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 resultCount++;

                                                                 if (expectedCount == resultCount) {
                                                                     completionHandler([UAUtils mergeFetchResults:fetchResults]);
                                                                 }
                                                             });
                                                         }];

                             }];
}

#pragma mark -
#pragma mark Helpers

+ (NSDictionary *)actionsPayloadForNotificationContent:(UANotificationContent *)notificationContent actionIdentifier:(NSString *)actionIdentifier {
    if (!actionIdentifier || [actionIdentifier isEqualToString:UANotificationDefaultActionIdentifier]) {
        NSMutableDictionary *mutableActionsPayload = [NSMutableDictionary dictionaryWithDictionary:notificationContent.notificationInfo];

#if !TARGET_OS_TV   // Inbox not supported on tvOS
        NSString *messageID = [UAInboxUtils inboxMessageIDFromNotification:notificationContent.notificationInfo];
        if (messageID) {
            NSSet *inboxActionNames = [NSSet setWithArray:@[kUADisplayInboxActionDefaultRegistryAlias,
                                                            kUADisplayInboxActionDefaultRegistryName,
                                                            kUAOverlayInboxMessageActionDefaultRegistryAlias,
                                                            kUAOverlayInboxMessageActionDefaultRegistryName]];

            NSSet *actionNames = [NSSet setWithArray:[mutableActionsPayload allKeys]];

            if (![actionNames intersectsSet:inboxActionNames]) {
                mutableActionsPayload[kUADisplayInboxActionDefaultRegistryAlias] = messageID;
            }
        }
#endif

        return [mutableActionsPayload copy];
    }

    return notificationContent.notificationInfo[kUANotificationActionKey][actionIdentifier];
}

+ (UANotificationAction *)notificationActionForCategory:(NSString *)category actionIdentifier:(NSString *)identifier {
    NSSet *categories = [UAirship push].combinedCategories;

    UANotificationCategory *notificationCategory;
    UANotificationAction *notificationAction;

    for (UANotificationCategory *possibleCategory in categories) {
        if ([possibleCategory.identifier isEqualToString:category]) {
            notificationCategory = possibleCategory;
            break;
        }
    }

    if (!notificationCategory) {
        UA_LERR(@"Unknown notification category identifier %@", category);
        return nil;
    }

    NSMutableArray *possibleActions = [NSMutableArray arrayWithArray:notificationCategory.actions];

    for (UANotificationAction *possibleAction in possibleActions) {
        if ([possibleAction.identifier isEqualToString:identifier]) {
            notificationAction = possibleAction;
            break;
        }
    }

    if (!notificationAction) {
        UA_LERR(@"Unknown notification action identifier %@", identifier);
        return nil;
    }

    return notificationAction;
}

@end
