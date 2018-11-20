/* Copyright 2017 Urban Airship and Contributors */

#import <CoreLocation/CoreLocation.h>

#import "UAirship+Internal.h"

#import "UAUser+Internal.h"
#import "UAAnalytics+Internal.h"
#import "UAUtils.h"
#import "UAKeychainUtils+Internal.h"
#import "UAGlobal.h"
#import "UAPush+Internal.h"
#import "UAConfig.h"
#import "UAApplicationMetrics.h"
#import "UAActionRegistry.h"
#import "UALocation+Internal.h"
#import "UAAutoIntegration+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "UAURLProtocol.h"
#import "UAAppInitEvent+Internal.h"
#import "UAAppExitEvent+Internal.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UANamedUser+Internal.h"
#import "UAAutomation+Internal.h"
#import "UAAppIntegration.h"

#if !TARGET_OS_TV
#import "UAInbox+Internal.h"
#import "UAActionJSDelegate.h"
#import "UAChannelCapture.h"
#import "UADefaultMessageCenter.h"
#import "UAInboxAPIClient+Internal.h"
#import "UAInAppMessaging+Internal.h"
#endif


// Exceptions
NSString * const UAirshipTakeOffBackgroundThreadException = @"UAirshipTakeOffBackgroundThreadException";
NSString * const UAResetKeychainKey = @"com.urbanairship.reset_keychain";

NSString * const UALibraryVersion = @"com.urbanairship.library_version";


static UAirship *sharedAirship_;

static NSBundle *resourcesBundle_;

static dispatch_once_t takeOffPred_;

// Its possible that plugins that use load to call takeoff will trigger after
// handleAppDidFinishLaunchingNotification.  We need to store that notification
// and call handleAppDidFinishLaunchingNotification in takeoff.
static NSNotification *appDidFinishLaunchingNotification_;


// Logging info
// Default to ON and ERROR - options/plist will override
BOOL uaLoggingEnabled = YES;
UALogLevel uaLogLevel = UALogLevelError;
BOOL uaLoudImpErrorLoggingEnabled = YES;

@implementation UAirship

#pragma mark -
#pragma mark Logging
+ (void)setLogging:(BOOL)value {
    uaLoggingEnabled = value;
}

+ (void)setLogLevel:(UALogLevel)level {
    uaLogLevel = level;
}

+ (void)setLoudImpErrorLogging:(BOOL)enabled{
    uaLoudImpErrorLoggingEnabled = enabled;
}

+ (void)load {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:[UAirship class] selector:@selector(handleAppDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [center addObserver:[UAirship class] selector:@selector(handleAppTerminationNotification:) name:UIApplicationWillTerminateNotification object:nil];
}


#pragma mark -
#pragma mark Object Lifecycle

- (instancetype)initWithConfig:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    self = [super init];
    if (self) {
#if TARGET_OS_TV   // remote-notification background mode not supported in tvOS
        // REVISIT - Replace this with a try-except block on objectForInfoDictionaryKey:@"UIBackgroundModes" - assume yes if no UIBackgroundModes but tvOS?
        self.remoteNotificationBackgroundModeEnabled = YES;
#else
        self.remoteNotificationBackgroundModeEnabled = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"] containsObject:@"remote-notification"];
#endif
        self.dataStore = dataStore;
        self.config = config;
        self.applicationMetrics = [UAApplicationMetrics applicationMetricsWithDataStore:dataStore];
        self.actionRegistry = [UAActionRegistry defaultRegistry];
        self.sharedPush = [UAPush pushWithConfig:config dataStore:dataStore];
        self.sharedInboxUser = [UAUser userWithPush:self.sharedPush config:config dataStore:dataStore];
        self.sharedNamedUser = [UANamedUser namedUserWithPush:self.sharedPush config:config dataStore:dataStore];
        self.analytics = [UAAnalytics analyticsWithConfig:config dataStore:dataStore];
        self.whitelist = [UAWhitelist whitelistWithConfig:config];
        self.sharedLocation = [UALocation locationWithAnalytics:self.analytics dataStore:dataStore];
        self.sharedAutomation = [UAAutomation automationWithConfig:config dataStore:dataStore];
        self.analytics.delegate = self.sharedAutomation;

#if !TARGET_OS_TV
        // IAP Nib not supported on tvOS
        self.sharedInAppMessaging = [UAInAppMessaging inAppMessagingWithAnalytics:self.analytics dataStore:dataStore];

        // Message center not supported on tvOS
        self.sharedInbox = [UAInbox inboxWithUser:self.sharedInboxUser config:config dataStore:dataStore];
        // Not supporting Javascript in tvOS
        self.actionJSDelegate = [[UAActionJSDelegate alloc] init];
        // UIPasteboard is not available in tvOS
        self.channelCapture = [UAChannelCapture channelCaptureWithConfig:config push:self.sharedPush dataStore:self.dataStore];

       // Only create the default message center if running iOS 8 and above
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){8, 0, 0}]) {
            if ([UAirship resources]) {
                self.sharedDefaultMessageCenter = [UADefaultMessageCenter messageCenterWithConfig:self.config];
            } else {
                UA_LINFO(@"Unable to initialize default message center: AirshipResources is missing");
            }
        }
