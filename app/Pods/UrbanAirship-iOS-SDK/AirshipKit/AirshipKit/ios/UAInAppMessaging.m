/* Copyright 2017 Urban Airship and Contributors */

#import "UAInAppMessaging+Internal.h"
#import "UAInAppMessage.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAActionRunner.h"
#import "UAInAppMessageController+Internal.h"
#import "UAInAppDisplayEvent+Internal.h"
#import "UAAnalytics.h"
#import "UAInAppResolutionEvent+Internal.h"
#import "UANotificationContent.h"
#import "UANotificationResponse.h"

#if !TARGET_OS_TV
#import "UAInboxUtils.h"
#import "UADisplayInboxAction.h"
#import "UAOverlayInboxMessageAction.h"
#endif

NSString *const UALastDisplayedInAppMessageID = @"UALastDisplayedInAppMessageID";

// Number of seconds to delay before displaying an in-app message
#define kUAInAppMessagingDefaultDelayBeforeInAppMessageDisplay 3.0

// The default display font
#define kUAInAppMessageDefaultFont [UIFont boldSystemFontOfSize:12];

// The default primary color for IAMs: white
#define kUAInAppMessageDefaultPrimaryColor [UIColor whiteColor]

// The default secondary color for IAMs: gray-ish
#define kUAInAppMessageDefaultSecondaryColor [UIColor colorWithRed:40.0/255 green:40.0/255 blue:40.0/255 alpha:1]

// APNS payload key
#define kUAIncomingInAppMessageKey @"com.urbanairship.in_app"


@interface UAInAppMessaging ()
@property(nonatomic, strong) UAInAppMessageController *messageController;
@property(nonatomic, strong) UAPreferenceDataStore *dataStore;
@property(nonatomic, strong) UAAnalytics *analytics;
@property(nonatomic, strong) NSTimer *autoDisplayTimer;
@end

@implementation UAInAppMessaging

- (instancetype)initWithAnalytics:(UAAnalytics *)analytics
                        dataStore:(UAPreferenceDataStore *)dataStore {

    self = [super init];
    if (self) {

        // Set up the most basic customization
        self.font = kUAInAppMessageDefaultFont;
        self.displayDelay = kUAInAppMessagingDefaultDelayBeforeInAppMessageDisplay;
        self.defaultPrimaryColor = kUAInAppMessageDefaultPrimaryColor;
        self.defaultSecondaryColor = kUAInAppMessageDefaultSecondaryColor;

        self.displayASAPEnabled = NO;

        self.dataStore = dataStore;
        self.analytics = analytics;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:[UIApplication sharedApplication]];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:[UIApplication sharedApplication]];

#if !TARGET_OS_TV // Keyboard notifications not available on tvOS
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
#endif
    }

    return self;
}

+ (instancetype)inAppMessagingWithAnalytics:(UAAnalytics *)analytics
                                  dataStore:(UAPreferenceDataStore *)dataStore {

    return [[UAInAppMessaging alloc] initWithAnalytics:analytics
                                             dataStore:dataStore];
}

- (void)invalidateAutoDisplayTimer {
    // if we've already got a valid timer, invalidate it first
    if (self.autoDisplayTimer.isValid) {
        [self.autoDisplayTimer invalidate];
    }
    self.autoDisplayTimer = nil;
}

- (void)scheduleAutoDisplayTimer:(BOOL)displayForcefully {
    [self invalidateAutoDisplayTimer];

    self.autoDisplayTimer = [NSTimer timerWithTimeInterval:self.displayDelay
                                                    target:self
                                                  selector:@selector(autoDisplayTimerFired:)
                                                  userInfo:@(displayForcefully)
                                                   repeats:NO];

    [[NSRunLoop currentRunLoop] addTimer:self.autoDisplayTimer forMode:NSDefaultRunLoopMode];
}

- (void)autoDisplayTimerFired:(NSTimer *)timer {
    NSNumber *userInfo = timer.userInfo;
    BOOL forcefully = userInfo.boolValue;
    [self displayPendingMessage:forcefully];
}

// UIKeyboardDidShowNotification event callback
- (void)keyboardDidShow {
    self.keyboardDisplayed = YES;
}

// UIKeyboardDidHideNotification event callback
- (void)keyboardDidHide {
    self.keyboardDisplayed = NO;
}

