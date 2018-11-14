/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>

#import "UAPush+Internal.h"
#import "UAirship+Internal.h"
#import "UAAnalytics+Internal.h"
#import "UADeviceRegistrationEvent+Internal.h"

#import "UAUtils.h"
#import "UAActionRegistry+Internal.h"
#import "UAActionRunner+Internal.h"
#import "UAChannelRegistrationPayload+Internal.h"
#import "UAUser.h"
#import "UAInteractiveNotificationEvent+Internal.h"
#import "UANotificationCategories+Internal.h"
#import "UANotificationCategory.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAConfig.h"
#import "UANotificationCategory.h"
#import "UATagGroupsAPIClient+Internal.h"
#import "UATagUtils+Internal.h"
#import "UAPushReceivedEvent+Internal.h"
#import "UATagGroupsMutation+Internal.h"
#import "UAPreferenceDataStore+InternalTagGroupsMutation.h"

#if !TARGET_OS_TV
#import "UAInboxUtils.h"
#endif

NSString *const UAUserPushNotificationsEnabledKey = @"UAUserPushNotificationsEnabled";
NSString *const UABackgroundPushNotificationsEnabledKey = @"UABackgroundPushNotificationsEnabled";
NSString *const UAPushTokenRegistrationEnabledKey = @"UAPushTokenRegistrationEnabled";

NSString *const UAPushAliasSettingsKey = @"UAPushAlias";
NSString *const UAPushTagsSettingsKey = @"UAPushTags";
NSString *const UAPushBadgeSettingsKey = @"UAPushBadge";
NSString *const UAPushChannelIDKey = @"UAChannelID";
NSString *const UAPushChannelLocationKey = @"UAChannelLocation";
NSString *const UAPushDeviceTokenKey = @"UADeviceToken";

NSString *const UAPushQuietTimeSettingsKey = @"UAPushQuietTime";
NSString *const UAPushQuietTimeEnabledSettingsKey = @"UAPushQuietTimeEnabled";
NSString *const UAPushTimeZoneSettingsKey = @"UAPushTimeZone";

NSString *const UAPushChannelCreationOnForeground = @"UAPushChannelCreationOnForeground";
NSString *const UAPushEnabledSettingsMigratedKey = @"UAPushEnabledSettingsMigrated";

NSString *const UAPushTypesAuthorizedKey = @"UAPushTypesAuthorized";
NSString *const UAPushUserPromptedForNotificationsKey = @"UAPushUserPromptedForNotifications";

// Old push enabled key
NSString *const UAPushEnabledKey = @"UAPushEnabled";

// Quiet time dictionary keys
NSString *const UAPushQuietTimeStartKey = @"start";
NSString *const UAPushQuietTimeEndKey = @"end";

// Channel tag group keys
NSString *const UAPushAddTagGroupsSettingsKey = @"UAPushAddTagGroups";
NSString *const UAPushRemoveTagGroupsSettingsKey = @"UAPushRemoveTagGroups";
NSString *const UAPushTagGroupsMutationsKey = @"UAPushTagGroupsMutations";

// The default device tag group.
NSString *const UAPushDefaultDeviceTagGroup = @"device";

NSString *const UAChannelCreatedEvent = @"com.urbanairship.push.channel_created";
NSString *const UAChannelUpdatedEvent = @"com.urbanairship.push.channel_updated";

NSString *const UAChannelCreatedEventChannelKey = @"com.urbanairship.push.channel_id";
NSString *const UAChannelCreatedEventExistingKey = @"com.urbanairship.push.existing";

NSString *const UAChannelUpdatedEventChannelKey = @"com.urbanairship.push.channel_id";

@implementation UAPush

// Both getter and setter are custom here, so give the compiler a hand with the synthesizing
@synthesize requireSettingsAppToDisableUserNotifications = _requireSettingsAppToDisableUserNotifications;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithConfig:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;

#if TARGET_OS_TV    // legacy APNS registration not available on tvOS
        self.pushRegistration = [[UAAPNSRegistration alloc] init];
#else
        if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}]) {
            self.pushRegistration = [[UALegacyAPNSRegistration alloc] init];
        } else {
            self.pushRegistration = [[UAAPNSRegistration alloc] init];
        }
#endif
        self.pushRegistration.registrationDelegate = self;

        self.channelTagRegistrationEnabled = YES;
        self.requireAuthorizationForDefaultCategories = YES;
        self.backgroundPushNotificationsEnabledByDefault = YES;

        // Require use of the settings app to change push settings
        // but allow the app to unregister to keep things in sync
        self.requireSettingsAppToDisableUserNotifications = YES;
        self.allowUnregisteringUserNotificationTypes = YES;

        self.notificationOptions = UANotificationOptionBadge;
#if !TARGET_OS_TV
        self.notificationOptions = self.notificationOptions|UANotificationOptionSound|UANotificationOptionAlert;
