/* Copyright 2017 Urban Airship and Contributors */

#import "UAAutoIntegration+Internal.h"
#import "UAirship+Internal.h"
#import "UAAppIntegration+Internal.h"
#import "UASwizzler+Internal.h"

static UAAutoIntegration *instance_;

@implementation UAAutoIntegrationDummyDelegate
static dispatch_once_t onceToken;
@end

@interface UAAutoIntegration()
@property (nonatomic, strong) UASwizzler *appDelegateSwizzler;
@property (nonatomic, strong) UASwizzler *notificationDelegateSwizzler;
@property (nonatomic, strong) UASwizzler *notificationCenterSwizzler;
@property (nonatomic, strong) UAAutoIntegrationDummyDelegate *dummyNotificationDelegate;
@end

@implementation UAAutoIntegration

+ (void)integrate {
    dispatch_once(&onceToken, ^{
        instance_ = [[UAAutoIntegration alloc] init];

        [instance_ swizzleAppDelegate];

        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}]) {
            [instance_ swizzleNotificationCenter];
        }
    });
}

+ (void)reset {
    if (instance_) {
        onceToken = 0;
        instance_.appDelegateSwizzler = nil;
        instance_.notificationDelegateSwizzler = nil;
        instance_.notificationCenterSwizzler = nil;
        instance_.dummyNotificationDelegate = nil;
        instance_ = nil;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dummyNotificationDelegate = [[UAAutoIntegrationDummyDelegate alloc] init];
    }

    return self;
}

- (void)swizzleAppDelegate {
    id delegate = [UIApplication sharedApplication].delegate;
    if (!delegate) {
        UA_LERR(@"App delegate not set, unable to perform automatic setup.");
        return;
    }

    Class class = [delegate class];

    self.appDelegateSwizzler = [UASwizzler swizzlerForClass:class];

    // Device token
    [self.appDelegateSwizzler swizzle:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)
                             protocol:@protocol(UIApplicationDelegate)
                       implementation:(IMP)ApplicationDidRegisterForRemoteNotificationsWithDeviceToken];

    // Device token errors
    [self.appDelegateSwizzler swizzle:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)
                             protocol:@protocol(UIApplicationDelegate)
                       implementation:(IMP)ApplicationDidFailToRegisterForRemoteNotificationsWithError];

    // Silent notifications
    [self.appDelegateSwizzler swizzle:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)
                             protocol:@protocol(UIApplicationDelegate)
                       implementation:(IMP)ApplicationDidReceiveRemoteNotificationFetchCompletionHandler];

    // Background app refresh
    [self.appDelegateSwizzler swizzle:@selector(application:performFetchWithCompletionHandler:)
                             protocol:@protocol(UIApplicationDelegate)
                       implementation:(IMP)ApplicationPerformFetchWithCompletionHandler];

#if !TARGET_OS_TV  // Delegate methods not supported on tvOS
    // iOS 8 & 9 Only
    if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}]) {

        // Notification action buttons
        [self.appDelegateSwizzler swizzle:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)
                                 protocol:@protocol(UIApplicationDelegate)
                           implementation:(IMP)ApplicationHandleActionWithIdentifierForRemoteNotificationCompletionHandler];

        // Notification action buttons with response info
        [self.appDelegateSwizzler swizzle:@selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)
                                 protocol:@protocol(UIApplicationDelegate)
                           implementation:(IMP)ApplicationHandleActionWithIdentifierForRemoteNotificationWithResponseInfoCompletionHandler];

        // Registered with user notification settings
        [self.appDelegateSwizzler swizzle:@selector(application:didRegisterUserNotificationSettings:)
                                 protocol:@protocol(UIApplicationDelegate)
                           implementation:(IMP)ApplicationDidRegisterUserNotificationSettings];
    }
#endif
}

- (void)swizzleNotificationCenter {
    Class class = [UNUserNotificationCenter class];
    if (!class) {
        UA_LERR(@"UNUserNotificationCenter not available, unable to perform automatic setup.");
        return;
    }

    self.notificationCenterSwizzler = [UASwizzler swizzlerForClass:class];

    // setDelegate:
    [self.notificationCenterSwizzler swizzle:@selector(setDelegate:) implementation:(IMP)UserNotificationCenterSetDelegate];

    id notificationCenterDelegate = [UNUserNotificationCenter currentNotificationCenter].delegate;
    if (notificationCenterDelegate) {
        [self swizzleNotificationCenterDelegate:notificationCenterDelegate];
    } else {
        [UNUserNotificationCenter currentNotificationCenter].delegate = instance_.dummyNotificationDelegate;
    }
}

