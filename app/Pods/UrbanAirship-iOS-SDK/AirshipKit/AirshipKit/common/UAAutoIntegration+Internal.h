/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface UAAutoIntegrationDummyDelegate : NSObject<UNUserNotificationCenterDelegate>

@end

@interface UAAutoIntegration : NSObject

///---------------------------------------------------------------------------------------
/// @name Auto Integration Internal Methods
///---------------------------------------------------------------------------------------

+ (void)integrate;

// Used to reset any state for testing only.
+ (void)reset;

@end