#endif

        self.registrationBackgroundTask = UIBackgroundTaskInvalid;

        self.channelRegistrar = [UAChannelRegistrar channelRegistrarWithConfig:config];
        self.channelRegistrar.delegate = self;

        self.tagGroupsAPIClient = [UATagGroupsAPIClient clientWithConfig:config];

        // Check config to see if user wants to delay channel creation
        // If channel ID exists or channel creation delay is disabled then channelCreationEnabled
        if (self.channelID || !config.isChannelCreationDelayEnabled) {
            self.channelCreationEnabled = YES;
        } else {
            UA_LDEBUG(@"Channel creation disabled.");
            self.channelCreationEnabled = NO;
        }

        // For observing each foreground entry
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        // Only for observing the first call to app foreground
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:[UIApplication sharedApplication]];

        // Only for observing the first call to app background
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:[UIApplication sharedApplication]];

#if !TARGET_OS_TV    // UIApplicationBackgroundRefreshStatusDidChangeNotification not available on tvOS
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationBackgroundRefreshStatusChanged)
                                                     name:UIApplicationBackgroundRefreshStatusDidChangeNotification
                                                   object:[UIApplication sharedApplication]];
#endif

        // Do not remove migratePushSettings call from init. It needs to be run
        // prior to allowing the application to set defaults.
        [self migratePushSettings];

        [self.dataStore migrateTagGroupSettingsForAddTagsKey:UAPushAddTagGroupsSettingsKey
                                               removeTagsKey:UAPushRemoveTagGroupsSettingsKey
                                                      newKey:UAPushTagGroupsMutationsKey];

        // Log the channel ID at error level, but without logging
        // it as an error.
        if (self.channelID && uaLogLevel >= UALogLevelError) {
            NSLog(@"Channel ID: %@", self.channelID);
        }

        // Register for remote notifications right away. This does not prompt for permissions to show notifications,
        // but starts the device token registration.
        [[UIApplication sharedApplication] registerForRemoteNotifications];

        [self updateAuthorizedNotificationTypes];

        self.defaultPresentationOptions = UNNotificationPresentationOptionNone;
    }

    return self;
}

+ (instancetype)pushWithConfig:(UAConfig *)config dataStore:(UAPreferenceDataStore *)dataStore {
    return [[UAPush alloc] initWithConfig:config dataStore:dataStore];
}

- (void)updateAuthorizedNotificationTypes {
    [self.pushRegistration getCurrentAuthorizationOptionsWithCompletionHandler:^(UANotificationOptions options) {
        if (self.userPromptedForNotifications || options != UANotificationOptionNone) {
            self.userPromptedForNotifications = YES;
            self.authorizedNotificationOptions = options;
        }
    }];
}

#pragma mark -
#pragma mark Device Token Get/Set Methods

- (UANotificationOptions)authorizedNotificationOptions {
    if (!self.userPushNotificationsEnabled) {
        return 0;
    }

    // iOS 10 does not disable the types if they are already authorized. Hide any types
    // that are authorized but are no longer requested
    return (UANotificationOptions) [self.dataStore integerForKey:UAPushTypesAuthorizedKey] & self.notificationOptions;
}

- (void)setAuthorizedNotificationOptions:(UANotificationOptions)types {
    if (![self.dataStore objectForKey:UAPushTypesAuthorizedKey] || [self.dataStore integerForKey:UAPushTypesAuthorizedKey] != types) {

        [self.dataStore setInteger:(NSInteger)types forKey:UAPushTypesAuthorizedKey];
        [self updateRegistration];

        id strongDelegate = self.registrationDelegate;
        if ([strongDelegate respondsToSelector:@selector(notificationAuthorizedOptionsDidChange:)]) {
            [strongDelegate notificationAuthorizedOptionsDidChange:types];
        }
    }
}

- (void)setDeviceToken:(NSString *)deviceToken {
    if (deviceToken == nil) {
        [self.dataStore removeObjectForKey:UAPushDeviceTokenKey];
        return;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9a-fA-F]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];

    if ([regex numberOfMatchesInString:deviceToken options:0 range:NSMakeRange(0, [deviceToken length])]) {
        UA_LERR(@"Device token %@ contains invalid characters. Only hex characters are allowed.", deviceToken);
        return;
    }

    // Device tokens are 32 to 100 bytes in binary format, each byte is 2 hex characters
    if (deviceToken.length < 64 || deviceToken.length > 200) {
        UA_LWARN(@"Device token %@ should be 64 to 200 hex characters (32 to 100 bytes) long.", deviceToken);
    }

    [self.dataStore setObject:deviceToken forKey:UAPushDeviceTokenKey];

    // Log the device token at error level, but without logging
    // it as an error.
    if (uaLogLevel >= UALogLevelError) {
        NSLog(@"Device token: %@", deviceToken);
    }
}

- (NSString *)deviceToken {
    return [self.dataStore stringForKey:UAPushDeviceTokenKey];
}

#pragma mark -
#pragma mark Get/Set Methods

- (void)setChannelID:(NSString *)channelID {
    [self.dataStore setValue:channelID forKey:UAPushChannelIDKey];
    // Log the channel ID at error level, but without logging
    // it as an error.
    if (uaLogLevel >= UALogLevelError) {
        NSLog(@"Channel ID: %@", channelID);
    }
}

- (NSString *)channelID {
    // Get the channel location from data store instead of
    // the channelLocation property, because that may cause an infinite loop.
    if ([self.dataStore stringForKey:UAPushChannelLocationKey]) {
        return [self.dataStore stringForKey:UAPushChannelIDKey];
    } else {
        return nil;
    }
}