- (void)swizzleNotificationCenterDelegate:(id<UNUserNotificationCenterDelegate>)delegate {
    Class class = [delegate class];

    self.notificationDelegateSwizzler = [UASwizzler swizzlerForClass:class];
    
    [self.notificationDelegateSwizzler swizzle:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)
                                      protocol:@protocol(UNUserNotificationCenterDelegate)
                                implementation:(IMP)UserNotificationCenterWillPresentNotificationWithCompletionHandler];

#if !TARGET_OS_TV  // Delegate method not supported on tvOS
    [self.notificationDelegateSwizzler swizzle:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
                                      protocol:@protocol(UNUserNotificationCenterDelegate)
                                implementation:(IMP)UserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler];
#endif
}


- (void)setNotificationCenterSwizzler:(UASwizzler *)notificationCenterSwizzler {
    if (_notificationCenterSwizzler) {
        [_notificationCenterSwizzler unswizzle];
    }
    _notificationCenterSwizzler = notificationCenterSwizzler;
}

- (void)setNotificationDelegateSwizzler:(UASwizzler *)notificationDelegateSwizzler {
    if (_notificationDelegateSwizzler) {
        [_notificationDelegateSwizzler unswizzle];
    }
    _notificationDelegateSwizzler = notificationDelegateSwizzler;
}

- (void)setAppDelegateSwizzler:(UASwizzler *)appDelegateSwizzler {
    if (_appDelegateSwizzler) {
        [_appDelegateSwizzler unswizzle];
    }
    _appDelegateSwizzler = appDelegateSwizzler;
}



#pragma mark -
#pragma mark UNUserNotificationCenterDelegate swizzled methods

void UserNotificationCenterWillPresentNotificationWithCompletionHandler(id self, SEL _cmd, UNUserNotificationCenter *notificationCenter, UNNotification *notification, void (^handler)(UNNotificationPresentationOptions)) {

    __block UNNotificationPresentationOptions mergedPresentationOptions = UNNotificationPresentationOptionNone;
    __block NSUInteger resultCount = 0;
    __block NSUInteger expectedCount = 1;


    IMP original = [instance_.notificationDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        expectedCount = 2;

        __block BOOL completionHandlerCalled = NO;
        void (^completionHandler)(UNNotificationPresentationOptions) = ^(UNNotificationPresentationOptions options) {

            // Make sure the app's completion handler is called on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandlerCalled) {
                    UA_LERR(@"Completion handler called multiple times.");
                    return;
                }

                mergedPresentationOptions |= options;

                completionHandlerCalled = YES;
                resultCount++;

                if (expectedCount == resultCount) {
                    [UAAppIntegration handleForegroundNotification:notification mergedOptions:mergedPresentationOptions withCompletionHandler:^{
                        handler(mergedPresentationOptions);
                    }];
                }
            });
        };

        ((void(*)(id, SEL, UNUserNotificationCenter *, UNNotification *, void (^)(UNNotificationPresentationOptions)))original)(self, _cmd, notificationCenter, notification, completionHandler);
    }


    // Call UAPush
    [UAAppIntegration userNotificationCenter:notificationCenter willPresentNotification:notification withCompletionHandler:^(UNNotificationPresentationOptions options) {
        // Make sure the app's completion handler is called on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            mergedPresentationOptions |= options;

            resultCount++;

            if (expectedCount == resultCount) {
                [UAAppIntegration handleForegroundNotification:notification mergedOptions:mergedPresentationOptions withCompletionHandler:^{
                    handler(mergedPresentationOptions);
                }];
            }
        });
    }];
}

#if !TARGET_OS_TV  // Delegate method not supported on tvOS
void UserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler(id self, SEL _cmd, UNUserNotificationCenter *notificationCenter, UNNotificationResponse *response, void (^handler)(void)) {

    __block NSUInteger resultCount = 0;
    __block NSUInteger expectedCount = 1;

    IMP original = [instance_.notificationDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        expectedCount = 2;

        __block BOOL completionHandlerCalled = NO;
        void (^completionHandler)(void) = ^() {

            // Make sure the app's completion handler is called on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandlerCalled) {
                    UA_LERR(@"Completion handler called multiple times.");
                    return;
                }


                completionHandlerCalled = YES;
                resultCount++;

                if (expectedCount == resultCount) {
                    handler();
                }
            });
        };

        ((void(*)(id, SEL, UNUserNotificationCenter *, UNNotificationResponse *, void (^)(void)))original)(self, _cmd, notificationCenter, response, completionHandler);
    }

    // Call UAPush
    [UAAppIntegration userNotificationCenter:notificationCenter
              didReceiveNotificationResponse:response
                       withCompletionHandler:^() {
                           // Make sure we call it on the main queue
                           dispatch_async(dispatch_get_main_queue(), ^{
                               resultCount++;

                               if (expectedCount == resultCount) {
                                   handler();
                               }
                           });
                       }];

}
#endif