// UIApplicationDidBecomeActiveNotification event callback
- (void)applicationDidBecomeActive {
    if (self.isAutoDisplayEnabled) {
        [self scheduleAutoDisplayTimer:YES];
    }
}

// UIApplicationDidEnterBackgroundNotification event callback
- (void)applicationDidEnterBackground {
    [self invalidateAutoDisplayTimer];
}

- (UAInAppMessage *)pendingMessage {
    NSDictionary *pendingMessagePayload = [self.dataStore objectForKey:kUAPendingInAppMessageDataStoreKey];
    if (pendingMessagePayload) {
        return [UAInAppMessage messageWithPayload:pendingMessagePayload];;
    }
    return nil;
}

- (void)setPendingMessage:(UAInAppMessage *)message {
    if (!message) {
        [self.dataStore setObject:message.payload forKey:kUAPendingInAppMessageDataStoreKey];
        return;
    }

    // Discard if it's not a banner
    if (message.displayType != UAInAppMessageDisplayTypeBanner) {
        UA_LDEBUG(@"In-app message is not a banner, discarding: %@", message);
        return;
    }

    UAInAppMessage *previousMessage = self.pendingMessage;

    if (previousMessage) {
        UAInAppResolutionEvent *event = [UAInAppResolutionEvent replacedResolutionWithMessage:previousMessage
                                                                                  replacement:message];
        [self.analytics addEvent:event];
    }

    UA_LINFO(@"Storing pending in-app message: %@.", message);
    [self.dataStore setObject:message.payload forKey:kUAPendingInAppMessageDataStoreKey];

    // Call the delegate, if needed
    id<UAInAppMessagingDelegate> strongDelegate = self.messagingDelegate;
    if ([strongDelegate respondsToSelector:@selector(pendingMessageAvailable:)]) {
        [strongDelegate pendingMessageAvailable:message];
    };

    // If auto display and displayASAP are enabled, display the message as soon as possible
    bool isActive = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
    if (isActive && self.isAutoDisplayEnabled && self.isDisplayASAPEnabled) {
        [self displayMessage:message forcefully:NO];
    }
}

- (BOOL)isAutoDisplayEnabled {
    if (![self.dataStore objectForKey:kUAAutoDisplayInAppMessageDataStoreKey]) {
        return YES;
    }

    return [self.dataStore boolForKey:kUAAutoDisplayInAppMessageDataStoreKey];
}

- (void)setAutoDisplayEnabled:(BOOL)autoDisplayEnabled {
    [self.dataStore setBool:autoDisplayEnabled forKey:kUAAutoDisplayInAppMessageDataStoreKey];
}

- (void)deletePendingMessage:(UAInAppMessage *)message {
    if ([self.pendingMessage isEqualToMessage:message]) {
        self.pendingMessage = nil;
    }
}

- (void)displayPendingMessage:(BOOL)forcefully {
    [self displayMessage:self.pendingMessage forcefully:forcefully];
}

- (void)displayPendingMessage {
    [self displayPendingMessage:YES];
}