- (void)setChannelLocation:(NSString *)channelLocation {
    [self.dataStore setValue:channelLocation forKey:UAPushChannelLocationKey];
}

- (NSString *)channelLocation {
    // Get the channel ID from data store instead of
    // the channelID property, because that may cause an infinite loop.
    if ([self.dataStore stringForKey:UAPushChannelIDKey]) {
        return [self.dataStore stringForKey:UAPushChannelLocationKey];
    } else {
        return nil;
    }
}

- (BOOL)isAutobadgeEnabled {
    return [self.dataStore boolForKey:UAPushBadgeSettingsKey];
}

- (void)setAutobadgeEnabled:(BOOL)autobadgeEnabled {
    [self.dataStore setBool:autobadgeEnabled forKey:UAPushBadgeSettingsKey];
}

- (NSString *)alias {
    return [self.dataStore stringForKey:UAPushAliasSettingsKey];
}

- (void)setAlias:(NSString *)alias {
    NSString * trimmedAlias = [alias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self.dataStore setObject:trimmedAlias forKey:UAPushAliasSettingsKey];
}

- (NSArray *)tags {
    NSArray *currentTags = [self.dataStore objectForKey:UAPushTagsSettingsKey];
    if (!currentTags) {
        currentTags = [NSArray array];
    }
    return currentTags;
}

- (void)setTags:(NSArray *)tags {
    [self.dataStore setObject:[UATagUtils normalizeTags:tags] forKey:UAPushTagsSettingsKey];
}

- (void)enableChannelCreation {
    if (!self.channelCreationEnabled) {
        self.channelCreationEnabled = YES;
        [self updateRegistration];
    }
}

- (BOOL)userPushNotificationsEnabled {
    if (![self.dataStore objectForKey:UAUserPushNotificationsEnabledKey]) {
        if ([self.dataStore boolForKey:UAPushEnabledSettingsMigratedKey]) {
            [self.dataStore setBool:self.userPushNotificationsEnabledByDefault forKey:UAUserPushNotificationsEnabledKey];
        }
        return self.userPushNotificationsEnabledByDefault;
    }

    return [self.dataStore boolForKey:UAUserPushNotificationsEnabledKey];
}

- (void)setUserPushNotificationsEnabled:(BOOL)enabled {
    BOOL previousValue = self.userPushNotificationsEnabled;

    // Do not allow disabling if the settings app is required,
    // requireSettingsAppToDisableUserNotifications can only return YES for iOS 8 & 9
    if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}] && !enabled && self.requireSettingsAppToDisableUserNotifications) {
        UA_LWARN(@"User notifications must be disabled via the iOS Settings app for iOS 8 & 9.");
        return;
    }

    [self.dataStore setBool:enabled forKey:UAUserPushNotificationsEnabledKey];

    if (enabled != previousValue) {
        self.shouldUpdateAPNSRegistration = YES;
        [self updateRegistration];
    }
}

- (BOOL)userPromptedForNotifications {
    return [self.dataStore boolForKey:UAPushUserPromptedForNotificationsKey];
}

- (void)setUserPromptedForNotifications:(BOOL)userPrompted {
    BOOL previousValue = self.userPromptedForNotifications;

    if (userPrompted != previousValue) {
        [self.dataStore setBool:userPrompted forKey:UAPushUserPromptedForNotificationsKey];
    }
}

- (BOOL)backgroundPushNotificationsEnabled {
    if (![self.dataStore objectForKey:UABackgroundPushNotificationsEnabledKey]) {
        return self.backgroundPushNotificationsEnabledByDefault;
    }

    return [self.dataStore boolForKey:UABackgroundPushNotificationsEnabledKey];
}

- (void)setBackgroundPushNotificationsEnabled:(BOOL)enabled {
    BOOL previousValue = self.backgroundPushNotificationsEnabled;
    [self.dataStore setBool:enabled forKey:UABackgroundPushNotificationsEnabledKey];

    if (enabled != previousValue) {
        [self updateRegistration];
    }
}

- (BOOL)pushTokenRegistrationEnabled {
    if (![self.dataStore objectForKey:UAPushTokenRegistrationEnabledKey]) {
        return YES;
    }

    return [self.dataStore boolForKey:UAPushTokenRegistrationEnabledKey];
}

- (void)setPushTokenRegistrationEnabled:(BOOL)enabled {
    BOOL previousValue = self.pushTokenRegistrationEnabled;
    [self.dataStore setBool:enabled forKey:UAPushTokenRegistrationEnabledKey];

    if (enabled != previousValue) {
        [self updateRegistration];
    }
}

- (void)setCustomCategories:(NSSet<UANotificationCategory *> *)categories {
    _customCategories = [categories filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        UANotificationCategory *category = evaluatedObject;
        if ([category.identifier hasPrefix:@"ua_"]) {
            UA_LERR(@"Ignoring category %@, only Urban Airship notification categories are allowed to have prefix ua_.", category.identifier);
            return NO;
        }

        return YES;
    }]];

    self.shouldUpdateAPNSRegistration = YES;
}

