/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UAAnalytics+Internal.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAEventManager+Internal.h"
#import "UAConfig.h"
#import "UAEvent.h"
#import "UAUtils.h"

#import "UAAppBackgroundEvent+Internal.h"
#import "UAAppForegroundEvent+Internal.h"
#import "UAScreenTrackingEvent+Internal.h"
#import "UARegionEvent+Internal.h"
#import "UAAssociateIdentifiersEvent+Internal.h"
#import "UAAssociatedIdentifiers.h"
#import "UACustomEvent.h"

#if !TARGET_OS_TV
#import "UAInboxUtils.h"
#endif

#define kUAAssociatedIdentifiers @"UAAssociatedIdentifiers"

@interface UAAnalytics()
@property (nonatomic, strong) UAConfig *config;
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;
@property (nonatomic, strong) UAEventManager *eventManager;

@property (nonatomic, assign) BOOL isEnteringForeground;

// Screen tracking state
@property (nonatomic, strong) NSString *currentScreen;
@property (nonatomic, strong) NSString *previousScreen;
@property (nonatomic, assign) NSTimeInterval startTime;
@end

@implementation UAAnalytics


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithConfig:(UAConfig *)airshipConfig dataStore:(UAPreferenceDataStore *)dataStore eventManager:(UAEventManager *)eventManager {
    self = [super init];

    if (self) {
        // Set server to default if not specified in options
        self.config = airshipConfig;
        self.dataStore = dataStore;
        self.eventManager = eventManager;

        // Default analytics value
        if (![self.dataStore objectForKey:kUAAnalyticsEnabled]) {
            [self.dataStore setBool:YES forKey:kUAAnalyticsEnabled];
        }

        // Register for background notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        // Register for foreground notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        // App inactive/active for incoming calls, notification center, and taskbar
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];

        // Register for terminate notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willTerminate)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];

        [self startSession];

        if (!self.isEnabled) {
            [self.eventManager deleteAllEvents];
        }
    }

    return self;
}

+ (instancetype)analyticsWithConfig:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    return [[UAAnalytics alloc] initWithConfig:config
                                     dataStore:dataStore
                                  eventManager:[UAEventManager eventManagerWithConfig:config dataStore:dataStore]];
}

+ (instancetype)analyticsWithConfig:(UAConfig *)config
                          dataStore:(UAPreferenceDataStore *)dataStore
                       eventManager:(UAEventManager *)eventManager {

    return [[UAAnalytics alloc] initWithConfig:config
                                     dataStore:dataStore
                                  eventManager:eventManager];

}

#pragma mark -
#pragma mark Application State

- (void)enterForeground {
    UA_LTRACE(@"Enter Foreground.");

    // Start tracking previous screen before backgrounding began
    [self trackScreen:self.previousScreen];

    // do not send the foreground event yet, as we are not actually in the foreground
    // (we are merely in the process of foregorunding)
    // set this flag so that the even will be sent as soon as the app is active.
    self.isEnteringForeground = YES;
}

- (void)enterBackground {
    UA_LTRACE(@"Enter Background.");

    [self stopTrackingScreen];

    // add app_background event
    [self addEvent:[UAAppBackgroundEvent event]];

    [self startSession];
    self.conversionSendID = nil;
    self.conversionRichPushID = nil;
    self.conversionPushMetadata = nil;
}

- (void)willTerminate {
    UA_LTRACE(@"Application is terminating.");

    [self stopTrackingScreen];
}

- (void)didBecomeActive {
    UA_LTRACE(@"Application did become active.");

    // If this is the first 'inactive->active' transition in this session,
    // send
    if (self.isEnteringForeground) {

        self.isEnteringForeground = NO;

        // Start a new session
        [self startSession];

        //add app_foreground event
        [self addEvent:[UAAppForegroundEvent event]];
    }
}


#pragma mark -
#pragma mark Analytics