#endif
    }

    return self;
}

+ (void)takeOff {
    if (![[NSBundle mainBundle] pathForResource:@"AirshipConfig" ofType:@"plist"]) {
        UA_LIMPERR(@"AirshipConfig.plist file is missing. Unable to takeOff.");
        // Bail now. Don't continue the takeOff sequence.
        return;
    }

    [UAirship takeOff:[UAConfig defaultConfig]];
}

+ (void)takeOff:(UAConfig *)config {
    UA_BUILD_WARNINGS;

    // takeOff needs to be run on the main thread
    if (![[NSThread currentThread] isMainThread]) {
        NSException *mainThreadException = [NSException exceptionWithName:UAirshipTakeOffBackgroundThreadException
                                                                   reason:@"UAirship takeOff must be called on the main thread."
                                                                 userInfo:nil];
        [mainThreadException raise];
    }

    dispatch_once(&takeOffPred_, ^{
        [UAirship executeUnsafeTakeOff:[config copy]];
    });
}

/*
 * This is an unsafe version of takeOff - use takeOff: instead for dispatch_once
 */
+ (void)executeUnsafeTakeOff:(UAConfig *)config {

    // Airships only take off once!
    if (sharedAirship_) {
        return;
    }

    [UAirship setLogLevel:config.logLevel];

    if (config.inProduction) {
        [UAirship setLoudImpErrorLogging:NO];
    }

    // Ensure that app credentials are valid
    if (![config validate]) {
        UA_LIMPERR(@"The UAConfig is invalid, no application credentials were specified at runtime.");
        // Bail now. Don't continue the takeOff sequence.
        return;
    }

    UA_LINFO(@"UAirship Take Off! Lib Version: %@ App Key: %@ Production: %@.",
             [UAirshipVersion get], config.appKey, config.inProduction ?  @"YES" : @"NO");

    
    // Data store
    UAPreferenceDataStore *dataStore = [UAPreferenceDataStore preferenceDataStoreWithKeyPrefix:[NSString stringWithFormat:@"com.urbanairship.%@.", config.appKey]];
    [dataStore migrateUnprefixedKeys:@[UALibraryVersion]];

    // Cache
    if (config.cacheDiskSizeInMB > 0) {
        UA_LTRACE("Registering UAURLProtocol.");
        [NSURLProtocol registerClass:[UAURLProtocol class]];
    }


    // Clearing the key chain
    if ([[NSUserDefaults standardUserDefaults] boolForKey:UAResetKeychainKey]) {
        UA_LDEBUG(@"Deleting the keychain credentials");
        [UAKeychainUtils deleteKeychainValue:config.appKey];

        UA_LDEBUG(@"Deleting the UA device ID");
        [UAKeychainUtils deleteKeychainValue:kUAKeychainDeviceIDKey];

        // Delete the Device ID in the data store so we don't clear the channel
        [dataStore removeObjectForKey:@"deviceId"];

        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:UAResetKeychainKey];
    }

    NSString *previousDeviceId = [dataStore stringForKey:@"deviceId"];
    NSString *currentDeviceId = [UAKeychainUtils getDeviceID];

    if (previousDeviceId && ![previousDeviceId isEqualToString:currentDeviceId]) {
        // Device ID changed since the last open. Most likely due to an app restore
        // on a different device.
        UA_LDEBUG(@"Device ID changed.");

        UA_LDEBUG(@"Clearing previous channel.");
        [dataStore removeObjectForKey:UAPushChannelLocationKey];
        [dataStore removeObjectForKey:UAPushChannelIDKey];

        if (config.clearUserOnAppRestore) {
            UA_LDEBUG(@"Deleting the keychain credentials");
            [UAKeychainUtils deleteKeychainValue:config.appKey];
        }
    }

    // Save the Device ID to the data store to detect when it changes
    [dataStore setObject:currentDeviceId forKey:@"deviceId"];

    // Create Airship
    [UAirship setSharedAirship:[[UAirship alloc] initWithConfig:config dataStore:dataStore]];

    // Save the version
    if ([[UAirshipVersion get] isEqualToString:@"0.0.0"]) {
        UA_LIMPERR(@"_UA_VERSION is undefined - this commonly indicates an issue with the build configuration, UA_VERSION will be set to \"0.0.0\".");
    } else {
        NSString *previousVersion = [sharedAirship_.dataStore stringForKey:UALibraryVersion];
        if (![[UAirshipVersion get] isEqualToString:previousVersion]) {
            [dataStore setObject:[UAirshipVersion get] forKey:UALibraryVersion];

#if !TARGET_OS_TV   // Inbox not supported on tvOS
            // Temp workaround for MB-1047 where model changes to the inbox
            // will drop the inbox and the last-modified-time will prevent
            // repopulating the messages.
            [sharedAirship_.sharedInbox.client clearLastModifiedTime];
#endif

            if (previousVersion) {
                UA_LINFO(@"Urban Airship library version changed from %@ to %@.", previousVersion, [UAirshipVersion get]);
            }
        }
    }

    // Validate any setup issues
    if (!config.inProduction) {
        [sharedAirship_ validate];
    }
    
    // Automatic setup
    if (sharedAirship_.config.automaticSetupEnabled) {
        UA_LINFO(@"Automatic setup enabled.");
        [UAAutoIntegration integrate];
    }

    if (appDidFinishLaunchingNotification_) {
        // Set up can occur after takeoff, so handle the launch notification on the
        // next run loop to allow app setup to finish
        dispatch_async(dispatch_get_main_queue(), ^() {
            [UAirship handleAppDidFinishLaunchingNotification:appDidFinishLaunchingNotification_];
            appDidFinishLaunchingNotification_ = nil;
        });
    }
}