- (void)setRequireAuthorizationForDefaultCategories:(BOOL)requireAuthorizationForDefaultCategories {
    _requireAuthorizationForDefaultCategories = requireAuthorizationForDefaultCategories;

    self.shouldUpdateAPNSRegistration = YES;
}

- (NSSet<UANotificationCategory *> *)combinedCategories {
    NSMutableSet *categories = [NSMutableSet setWithSet:[UANotificationCategories defaultCategoriesWithRequireAuth:self.requireAuthorizationForDefaultCategories]];
    [categories unionSet:self.customCategories];
    return categories;
}

- (NSDictionary *)quietTime {
    return [self.dataStore dictionaryForKey:UAPushQuietTimeSettingsKey];
}

- (void)setQuietTime:(NSDictionary *)quietTime {
    [self.dataStore setObject:quietTime forKey:UAPushQuietTimeSettingsKey];
}

- (BOOL)isQuietTimeEnabled {
    return [self.dataStore boolForKey:UAPushQuietTimeEnabledSettingsKey];
}

- (void)setQuietTimeEnabled:(BOOL)quietTimeEnabled {
    [self.dataStore setBool:quietTimeEnabled forKey:UAPushQuietTimeEnabledSettingsKey];
}

- (NSTimeZone *)timeZone {
    NSString *timeZoneName = [self.dataStore stringForKey:UAPushTimeZoneSettingsKey];
    return [NSTimeZone timeZoneWithName:timeZoneName] ?: [self defaultTimeZoneForQuietTime];
}

- (void)setTimeZone:(NSTimeZone *)timeZone {
    [self.dataStore setObject:[timeZone name] forKey:UAPushTimeZoneSettingsKey];
}

- (NSTimeZone *)defaultTimeZoneForQuietTime {
    return [NSTimeZone localTimeZone];
}

- (void)setNotificationOptions:(UANotificationOptions)notificationOptions {
    if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}] && !notificationOptions) {
        UA_LWARN(@"Registering for UANotificationOptionNone may disable the ability to register for other types without restarting the device first on iOS 8 & 9.");
    }

    _notificationOptions = notificationOptions;
    self.shouldUpdateAPNSRegistration = YES;
}

- (void)setRequireSettingsAppToDisableUserNotifications:(BOOL)requireSettingsAppToDisableUserNotifications {
    if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}] && !requireSettingsAppToDisableUserNotifications) {
        UA_LWARN(@"Allowing the application to disable notifications in iOS 8 & 9 will prevent your application from properly "
                 "opt-ing out of notifications that include \"content-available\" background components in "
                 "notifications that also include a user-visible component. Instead, direct users to the iOS "
                 "settings app using the UIApplicationOpenSettingsURLString URL constant.");
    }
    _requireSettingsAppToDisableUserNotifications = requireSettingsAppToDisableUserNotifications;
}

- (BOOL)requireSettingsAppToDisableUserNotifications {
    return _requireSettingsAppToDisableUserNotifications;
}

#pragma mark -
#pragma mark Open APIs - Property Setters

-(void)setQuietTimeStartHour:(NSUInteger)startHour startMinute:(NSUInteger)startMinute
                     endHour:(NSUInteger)endHour endMinute:(NSUInteger)endMinute {

    if (startHour >= 24 || startMinute >= 60) {
        UA_LWARN(@"Unable to set quiet time, invalid start time: %ld:%02ld", (unsigned long)startHour, (unsigned long)startMinute);
        return;
    }

    if (endHour >= 24 || endMinute >= 60) {
        UA_LWARN(@"Unable to set quiet time, invalid end time: %ld:%02ld", (unsigned long)endHour, (unsigned long)endMinute);
        return;
    }

    NSString *startTimeStr = [NSString stringWithFormat:@"%ld:%02ld",(unsigned long)startHour, (unsigned long)startMinute];
    NSString *endTimeStr = [NSString stringWithFormat:@"%ld:%02ld",(unsigned long)endHour, (unsigned long)endMinute];

    UA_LDEBUG("Setting quiet time: %@ to %@", startTimeStr, endTimeStr);

    self.quietTime = @{UAPushQuietTimeStartKey : startTimeStr,
                       UAPushQuietTimeEndKey : endTimeStr };
}


#pragma mark -
#pragma mark Open APIs - UA Registration Tags APIs

- (void)addTag:(NSString *)tag {
    [self addTags:[NSArray arrayWithObject:tag]];
}

- (void)addTags:(NSArray *)tags {
    NSMutableSet *updatedTags = [NSMutableSet setWithArray:self.tags];
    [updatedTags addObjectsFromArray:tags];
    [self setTags:[updatedTags allObjects]];
}

- (void)removeTag:(NSString *)tag {
    [self removeTags:[NSArray arrayWithObject:tag]];
}

- (void)removeTags:(NSArray *)tags {
    NSMutableArray *mutableTags = [NSMutableArray arrayWithArray:self.tags];
    [mutableTags removeObjectsInArray:tags];
    [self.dataStore setObject:mutableTags forKey:UAPushTagsSettingsKey];
}

#pragma mark -
#pragma mark Open APIs - UA Tag Groups APIs