- (void)displayMessage:(UAInAppMessage * __nonnull)message forcefully:(BOOL)forcefully {
    if (!message) {
        return;
    }

    // Discard if it's not a banner
    if (message.displayType != UAInAppMessageDisplayTypeBanner) {
        UA_LDEBUG(@"In-app message is not a banner, discarding: %@", message);
        return;
    }

    // Check if the message is expired
    if (message.expiry && [[NSDate date] compare:message.expiry] == NSOrderedDescending) {
        UA_LINFO(@"In-app message is expired: %@", message);
        [self deletePendingMessage:message];

        UAInAppResolutionEvent *event = [UAInAppResolutionEvent expiredMessageResolutionWithMessage:message];
        [self.analytics addEvent:event];

        return;
    }

    // If it's not currently displayed
    if ([message isEqualToMessage:self.messageController.message]) {
        UA_LDEBUG(@"In-app message already displayed: %@", message);
        return;
    }

    UA_LINFO(@"Displaying in-app message: %@", message);

    __block UAInAppMessageController *controller;

    if  (self.isKeyboardDisplayed) {
        UA_LDEBUG(@"Keyboard is currently displayed cancelling in-app message: %@", message);
        return;
    }

    controller = [UAInAppMessageController controllerWithMessage:message
                                                        delegate:self.messageControllerDelegate
                                                  dismissalBlock:^(UAInAppMessageController *dismissedController) {
                                                      // Delete the pending payload once it's dismissed
                                                      [self deletePendingMessage:message];
                                                      // Release the message controller if it hasn't been replaced
                                                      if ([self.messageController isEqual:dismissedController]) {
                                                          self.messageController = nil;
                                                      }
                                                      // If necessary, schedule automatic display of the next pending message
                                                      if (self.pendingMessage && self.autoDisplayEnabled && self.isDisplayASAPEnabled) {
                                                          [self scheduleAutoDisplayTimer:NO];
                                                      }
                                                  }];

    // Call the delegate, if needed
    id<UAInAppMessagingDelegate> strongDelegate = self.messagingDelegate;
    if ([strongDelegate respondsToSelector:@selector(messageWillBeDisplayed:)]) {
        [strongDelegate messageWillBeDisplayed:message];
    };

    // There's not a message already showing, or if we're displaying forcefully
    if (!self.messageController.isShowing || forcefully) {

        // Dismiss any existing message and attempt to show the new one
        [self.messageController dismiss];

        UAInAppMessageController *strongController = controller;
        self.messageController = strongController;
        BOOL displayed = [strongController show];

        // If the display was successful
        if (displayed) {
            // Send a display event if it's the first time we are displaying this IAM
            NSString *lastDisplayedIAM = [self.dataStore valueForKey:UALastDisplayedInAppMessageID];
            if (message.identifier && ![message.identifier isEqualToString:lastDisplayedIAM]) {
                UAInAppDisplayEvent *event = [UAInAppDisplayEvent eventWithMessage:message];
                [self.analytics addEvent:event];

                // Set the ID as the last displayed so we dont send duplicate display events
                [self.dataStore setValue:message.identifier forKey:UALastDisplayedInAppMessageID];
            }
        } else {
            UA_LDEBUG(@"Unable to display in-app message: %@", message);
            if (!self.messageController) {
                UA_LTRACE(@"In-app message controller is nil");
            }
            self.messageController = nil;
        }
    }
}

- (void)displayMessage:(UAInAppMessage *)message {
    [self displayMessage:message forcefully:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)handleNotificationResponse:(UANotificationResponse *)response {
    NSDictionary *apnsPayload = response.notificationContent.notificationInfo;
    if (!apnsPayload[kUAIncomingInAppMessageKey]) {
        return;
    }

    NSString *sendId = apnsPayload[@"_"];

    UAInAppMessage *pending = self.pendingMessage;

    // Compare only the ID in case we amended the in-app message payload
    if (sendId.length && [sendId isEqualToString:pending.identifier]) {
        UA_LINFO(@"The in-app message delivery push was directly launched for message: %@", pending);
        [self deletePendingMessage:pending];

        UAInAppResolutionEvent *event = [UAInAppResolutionEvent directOpenResolutionWithMessage:pending];
        [self.analytics addEvent:event];
    }
}

- (void)handleRemoteNotification:(UANotificationContent *)notification {
    // Set the send ID as the IAM unique identifier
    NSDictionary *apnsPayload = notification.notificationInfo;

    if (!apnsPayload[kUAIncomingInAppMessageKey]) {
        return;
    }

    NSMutableDictionary *messagePayload = [NSMutableDictionary dictionaryWithDictionary:apnsPayload[kUAIncomingInAppMessageKey]];
    UAInAppMessage *message = [UAInAppMessage messageWithPayload:messagePayload];

    if (apnsPayload[@"_"]) {
        message.identifier = apnsPayload[@"_"];
    }

#if !TARGET_OS_TV   // Inbox not supported on tvOS
    NSString *inboxMessageID = [UAInboxUtils inboxMessageIDFromNotification:apnsPayload];
    if (inboxMessageID) {
        NSSet *inboxActionNames = [NSSet setWithArray:@[kUADisplayInboxActionDefaultRegistryAlias,
                                                        kUADisplayInboxActionDefaultRegistryName,
                                                        kUAOverlayInboxMessageActionDefaultRegistryAlias,
                                                        kUAOverlayInboxMessageActionDefaultRegistryName]];

        NSSet *actionNames = [NSSet setWithArray:message.onClick.allKeys];

        if (![actionNames intersectsSet:inboxActionNames]) {
            NSMutableDictionary *actions = [NSMutableDictionary dictionaryWithDictionary:message.onClick];
            actions[kUADisplayInboxActionDefaultRegistryAlias] = inboxMessageID;
            message.onClick = actions;
        }
    }
#endif

    self.pendingMessage = message;
}




@end