+ (void)handleAppDidFinishLaunchingNotification:(NSNotification *)notification {

    [[NSNotificationCenter defaultCenter] removeObserver:[UAirship class] name:UIApplicationDidFinishLaunchingNotification object:nil];

    if (!sharedAirship_) {
        appDidFinishLaunchingNotification_ = notification;

        // Log takeoff errors on the next run loop to give time for apps that
        // use class loader to call takeoff.
        dispatch_async(dispatch_get_main_queue(), ^() {
            if (!sharedAirship_) {
                UA_LERR(@"[UAirship takeOff] was not called in application:didFinishLaunchingWithOptions:");
                UA_LERR(@"Please ensure that [UAirship takeOff] is called synchronously before application:didFinishLaunchingWithOptions: returns");
            }
        });

        return;
    }

#if !TARGET_OS_TV    // UIApplicationLaunchOptionsRemoteNotificationKey not available on tvOS
    NSDictionary *remoteNotification = [notification.userInfo objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

    // Required before the app init event to track conversion push ID
    if (remoteNotification) {
        [sharedAirship_.analytics launchedFromNotification:remoteNotification];
    }

#endif
    // Init event
    [sharedAirship_.analytics addEvent:[UAAppInitEvent event]];

    // Update registration on the next run loop to allow apps to customize
    // finish custom setup
    dispatch_async(dispatch_get_main_queue(), ^() {
        [sharedAirship_.sharedPush updateRegistration];
    });

}

+ (void)handleAppTerminationNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:[UAirship class]  name:UIApplicationWillTerminateNotification object:nil];

    // Add app_exit event
    [[UAirship shared].analytics addEvent:[UAAppExitEvent event]];

    // Land it
    [UAirship land];
}