- (void)addTags:(NSArray *)tags group:(NSString *)tagGroupID {
    if (self.channelTagRegistrationEnabled && [UAPushDefaultDeviceTagGroup isEqualToString:tagGroupID]) {
        UA_LERR(@"Unable to add tags %@ to device tag group when channelTagRegistrationEnabled is true.", [tags description]);
        return;
    }

    NSArray *normalizedTags = [UATagUtils normalizeTags:tags];
    NSString *normalizedTagGroupID = [UATagUtils normalizeTagGroupID:tagGroupID];
    if (!normalizedTags.count || !normalizedTagGroupID.length) {
        return;
    }

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToAddTags:normalizedTags
                                                                     group:normalizedTagGroupID];

    [self.dataStore addTagGroupsMutation:mutation atBeginning:NO forKey:UAPushTagGroupsMutationsKey];
}

- (void)removeTags:(NSArray *)tags group:(NSString *)tagGroupID {
    if (self.channelTagRegistrationEnabled && [UAPushDefaultDeviceTagGroup isEqualToString:tagGroupID]) {
        UA_LERR(@"Unable to remove tags %@ from device tag group when channelTagRegistrationEnabled is true.", [tags description]);
        return;
    }

    NSArray *normalizedTags = [UATagUtils normalizeTags:tags];
    NSString *normalizedTagGroupID = [UATagUtils normalizeTagGroupID:tagGroupID];

    if (!normalizedTags.count || !normalizedTagGroupID.length) {
        return;
    }

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToRemoveTags:normalizedTags
                                                                        group:normalizedTagGroupID];

    [self.dataStore addTagGroupsMutation:mutation atBeginning:NO forKey:UAPushTagGroupsMutationsKey];
}

- (void)setTags:(NSArray *)tags group:(NSString *)tagGroupID {
    if (self.channelTagRegistrationEnabled && [UAPushDefaultDeviceTagGroup isEqualToString:tagGroupID]) {
        UA_LERR(@"Unable to set tags %@ for device tag group when channelTagRegistrationEnabled is true.", [tags description]);
        return;
    }

    NSArray *normalizedTags = [UATagUtils normalizeTags:tags];
    NSString *normalizedTagGroupID = [UATagUtils normalizeTagGroupID:tagGroupID];

    if (!normalizedTagGroupID.length) {
        return;
    }

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToSetTags:normalizedTags
                                                                     group:normalizedTagGroupID];

    [self.dataStore addTagGroupsMutation:mutation atBeginning:NO forKey:UAPushTagGroupsMutationsKey];
}

- (void)setBadgeNumber:(NSInteger)badgeNumber {

    if ([[UIApplication sharedApplication] applicationIconBadgeNumber] == badgeNumber) {
        return;
    }

    UA_LDEBUG(@"Change Badge from %ld to %ld", (long)[[UIApplication sharedApplication] applicationIconBadgeNumber], (long)badgeNumber);

    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeNumber];

    // if the device token has already been set then
    // we are post-registration and will need to make
    // an update call
    if (self.autobadgeEnabled && (self.deviceToken || self.channelID)) {
        UA_LDEBUG(@"Sending autobadge update to UA server.");
        [self updateChannelRegistrationForcefully:YES];
    }
}

- (void)resetBadge {
    [self setBadgeNumber:0];
}


#pragma mark -
#pragma mark UIApplication State Observation

- (void)enterForeground {
    [self updateAuthorizedNotificationTypes];

    if ([self.dataStore boolForKey:UAPushChannelCreationOnForeground]) {
        UA_LTRACE(@"Application did become active. Updating registration.");
        [self updateChannelRegistrationForcefully:NO];
    }
}

- (void)applicationDidBecomeActive {
    [self enterForeground];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)applicationDidEnterBackground {
    self.launchNotificationResponse = nil;

    // Set the UAPushChannelCreationOnForeground after first run
    [self.dataStore setBool:YES forKey:UAPushChannelCreationOnForeground];

    // Create a channel if we do not have a channel ID
    if (!self.channelID) {
        [self updateChannelRegistrationForcefully:NO];
    }

    [self updateAuthorizedNotificationTypes];
}

