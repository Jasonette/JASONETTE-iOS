/* Copyright 2017 Urban Airship and Contributors */

#import "UALegacyAPNSRegistration+Internal.h"
#import "UANotificationCategory.h"

@implementation UALegacyAPNSRegistration

@synthesize registrationDelegate;

-(void)getCurrentAuthorizationOptionsWithCompletionHandler:(void (^)(UANotificationOptions))completionHandler {
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    completionHandler((UANotificationOptions)settings.types);
}

-(void)updateRegistrationWithOptions:(UANotificationOptions)options
                          categories:(NSSet<UANotificationCategory *> *)categories {

    NSMutableSet *normalizedCategories;

    if (categories) {
        normalizedCategories = [NSMutableSet set];
        // Normalize our abstract categories to iOS-appropriate type
        for (UANotificationCategory *category in categories) {
            [normalizedCategories addObject:[category asUIUserNotificationCategory]];
        }
    }

    // Only allow alert, badge, and sound
    NSUInteger filteredOptions = options & (UANotificationOptionAlert | UANotificationOptionBadge | UANotificationOptionSound);
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:filteredOptions
                                                                                                          categories:normalizedCategories]];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    UANotificationOptions options = (UANotificationOptions)notificationSettings.types;
    [self.registrationDelegate notificationRegistrationFinishedWithOptions:options];
}

@end
