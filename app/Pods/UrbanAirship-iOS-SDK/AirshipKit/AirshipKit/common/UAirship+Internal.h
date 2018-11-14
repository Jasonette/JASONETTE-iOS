/* Copyright 2017 Urban Airship and Contributors */

#import "UAirship.h"

@class UABaseAppDelegateSurrogate;
@class UAJavaScriptDelegate;
@class UAPreferenceDataStore;
@class UAChannelCapture;


@interface UAirship()

NS_ASSUME_NONNULL_BEGIN

///---------------------------------------------------------------------------------------
/// @name Airship Internal Properties
///---------------------------------------------------------------------------------------

// Setters for public readonly-getters
@property (nonatomic, strong) UAConfig *config;
@property (nonatomic, strong) UAAnalytics *analytics;
@property (nonatomic, strong) UAActionRegistry *actionRegistry;
@property (nonatomic, assign) BOOL remoteNotificationBackgroundModeEnabled;
@property (nonatomic, strong, nullable) id<UAJavaScriptDelegate> actionJSDelegate;
@property (nonatomic, strong) UAApplicationMetrics *applicationMetrics;
@property (nonatomic, strong) UAWhitelist *whitelist;
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;
@property (nonatomic, strong) UAChannelCapture *channelCapture;

/**
 * The push manager.
 */
@property (nonatomic, strong) UAPush *sharedPush;


/**
 * The inbox user.
 */
@property (nonatomic, strong) UAUser *sharedInboxUser;

#if !TARGET_OS_TV   // Inbox not supported on tvOS
/**
 * The inbox.
 */
@property (nonatomic, strong) UAInbox *sharedInbox;
#endif

/**
 * The in-app messaging manager.
 */
@property (nonatomic, strong) UAInAppMessaging *sharedInAppMessaging;

/**
 * The default message center.
 */
@property (nonatomic, strong) UADefaultMessageCenter *sharedDefaultMessageCenter;

/**
 * The location manager.
 */
@property (nonatomic, strong) UALocation *sharedLocation;

/**
 * The named user.
 */
@property (nonatomic, strong) UANamedUser *sharedNamedUser;


/**
 * Shared automation manager.
 */
@property (nonatomic, strong) UAAutomation *sharedAutomation;

///---------------------------------------------------------------------------------------
/// @name Airship Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Handle app init. This should be called from NSNotification center
 * and will record a launch from notification and record the app init even
 * for analytics.
 * @param notification The app did finish launching notification
 */
+ (void)handleAppDidFinishLaunchingNotification:(NSNotification *)notification;

/**
 * Handle a termination event from NSNotification center (forward it to land)
 * @param notification The app termination notification
 */
+ (void)handleAppTerminationNotification:(NSNotification *)notification;

/**
 * Perform teardown on the shared instance. This will automatically be called when an application
 * terminates.
 */
+ (void)land;

/**
 * Sets the shared airship.
 * @param airship The shared airship instance.
 */
+ (void)setSharedAirship:(UAirship * __nullable)airship;

NS_ASSUME_NONNULL_END

@end