#if !TARGET_OS_TV    // UIBackgroundRefreshStatusAvailable not available on tvOS
- (void)applicationBackgroundRefreshStatusChanged {
    UA_LTRACE(@"Background refresh status changed.");

    if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable) {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [self updateRegistration];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if ([self.pushRegistration respondsToSelector:@selector(application:didRegisterUserNotificationSettings:)]) {
        [self.pushRegistration application:application didRegisterUserNotificationSettings:notificationSettings];
    }
}
#endif

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.deviceToken = [UAUtils deviceTokenStringFromDeviceToken:deviceToken];
    
    if (application.applicationState == UIApplicationStateBackground && self.channelID) {
        UA_LDEBUG(@"Skipping channel registration. The app is currently backgrounded and we already have a channel ID.");
    } else {
        [self updateChannelRegistrationForcefully:NO];
    }

    id strongDelegate = self.registrationDelegate;
    if ([strongDelegate respondsToSelector:@selector(apnsRegistrationSucceededWithDeviceToken:)]) {
        [strongDelegate apnsRegistrationSucceededWithDeviceToken:deviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    id strongDelegate = self.registrationDelegate;
    if ([strongDelegate respondsToSelector:@selector(apnsRegistrationFailedWithError:)]) {
        [strongDelegate apnsRegistrationFailedWithError:error];
    }
}

#pragma mark -
#pragma mark UA Registration Methods

- (UAChannelRegistrationPayload *)createChannelPayload {
    UAChannelRegistrationPayload *payload = [[UAChannelRegistrationPayload alloc] init];
    payload.deviceID = [UAUtils deviceID];
#if !TARGET_OS_TV   // Inbox not supported on tvOS
    payload.userID = [UAirship inboxUser].username;
#endif

    if (self.pushTokenRegistrationEnabled) {
        payload.pushAddress = self.deviceToken;
    }

    payload.optedIn = [self userPushNotificationsAllowed];
    payload.backgroundEnabled = [self backgroundPushNotificationsAllowed];

    payload.setTags = self.channelTagRegistrationEnabled;
    payload.tags = self.channelTagRegistrationEnabled ? [self.tags copy]: nil;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    payload.alias = self.alias;
#pragma GCC diagnostic pop

    if (self.autobadgeEnabled) {
        payload.badge = [NSNumber numberWithInteger:[[UIApplication sharedApplication] applicationIconBadgeNumber]];
    } else {
        payload.badge = nil;
    }

    if (self.timeZone.name && self.quietTimeEnabled) {
        payload.timeZone = self.timeZone.name;
        payload.quietTime = [self.quietTime copy];
    }

    if ([UAirship shared].analytics.isEnabled) {
        NSString *localeLanguage = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleLanguageCode];
        NSString *localeCountry = [[NSLocale autoupdatingCurrentLocale] objectForKey: NSLocaleCountryCode];

        // Set top level language
        if (localeLanguage) {
            payload.language = localeLanguage;
        }

        // Set top level country
        if (localeCountry) {
            payload.country = localeCountry;
        }

        // Set top level timezone only when language or country is available
        if (self.timeZone.name && (localeLanguage || localeCountry)) {
            payload.timeZone = self.timeZone.name;
        }

    }

    return payload;
}

- (BOOL)userPushNotificationsAllowed {

    BOOL isRegisteredForRemoteNotifications = [UIApplication sharedApplication].isRegisteredForRemoteNotifications;

    return self.deviceToken
    && self.userPushNotificationsEnabled
    && self.authorizedNotificationOptions
    && isRegisteredForRemoteNotifications
    && self.pushTokenRegistrationEnabled;
}

- (BOOL)backgroundPushNotificationsAllowed {
    if (!self.deviceToken
        || !self.backgroundPushNotificationsEnabled
        || ![UAirship shared].remoteNotificationBackgroundModeEnabled
        || !self.pushTokenRegistrationEnabled) {
        return NO;
    }

    BOOL backgroundPushAllowed = [UIApplication sharedApplication].isRegisteredForRemoteNotifications;

#if !TARGET_OS_TV    // UIBackgroundRefreshStatusAvailable not available on tvOS
    if ([UIApplication sharedApplication].backgroundRefreshStatus != UIBackgroundRefreshStatusAvailable) {
        backgroundPushAllowed = NO;
    }
#endif

    return backgroundPushAllowed;
}

- (void)updateRegistration {

    // Update channel tag groups
    [self updateChannelTagGroups];

    // APNS registration will cause a channel registration
    if (self.shouldUpdateAPNSRegistration) {
        UA_LDEBUG(@"APNS registration is out of date, updating.");
        [self updateAPNSRegistration];
    } else if (self.userPushNotificationsEnabled && !self.channelID) {
        UA_LDEBUG(@"Push is enabled but we have not yet generated a channel ID. "
                  "Urban Airship registration will automatically run when the device token is registered, "
                  "the next time the app is backgrounded, or the next time the app is foregrounded.");
    } else {
        [self updateChannelRegistrationForcefully:NO];
    }
}

- (void)updateChannelRegistrationForcefully:(BOOL)forcefully {
    if (![NSThread isMainThread]) {
        UA_WEAKIFY(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            UA_STRONGIFY(self);
            [self updateChannelRegistrationForcefully:forcefully];
        });
        return;
    }

    // Only cancel in flight requests if the channel is already created
    if (!self.channelCreationEnabled) {
        UA_LDEBUG(@"Channel creation is currently disabled.");
        return;
    }

    if (![self beginRegistrationBackgroundTask]) {
        UA_LDEBUG(@"Unable to perform registration, background task not granted.");
        return;
    }


    [self.channelRegistrar registerWithChannelID:self.channelID
                                 channelLocation:self.channelLocation
                                     withPayload:[self createChannelPayload]
                                      forcefully:forcefully];
}

