/* Copyright 2017 Urban Airship and Contributors */

#import "UAAPNSRegistration+Internal.h"
#import "UANotificationCategory.h"

@implementation UAAPNSRegistration

@synthesize registrationDelegate;

-(void)getCurrentAuthorizationOptionsWithCompletionHandler:(void (^)(UANotificationOptions))completionHandler {
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {

        if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
            completionHandler(UANotificationOptionNone);
            return;
        }

        UANotificationOptions options = UANotificationOptionNone;

        if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {

#if !TARGET_OS_TV
            if (settings.alertSetting == UNNotificationSettingEnabled) {
                options |= UANotificationOptionAlert;
            }

            if (settings.soundSetting == UNNotificationSettingEnabled) {
                options |= UANotificationOptionSound;
            }

            if (settings.carPlaySetting == UNNotificationSettingEnabled) {
                options |= UANotificationOptionCarPlay;
            }
#endif
            if (settings.badgeSetting == UNNotificationSettingEnabled) {
                options |= UANotificationOptionBadge;
            }

            completionHandler(options);
        }}];
}

-(void)updateRegistrationWithOptions:(UANotificationOptions)options
                          categories:(NSSet<UANotificationCategory *> *)categories {

#if !TARGET_OS_TV   // UNNotificationCategory not supported on tvOS
    NSMutableSet *normalizedCategories;

    if (categories) {
        normalizedCategories = [NSMutableSet set];

        // Normalize our abstract categories to iOS-appropriate type
        for (UANotificationCategory *category in categories) {

            id normalizedCategory = [category asUNNotificationCategory];

            // iOS 10 beta this could return nil
            if (normalizedCategory) {
                [normalizedCategories addObject:normalizedCategory];
            }
        }
    }

    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithSet:normalizedCategories]];
#endif

    UNAuthorizationOptions normalizedOptions = (UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionCarPlay);
    normalizedOptions &= options;

    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:normalizedOptions
                                                                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                                                            [self getCurrentAuthorizationOptionsWithCompletionHandler:^(UANotificationOptions authorizedOptions) {
                                                                                [self.registrationDelegate notificationRegistrationFinishedWithOptions:authorizedOptions];
                                                                            }];
                                                                        }];
}

@end

