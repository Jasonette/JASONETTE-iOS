/* Copyright 2017 Urban Airship and Contributors */

#import "UAPush.h"
#import "UAirship.h"
#import "UAChannelRegistrar+Internal.h"
#import "UAAPNSRegistrationProtocol+Internal.h"
#import "UAAPNSRegistration+Internal.h"

#if !TARGET_OS_TV
#import "UALegacyAPNSRegistration+Internal.h"
#endif

@class UAPreferenceDataStore;
@class UAConfig;
@class UATagGroupsAPIClient;

NS_ASSUME_NONNULL_BEGIN

/**
 * User push notification enabled data store key.
 */
extern NSString *const UAUserPushNotificationsEnabledKey;

/**
 * Background push notification enabled data store key.
 */
extern NSString *const UABackgroundPushNotificationsEnabledKey;

/**
 * Device token sent during channel registration enabled data store key.
 */
extern NSString *const UAPushTokenRegistrationEnabledKey;

/**
 * Alias data store key.
 */
extern NSString *const UAPushAliasSettingsKey;

/**
 * Tags data store key.
 */
extern NSString *const UAPushTagsSettingsKey;

/**
 * Badge data store key.
 */
extern NSString *const UAPushBadgeSettingsKey;

/**
 * Quiet time settings data store key.
 */
extern NSString *const UAPushQuietTimeSettingsKey;

/**
 * Quiet enabled data store key.
 */
extern NSString *const UAPushQuietTimeEnabledSettingsKey;

/**
 * Quiet time time zone data store key.
 */
extern NSString *const UAPushTimeZoneSettingsKey;

/**
 * Quiet time settings start key.
 */
extern NSString *const UAPushQuietTimeStartKey;

/**
 * Quiet time settings end key.
 */
extern NSString *const UAPushQuietTimeEndKey;

/**
 * If channel creation should occur on foreground data store key.
 */
extern NSString *const UAPushChannelCreationOnForeground;

/**
 * If push enabled settings have been migrated data store key.
 */
extern NSString *const UAPushEnabledSettingsMigratedKey;

/**
 * Channel ID data store key.
 */
extern NSString *const UAPushChannelIDKey;

/**
 * Channel location data store key.
 */
extern NSString *const UAPushChannelLocationKey;

/**
 * Add channel tag groups data store key.
 */
extern NSString *const UAPushAddTagGroupsSettingsKey;

/**
 * Remove channel tag groups data store key.
 */
extern NSString *const UAPushRemoveTagGroupsSettingsKey;

/**
 * Tag group mutations data store key.
 */
extern NSString *const UAPushTagGroupsMutationsKey;

/**
 * Old push enabled key.
 */
extern NSString *const UAPushEnabledKey;

@interface UAPush () <UAChannelRegistrarDelegate, UAAPNSRegistrationDelegate>

///---------------------------------------------------------------------------------------
/// @name Push Internal Properties
///---------------------------------------------------------------------------------------

/**
 * Device token as a string.
 */
@property (nonatomic, copy, nullable) NSString *deviceToken;

/**
 * Allows disabling channel registration before a channel is created.  Channel registration will resume
 * when this flag is set to `YES`.
 *
 * Set this to `NO` to disable channel registration. Defaults to `YES`.
 */
@property (nonatomic, assign, getter=isChannelCreationEnabled) BOOL channelCreationEnabled;

/**
 * Channel ID as a string.
 */
@property (nonatomic, copy, nullable) NSString *channelID;

/**
 * Channel location as a string.
 */
@property (nonatomic, copy, nullable) NSString *channelLocation;

/**
 * The UAChannelRegistrar that handles registering the device with Urban Airship.
 */
@property (nonatomic, strong) UAChannelRegistrar *channelRegistrar;

/**
 * Notification that launched the application.
 */
@property (nullable, nonatomic, strong) UANotificationResponse *launchNotificationResponse;

/**
 * Background task identifier used to do any registration in the background.
 */
@property (nonatomic, assign) UIBackgroundTaskIdentifier registrationBackgroundTask;

/**
 * Indicates whether APNS registration is out of date or not.
 */
@property (nonatomic, assign) BOOL shouldUpdateAPNSRegistration;

/**
 * The preference data store.
 */
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;


/**
 * The tag groups API client.
 */
@property (nonatomic, strong) UATagGroupsAPIClient *tagGroupsAPIClient;

/**
 * The current authorized notification options.
 */
@property (nonatomic, assign) UANotificationOptions authorizedNotificationOptions;

/**
 * Indicates whether the user has been prompted for notifications or not.
 */
@property (nonatomic, assign) BOOL userPromptedForNotifications;

/**
 * The push registration instance.
 */
@property (nonatomic, strong) id<UAAPNSRegistrationProtocol> pushRegistration;