- (void)updateChannelTagGroups {
    if (![NSThread isMainThread]) {
        UA_WEAKIFY(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            UA_STRONGIFY(self);
            [self updateChannelTagGroups];
        });
        return;
    }

    if (!self.channelID) {
        return;
    }

    UATagGroupsMutation *mutation = [self.dataStore pollTagGroupsMutationForKey:UAPushTagGroupsMutationsKey];

    if (!mutation) {
        return;
    }

    UA_WEAKIFY(self);

    __block UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        UA_STRONGIFY(self);

        UA_LTRACE(@"Tag groups background task expired.");
        [self.tagGroupsAPIClient cancelAllRequests];
        [self.dataStore addTagGroupsMutation:mutation atBeginning:YES forKey:UAPushTagGroupsMutationsKey];

        if (backgroundTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
            backgroundTask = UIBackgroundTaskInvalid;
        }
    }];

    if (backgroundTask == UIBackgroundTaskInvalid) {
        UA_LTRACE("Background task unavailable, skipping tag groups update.");
        [self.dataStore addTagGroupsMutation:mutation atBeginning:YES forKey:UAPushTagGroupsMutationsKey];
        return;
    }

    [self.tagGroupsAPIClient updateChannel:self.channelID
                         tagGroupsMutation:mutation
                         completionHandler:^(NSUInteger status) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 UA_STRONGIFY(self);

                                 if (status >= 200 && status <= 299) {
                                     [self updateChannelTagGroups];
                                 } else if (status != 400 && status != 403) {
                                     [self.dataStore addTagGroupsMutation:mutation atBeginning:YES forKey:UAPushTagGroupsMutationsKey];
                                 }

                                 [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
                                 backgroundTask = UIBackgroundTaskInvalid;
                             });
                         }];
}

- (void)updateAPNSRegistration {
    self.shouldUpdateAPNSRegistration = NO;

    UANotificationOptions options = UANotificationOptionNone;
    NSSet *categories = nil;

    if (self.userPushNotificationsEnabled) {
        options = self.notificationOptions;
        categories = self.combinedCategories;
    }

    if (options == UANotificationOptionNone && !self.allowUnregisteringUserNotificationTypes) {
        UA_LDEBUG(@"Skipping unregistered for user notification types.");
        [self updateChannelRegistrationForcefully:NO];
        return;
    }

    [self.pushRegistration getCurrentAuthorizationOptionsWithCompletionHandler:^(UANotificationOptions authorizedOptions) {
        if (authorizedOptions == UANotificationOptionNone && options == UANotificationOptionNone) {
            // Skip updating registration to avoid prompting the user
            return;
        }

        [self.pushRegistration updateRegistrationWithOptions:options categories:categories];
    }];
}

- (void)notificationRegistrationFinishedWithOptions:(UANotificationOptions)options {
    if (!self.deviceToken) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        });
    };

    self.userPromptedForNotifications = YES;
    self.authorizedNotificationOptions = options;

    id strongDelegate = self.registrationDelegate;
    if ([strongDelegate respondsToSelector:@selector(notificationRegistrationFinishedWithOptions:categories:)]) {
        [strongDelegate notificationRegistrationFinishedWithOptions:options categories:self.combinedCategories];
    }
}


- (void)registrationSucceededWithPayload:(UAChannelRegistrationPayload *)payload {
    UA_LINFO(@"Channel registration updated successfully.");

    NSString *channelID = self.channelID;

    if (!channelID) {
        UA_LWARN(@"Channel ID is nil after successful registration.");
        return;
    }

    id strongDelegate = self.registrationDelegate;
    if ([strongDelegate respondsToSelector:@selector(registrationSucceededForChannelID:deviceToken:)]) {
        [strongDelegate registrationSucceededForChannelID:self.channelID deviceToken:self.deviceToken];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:UAChannelUpdatedEvent
                                                        object:self
                                                      userInfo:@{UAChannelUpdatedEventChannelKey: channelID}];

    if (![payload isEqualToPayload:[self createChannelPayload]]) {
        [self updateChannelRegistrationForcefully:NO];
    } else {
        [self endRegistrationBackgroundTask];
    }


}

- (void)registrationFailedWithPayload:(UAChannelRegistrationPayload *)payload {
    UA_LINFO(@"Channel registration failed.");

    id strongDelegate = self.registrationDelegate;
    if ([strongDelegate respondsToSelector:@selector(registrationFailed)]) {
        [strongDelegate registrationFailed];
    }

    [self endRegistrationBackgroundTask];
}

- (void)channelCreated:(NSString *)channelID
       channelLocation:(NSString *)channelLocation
              existing:(BOOL)existing {

    if (channelID && channelLocation) {
        // WARNING: Order matters here. Some things observe channelID being changed,
        // and if we do not have a channel location set, the channelID will return nil.
        self.channelLocation = channelLocation;
        self.channelID = channelID;

        if (uaLogLevel >= UALogLevelError) {
            NSLog(@"Created channel with ID: %@", self.channelID);
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:UAChannelCreatedEvent
                                                            object:self
                                                          userInfo:@{UAChannelCreatedEventChannelKey: channelID,
                                                                     UAChannelCreatedEventExistingKey: @(existing)}];
    } else {
        UA_LERR(@"Channel creation failed. Missing channelID: %@ or channelLocation: %@",
                channelID, channelLocation);
    }
}

#pragma mark -
#pragma mark Push handling

- (UNNotificationPresentationOptions)presentationOptionsForNotification:(UNNotification *)notification {
    UNNotificationPresentationOptions options = UNNotificationPresentationOptionNone;

    id pushDelegate = self.pushNotificationDelegate;
    if ([pushDelegate respondsToSelector:@selector(presentationOptionsForNotification:)]) {
        options = [pushDelegate presentationOptionsForNotification:notification];
    } else {
        options = self.defaultPresentationOptions;
    }

    return options;
}