#pragma mark -
#pragma mark UNUserNotificationCenter swizzled methods

void UserNotificationCenterSetDelegate(id self, SEL _cmd, id<UNUserNotificationCenterDelegate>delegate) {

    // Call through to original setter
    IMP original = [instance_.notificationCenterSwizzler originalImplementation:_cmd];
    if (original) {
        ((void(*)(id, SEL, id))original)(self, _cmd, delegate);
    }

    if (!delegate) {
        // set our dummy delegate back
        [UNUserNotificationCenter currentNotificationCenter].delegate = instance_.dummyNotificationDelegate;
    } else {
        [instance_ swizzleNotificationCenterDelegate:delegate];
    }
}

#pragma mark -
#pragma mark App delegate (UIApplicationDelegate) swizzled methods

void ApplicationPerformFetchWithCompletionHandler(id self,
                                                  SEL _cmd,
                                                  UIApplication *application,
                                                  void (^handler)(UIBackgroundFetchResult)) {
    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNoData;

    __block NSUInteger resultCount = 0;
    __block NSUInteger expectedCount = 1;

    IMP original = [instance_.appDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        expectedCount = 2;
        __block BOOL completionHandlerCalled = NO;

        void (^completionHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result) {

            // Make sure the app's completion handler is called on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandlerCalled) {
                    UA_LERR(@"Completion handler called multiple times.");
                    return;
                }

                completionHandlerCalled = YES;
                resultCount++;

                // Merge the UIBackgroundFetchResults. If final fetchResult is not already UIBackgroundFetchResultNewData
                // and the current result is not UIBackgroundFetchResultNoData, then set the fetchResult to result
                // (should be either UIBackgroundFetchFailed or UIBackgroundFetchResultNewData)
                if (fetchResult != UIBackgroundFetchResultNewData && result != UIBackgroundFetchResultNoData) {
                    fetchResult = result;
                }

                if (expectedCount == resultCount) {
                    handler(fetchResult);
                }
            });
        };

        // Call the original implementation
        ((void(*)(id, SEL, UIApplication *, void (^)(UIBackgroundFetchResult)))original)(self, _cmd, application, completionHandler);
    }

    [UAAppIntegration application:application performFetchWithCompletionHandler:^(UIBackgroundFetchResult result){
        resultCount++;

        // Merge the UIBackgroundFetchResults. If final fetchResult is not already UIBackgroundFetchResultNewData
        // and the current result is not UIBackgroundFetchResultNoData, then set the fetchResult to result
        // (should be either UIBackgroundFetchFailed or UIBackgroundFetchResultNewData)
        if (fetchResult != UIBackgroundFetchResultNewData && result != UIBackgroundFetchResultNoData) {
            fetchResult = result;
        }

        if (expectedCount == resultCount) {
            handler(result);
        }
    }];
}

void ApplicationDidRegisterForRemoteNotificationsWithDeviceToken(id self, SEL _cmd, UIApplication *application, NSData *deviceToken) {
    [UAAppIntegration application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];

    IMP original = [instance_.appDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        ((void(*)(id, SEL, UIApplication *, NSData*))original)(self, _cmd, application, deviceToken);
    }
}

#if !TARGET_OS_TV  // Delegate method not supported on tvOS
void ApplicationDidRegisterUserNotificationSettings(id self, SEL _cmd, UIApplication *application, UIUserNotificationSettings *settings) {
    [UAAppIntegration application:application didRegisterUserNotificationSettings:settings];

    IMP original = [instance_.appDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        ((void(*)(id, SEL, UIApplication *, UIUserNotificationSettings*))original)(self, _cmd, application, settings);
    }
}
#endif

void ApplicationDidFailToRegisterForRemoteNotificationsWithError(id self, SEL _cmd, UIApplication *application, NSError *error) {
    UA_LERR(@"Application failed to register for remote notifications with error: %@", error);
    [UAAppIntegration application:application didFailToRegisterForRemoteNotificationsWithError:error];

    IMP original = [instance_.appDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        ((void(*)(id, SEL, UIApplication *, NSError*))original)(self, _cmd, application, error);
    }
}