- (void)addEvent:(UAEvent *)event {
    if (!event.isValid) {
        UA_LWARN(@"Dropping invalid event %@.", event);
        return;
    }

    if (!self.isEnabled) {
        UA_LTRACE(@"Analytics disabled, ignoring event: %@", event.eventType);
        return;
    }

    UA_LDEBUG(@"Adding %@ event %@.", event.eventType, event.eventID);
    [self.eventManager addEvent:event sessionID:self.sessionID];
    UA_LTRACE(@"Event added: %@.", event);

    id strongDelegate = self.delegate;
    if ([event isKindOfClass:[UACustomEvent class]]) {
        if ([strongDelegate respondsToSelector:@selector(customEventAdded:)]) {
            [strongDelegate customEventAdded:(UACustomEvent *)event];
        }
    }

    if ([event isKindOfClass:[UARegionEvent class]]) {
        if ([strongDelegate respondsToSelector:@selector(regionEventAdded:)]) {
            [strongDelegate regionEventAdded:(UARegionEvent *)event];
        }
    }
}


- (void)launchedFromNotification:(NSDictionary *)notification {
    if (!notification) {
        return;
    }

    // If the server did not send a push ID (likely because the payload did not have room)
    // then send "MISSING_SEND_ID"
    if ([UAUtils isAlertingPush:notification]) {
        self.conversionSendID = [notification objectForKey:@"_"] ?: kUAMissingSendID;
    } else {
        self.conversionSendID = nil;
    }

    // If the server did not send the metadata, then set it to nil
    self.conversionPushMetadata = [notification objectForKey:kUAPushMetadata] ?: nil;

#if !TARGET_OS_TV   // Inbox not supported on tvOS
    NSString *richPushID = [UAInboxUtils inboxMessageIDFromNotification:notification];
    if (richPushID) {
        self.conversionRichPushID = richPushID;
    }
#endif
}

- (void)startSession {
    self.sessionID = [NSUUID UUID].UUIDString;
}

- (BOOL)isEnabled {
    return [self.dataStore boolForKey:kUAAnalyticsEnabled] && self.config.analyticsEnabled;
}

- (void)setEnabled:(BOOL)enabled {
    // If we are disabling the runtime flag clear all events
    if ([self.dataStore boolForKey:kUAAnalyticsEnabled] && !enabled) {
        UA_LINFO(@"Deleting all analytics events.");
        [self.eventManager deleteAllEvents];
    }

    [self.dataStore setBool:enabled forKey:kUAAnalyticsEnabled];
}

- (void)associateDeviceIdentifiers:(UAAssociatedIdentifiers *)associatedIdentifiers {
    [self.dataStore setObject:associatedIdentifiers.allIDs forKey:kUAAssociatedIdentifiers];
    [self addEvent:[UAAssociateIdentifiersEvent eventWithIDs:associatedIdentifiers]];
}

- (UAAssociatedIdentifiers *)currentAssociatedDeviceIdentifiers {
    NSDictionary *storedIDs = [self.dataStore objectForKey:kUAAssociatedIdentifiers];
    return [UAAssociatedIdentifiers identifiersWithDictionary:storedIDs];
}

- (void)trackScreen:(nullable NSString *)screen {

    // Prevent duplicate calls to track same screen
    if ([screen isEqualToString:self.currentScreen]) {
        return;
    }

    id strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(screenTracked:)]) {
        [strongDelegate screenTracked:screen];
    }

    // If there's a screen currently being tracked set it's stop time and add it to analytics
    if (self.currentScreen) {
        UAScreenTrackingEvent *ste = [UAScreenTrackingEvent eventWithScreen:self.currentScreen startTime:self.startTime];
        ste.stopTime = [NSDate date].timeIntervalSince1970;
        ste.previousScreen = self.previousScreen;

        // Set previous screen to last tracked screen
        self.previousScreen = self.currentScreen;

        // Add screen tracking event to next analytics batch
        [self addEvent:ste];
    }
    
    self.currentScreen = screen;
    self.startTime = [NSDate date].timeIntervalSince1970;
}

- (void)stopTrackingScreen {
    [self trackScreen:nil];
}

- (void)cancelUpload {
    [self.eventManager cancelUpload];
}

- (void)scheduleUpload {
    [self.eventManager scheduleUpload];
}

@end