///---------------------------------------------------------------------------------------
/// @name Push Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a push instance.
 * @param config The Urban Airship config
 * @param dataStore The preference data store.
 * @return A new push instance.
 */
+ (instancetype)pushWithConfig:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore;

/**
 * Get the local time zone, considered the default.
 * @return The local time zone.
 */
- (NSTimeZone *)defaultTimeZoneForQuietTime;

/**
 * Called on active NSNotificationCenter notifications (on "active" rather than "foreground" so that we
 * can capture the push ID sent with a converting push). Triggers an updateRegistration.
 */
- (void)applicationDidBecomeActive;

/**
 * Used to clear a flag set on foreground to prevent double registration on
 * app init.
 */
- (void)applicationDidEnterBackground;

#if !TARGET_OS_TV    // UIBackgroundRefreshStatusAvailable not available on tvOS
/**
 * Used to update channel registration when the background refresh status changes.
 */
- (void)applicationBackgroundRefreshStatusChanged;
#endif

/**
 * Called when the channel registrar failed to register.
 * @param payload The registration payload.
 */
- (void)registrationFailedWithPayload:(UAChannelRegistrationPayload *)payload;

/**
 * Called when the channel registrar succesfully registered.
 * @param payload The registration payload.
 */
- (void)registrationSucceededWithPayload:(UAChannelRegistrationPayload *)payload;

/**
 * Called when the channel registrar creates a new channel.
 * @param channelID The channel ID string.
 * @param channelLocation The channel location string.
 * @param existing Boolean to indicate if the channel previously existed or not.
 */
- (void)channelCreated:(NSString *)channelID
       channelLocation:(NSString *)channelLocation
              existing:(BOOL)existing;

/**
 * Creates a UAChannelRegistrationPayload.
 *
 * @return A UAChannelRegistrationPayload payload.
 */
- (UAChannelRegistrationPayload *)createChannelPayload;

/**
 * Registers or updates the current registration with an API call. If push notifications are
 * not enabled, this unregisters the device token.
 *
 * Add a `UARegistrationDelegate` to `UAPush` to receive success and failure callbacks.
 *
 * @param forcefully Tells the device api client to do any device api call forcefully.
 */
- (void)updateChannelRegistrationForcefully:(BOOL)forcefully;

/**
 * Returns YES if background push is enabled and configured for the device. Used
 * as the channel's 'background' flag.
 */
- (BOOL)backgroundPushNotificationsAllowed;

/**
 * Returns YES if user notifications are configured and enabled for the device. Used
 * as the channel's 'opt_in' flag.
 */
- (BOOL)userPushNotificationsAllowed;

/**
 * Migrates the old pushEnabled setting to the new userPushNotificationsEnabled
 * setting.
 */
- (void)migratePushSettings;

/**
 * Updates the registration with APNS. Call after modifying notification types
 * and user notification categories.
 */
- (void)updateAPNSRegistration;

/**
 * Updates the authorized notification types.
 */
- (void)updateAuthorizedNotificationTypes;

/**
 * Called to return the presentation options for an iOS 10 notification.
 *
 * @param notification The notification.
 * @return Foreground presentation options.
 */
- (UNNotificationPresentationOptions)presentationOptionsForNotification:(UNNotification *)notification;

/**
 * Called when a notification response is received.
 * 
 * @param response The notification response.
 * @param handler The completion handler.
 */
- (void)handleNotificationResponse:(UANotificationResponse *)response completionHandler:(void (^)(void))handler;

/**
 * Called when a remote notification is received.
 *
 * @param notification The notification content.
 * @param foreground If the notification was recieved in the foreground or not.
 * @param handler The completion handler.
 */
- (void)handleRemoteNotification:(UANotificationContent *)notification foreground:(BOOL)foreground completionHandler:(void (^)(UIBackgroundFetchResult))handler;

/**
 * Called by the UIApplicationDelegate's application:didRegisterForRemoteNotificationsWithDeviceToken:
 * so UAPush can forward the delegate call to its registration delegate.
 *
 * @param application The application instance.
 * @param deviceToken The APNS device token.
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 * Called by the UIApplicationDelegate's application:didFailToRegisterForRemoteNotificationsWithError:
 * so UAPush can forward the delegate call to its registration delegate.
 *
 * @param application The application instance.
 * @param error An NSError object that encapsulates information why registration did not succeed.
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
#if !TARGET_OS_TV
/**
 * Called by the UIApplicationDelegate's application:didRegisterUserNotificationSettings:
 * so UAPush can forward the delegate call to its registration delegate.
 *
 * @param application The application instance.
 * @param notificationSettings The resulting notification settings.
 *
 * @deprecated Deprecated in iOS 10.
 */
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings NS_DEPRECATED_IOS(8_0, 10_0, "Deprecated in iOS 10");
#endif

/**
 * Called to update the tag groups for the current channel.
 */
- (void)updateChannelTagGroups;

@end

NS_ASSUME_NONNULL_END