void ApplicationDidReceiveRemoteNotificationFetchCompletionHandler(id self,
                                                                   SEL _cmd,
                                                                   UIApplication *application,
                                                                   NSDictionary *userInfo,
                                                                   void (^handler)(UIBackgroundFetchResult)) {

    __block NSUInteger resultCount = 0;
    __block NSUInteger expectedCount = 1;
    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNoData;

    IMP original = [instance_.appDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        expectedCount = 2;
        __block BOOL completionHandlerCalled = NO;

        void (^completionHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result) {

            // Make sure the app's completion handler is called on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandlerCalled) {
                    UA_LERR(@"Completion handler called multiple times.");
                    return;
                }

                completionHandlerCalled = YES;
                resultCount++;

                // Merge the UIBackgroundFetchResults. If final fetchResult is not already UIBackgroundFetchResultNewData
                // and the current result is not UIBackgroundFetchResultNoData, then set the fetchResult to result
                // (should be either UIBackgroundFetchFailed or UIBackgroundFetchResultNewData)
                if (fetchResult != UIBackgroundFetchResultNewData && result != UIBackgroundFetchResultNoData) {
                    fetchResult = result;
                }

                if (expectedCount == resultCount) {
                    handler(fetchResult);
                }
            });
        };

        // Call the original implementation
        ((void(*)(id, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult)))original)(self, _cmd, application, userInfo, completionHandler);
    }


    // Our completion handler is called by the action framework on the main queue
    [UAAppIntegration application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
        resultCount++;

        // Merge the UIBackgroundFetchResults. If final fetchResult is not already UIBackgroundFetchResultNewData
        // and the current result is not UIBackgroundFetchResultNoData, then set the fetchResult to result
        // (should be either UIBackgroundFetchFailed or UIBackgroundFetchResultNewData)
        if (fetchResult != UIBackgroundFetchResultNewData && result != UIBackgroundFetchResultNoData) {
            fetchResult = result;
        }

        if (expectedCount == resultCount) {
            handler(fetchResult);
        }
    }];

}


#if !TARGET_OS_TV  // Delegate methods not supported on tvOS
void ApplicationHandleActionWithIdentifierForRemoteNotificationCompletionHandler(id self,
                                                                                 SEL _cmd,
                                                                                 UIApplication *application,
                                                                                 NSString *identifier,
                                                                                 NSDictionary *userInfo,
                                                                                 void (^handler)(void)) {
    __block NSUInteger resultCount = 0;
    __block NSUInteger expectedCount = 1;

    IMP original = [instance_.appDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        expectedCount = 2;

        __block BOOL completionHandlerCalled = NO;
        void (^completionHandler)(void) = ^() {

            // Make sure the app's completion handler is called on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandlerCalled) {
                    UA_LERR(@"Completion handler called multiple times.");
                    return;
                }

                completionHandlerCalled = YES;
                resultCount++;

                if (expectedCount == resultCount) {
                    handler();
                }
            });

        };

        // Call the original implementation
        ((void(*)(id, SEL, UIApplication *, NSString *, NSDictionary *, void (^)(void)))original)(self, _cmd, application, identifier, userInfo, completionHandler);
    }

    // Our completion handler is called by the action framework on the main queue
    [UAAppIntegration application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:^{
        resultCount++;

        if (expectedCount == resultCount) {
            handler();
        }
    }];
}

void ApplicationHandleActionWithIdentifierForRemoteNotificationWithResponseInfoCompletionHandler(id self,
                                                                                                 SEL _cmd,
                                                                                                 UIApplication *application,
                                                                                                 NSString *identifier,
                                                                                                 NSDictionary *userInfo,
                                                                                                 NSDictionary *responseInfo,
                                                                                                 void (^handler)(void)) {
    __block NSUInteger resultCount = 0;
    __block NSUInteger expectedCount = 1;

    IMP original = [instance_.appDelegateSwizzler originalImplementation:_cmd];
    if (original) {
        expectedCount = 2;

        __block BOOL completionHandlerCalled = NO;
        void (^completionHandler)(void) = ^() {

            // Make sure the app's completion handler is called on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandlerCalled) {
                    UA_LERR(@"Completion handler called multiple times.");
                    return;
                }

                completionHandlerCalled = YES;
                resultCount++;
                
                if (expectedCount == resultCount) {
                    handler();
                }
            });
            
        };
        
        // Call the original implementation
        ((void(*)(id, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)(void)))original)(self, _cmd, application, identifier, userInfo, responseInfo, completionHandler);
    }
    
    // Our completion handler is called by the action framework on the main queue
    [UAAppIntegration application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:^{
        resultCount++;
        
        if (expectedCount == resultCount) {
            handler();
        }
    }];
}
#endif

@end