+ (void)land {
    if (!sharedAirship_) {
        return;
    }

    // Invalidate UAAnalytics timer and cancel all queued operations
    [sharedAirship_.analytics cancelUpload];

#if !TARGET_OS_TV
    // Invalidate UAInAppMessaging autodisplay timer
    [sharedAirship_.sharedInAppMessaging invalidateAutoDisplayTimer];
#endif

    // Finally, release the airship!
    [UAirship setSharedAirship:nil];

    // Reset the dispatch_once_t flag for testing
    takeOffPred_ = 0;
}

+ (void)setSharedAirship:(UAirship *)airship {
    sharedAirship_ = airship;
}

+ (UAirship *)shared {
    return sharedAirship_;
}

+ (UAPush *)push {
    return sharedAirship_.sharedPush;
}

#if !TARGET_OS_TV   // Inbox not supported on tvOS
+ (UAInbox *)inbox {
    return sharedAirship_.sharedInbox;
}

+ (UAUser *)inboxUser {
    return sharedAirship_.sharedInboxUser;
}


+ (UAInAppMessaging *)inAppMessaging {
    return sharedAirship_.sharedInAppMessaging;
}

+ (UADefaultMessageCenter *)defaultMessageCenter {
    return sharedAirship_.sharedDefaultMessageCenter;
}

#endif

+ (UALocation *)location {
    return sharedAirship_.sharedLocation;
}

+ (UANamedUser *)namedUser {
    return sharedAirship_.sharedNamedUser;
}

+ (UAAutomation *)automation {
    return sharedAirship_.sharedAutomation;
}

+ (NSBundle *)resources {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Don't assume that we are within the main bundle
        NSBundle *containingBundle = [NSBundle bundleForClass:self];
#if !TARGET_OS_TV
        NSURL *resourcesBundleURL = [containingBundle URLForResource:@"AirshipResources" withExtension:@"bundle"];
#else
        NSURL *resourcesBundleURL = [containingBundle URLForResource:@"AirshipResources tvOS" withExtension:@"bundle"];
#endif
        if (resourcesBundleURL) {
            resourcesBundle_ = [NSBundle bundleWithURL:resourcesBundleURL];
        }
        if (!resourcesBundle_) {
            UA_LIMPERR(@"AirshipResources.bundle could not be found. If using the static library, you must add this file to your application's Copy Bundle Resources phase, or use the AirshipKit embedded framework");
        }
    });
    return resourcesBundle_;
}

- (void)validate {
    // Background notification validation
    if (self.remoteNotificationBackgroundModeEnabled) {

        if (self.config.automaticSetupEnabled) {
            id delegate = [UIApplication sharedApplication].delegate;

            // If its automatic setup up, make sure if they are implementing their own app delegates, that they are
            // also implementing the new application:didReceiveRemoteNotification:fetchCompletionHandler: call.
            if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]
                && ![delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {

                UA_LIMPERR(@"Application is set up to receive background notifications, but the app delegate only implements application:didReceiveRemoteNotification: and not application:didReceiveRemoteNotification:fetchCompletionHandler. application:didReceiveRemoteNotification: will be ignored.");
            }
        } else {
            id delegate = [UIApplication sharedApplication].delegate;

            // They must implement application:didReceiveRemoteNotification:fetchCompletionHandler: to handle background
            // notifications
            if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]
                && ![delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {

                UA_LIMPERR(@"Application is set up to receive background notifications, but the app delegate does not implements application:didReceiveRemoteNotification:fetchCompletionHandler:. Use either UAirship automaticSetupEnabled or implement a proper application:didReceiveRemoteNotification:fetchCompletionHandler: in the app delegate.");
            }
        }
    } else {
#if !TARGET_OS_TV   // remote-notification background mode not supported in tvOS
        UA_LIMPERR(@"Application is not configured for background notifications. "
                 @"Please enable remote notifications in the application's background modes.");
#endif
    }

    // -ObjC linker flag is set
    if (![[NSJSONSerialization class] respondsToSelector:@selector(stringWithObject:)]) {
        UA_LIMPERR(@"UAirship library requires the '-ObjC' linker flag set in 'Other linker flags'.");
    }

}

@end