- (void)handleNotificationResponse:(UANotificationResponse *)response completionHandler:(void (^)(void))handler {
    if ([response.actionIdentifier isEqualToString:UANotificationDefaultActionIdentifier]) {
        self.launchNotificationResponse = response;
    }

    id delegate = self.pushNotificationDelegate;
    if ([delegate respondsToSelector:@selector(receivedNotificationResponse:completionHandler:)]) {
        [delegate receivedNotificationResponse:response completionHandler:handler];
    } else {
        handler();
    }
}

- (void)handleRemoteNotification:(UANotificationContent *)notification foreground:(BOOL)foreground completionHandler:(void (^)(UIBackgroundFetchResult))handler {
    BOOL delegateCalled = NO;
    id delegate = self.pushNotificationDelegate;

    if (foreground) {

        if (self.autobadgeEnabled) {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:notification.badge.integerValue];
        }

        if ([delegate respondsToSelector:@selector(receivedForegroundNotification:completionHandler:)]) {
            delegateCalled = YES;
            [delegate receivedForegroundNotification:notification completionHandler:^{
                handler(UIBackgroundFetchResultNoData);
            }];
        }
    } else {
        if ([delegate respondsToSelector:@selector(receivedBackgroundNotification:completionHandler:)]) {
            delegateCalled = YES;
            [delegate receivedBackgroundNotification:notification completionHandler:^(UIBackgroundFetchResult fetchResult) {
                handler(fetchResult);
            }];
        }
    }

    if (!delegateCalled) {
        handler(UIBackgroundFetchResultNoData);
    }
}

#pragma mark -
#pragma mark Default Values

- (void)setBackgroundPushNotificationsEnabledByDefault:(BOOL)enabled {
    _backgroundPushNotificationsEnabledByDefault = enabled;
}

- (void)setUserPushNotificationsEnabledByDefault:(BOOL)enabled {
    _userPushNotificationsEnabledByDefault = enabled;
}

- (BOOL)beginRegistrationBackgroundTask {
    if (self.registrationBackgroundTask == UIBackgroundTaskInvalid) {
        self.registrationBackgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self.channelRegistrar cancelAllRequests];
            [[UIApplication sharedApplication] endBackgroundTask:self.registrationBackgroundTask];
            self.registrationBackgroundTask = UIBackgroundTaskInvalid;
        }];
    }

    return (BOOL) self.registrationBackgroundTask != UIBackgroundTaskInvalid;
}

- (void)endRegistrationBackgroundTask {
    if (self.registrationBackgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.registrationBackgroundTask];
        self.registrationBackgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)migratePushSettings {
    [self.dataStore migrateUnprefixedKeys:@[UAUserPushNotificationsEnabledKey, UABackgroundPushNotificationsEnabledKey,
                                            UAPushAliasSettingsKey, UAPushTagsSettingsKey, UAPushBadgeSettingsKey,
                                            UAPushChannelIDKey, UAPushChannelLocationKey, UAPushDeviceTokenKey,
                                            UAPushQuietTimeSettingsKey, UAPushQuietTimeEnabledSettingsKey,
                                            UAPushChannelCreationOnForeground, UAPushEnabledSettingsMigratedKey,
                                            UAPushEnabledKey, UAPushTimeZoneSettingsKey]];

    if ([self.dataStore boolForKey:UAPushEnabledSettingsMigratedKey]) {
        // Already migrated
        return;
    }

    // Migrate userNotificationEnabled setting to YES if we are currently registered for notification types
    if (![self.dataStore objectForKey:UAUserPushNotificationsEnabledKey]) {

        // If the previous pushEnabled was set
        if ([self.dataStore objectForKey:UAPushEnabledKey]) {
            BOOL previousValue = [self.dataStore boolForKey:UAPushEnabledKey];
            UA_LDEBUG(@"Migrating userPushNotificationEnabled to %@ from previous pushEnabledValue.", previousValue ? @"YES" : @"NO");
            [self.dataStore setBool:previousValue forKey:UAUserPushNotificationsEnabledKey];
            [self.dataStore removeObjectForKey:UAPushEnabledKey];
        } else {
            // If >= iOS 10
            if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}]) {
                [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                    if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                        UA_LDEBUG(@"Migrating userPushNotificationEnabled to YES because application was authorized for notifications");
                        [self.dataStore setBool:YES forKey:UAUserPushNotificationsEnabledKey];
                    }
                }];
            } else { // iOS 8 & 9
#if !TARGET_OS_TV    // UIUserNotificationTypeNone, currentUserNotificationSettings not available on tvOS
                if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {

                    NSLog(@"%lu", (unsigned long)[[UIApplication sharedApplication] currentUserNotificationSettings].types);
                    UA_LDEBUG(@"Migrating userPushNotificationEnabled to YES because application was already registered for notification types");
                    [self.dataStore setBool:YES forKey:UAUserPushNotificationsEnabledKey];
                }
#endif
            }
        }
    }
    
    [self.dataStore setBool:YES forKey:UAPushEnabledSettingsMigratedKey];
    
    // Normalize tags for older SDK versions
    self.tags = [UATagUtils normalizeTags:self.tags];
}

@end
