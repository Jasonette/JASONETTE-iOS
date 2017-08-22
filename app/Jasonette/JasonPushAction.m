//
//  JasonPushAction.m
//  Jasonette
//
//  Created by e on 8/21/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonPushAction.h"

@implementation JasonPushAction

- (void) initialize: (NSDictionary *)launchOptions {
    
#ifdef PUSH
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"registerNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerNotification) name:@"registerNotification" object:nil];
    
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(notification){
        if(notification.userInfo) {
            if(notification.userInfo[@"href"]){
                [[Jason client] go:notification.userInfo[@"href"]];
            } else if(notification.userInfo[@"action"]) {
                [[Jason client] call:notification.userInfo[@"action"]];
            }
        }
    }

#else
    NSLog(@"Push notification turned off by default. If you'd like to suport push, uncomment the #define statement in Constants.h and turn on the push notification feature from the capabilities tab.");
#endif

}

- (void)register{
    // currently only remote notification
    
    /* Example Syntax related to remote notifications
     
     1. $push.register action => Registers this device to Apple for push notification
     2. Then Apple server returns a device token => this triggers "$push.onregister" event with $jason.device_token set as the newly assigned device token
     3. You can use this value to do whatever you want. In the following example we send it to our server. It will probably store the device_token under current user's database entry
     4. Also, when the user receives a push notification while the app is in the foreground, it triggers "$notification.remote" event. In this case the entire push payload will be stored inside $jason. you can utilize this value to run any other action. In this case we call a $util.banner.
     
     {
         "$jason": {
             "head": {
                 "title": "PUSH TEST",
                 "actions": {
                     "$load": {
                         "type": "$push.register"
                     },
                     "$push.onregister": {
                         "type": "$network.request",
                         "options": {
                             "url": "https://myserver.com/register_device.json",
                             "data": {
                                 "device_token": "{{$jason.device_token}}"
                             }
                         }
                     },
                     "$push.onmessage": {
                         "type": "$util.banner",
                         "options": {
                             "title": "Message",
                             "description": "{{JSON.stringify($jason)}}"
                         }
                     }
                 }
             }
         }
     }
     
     */
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:nil];
    
    [[Jason client] success];
}


// The "PUSH" constant is defined in Constants.h
// By default PUSH is disabled. To turn it on, go to Constants.h and uncomment the #define statement, and then go to the capabilities tab and switch the push notification feature on.

#ifdef PUSH

- (void)registerNotification {
    if(SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(@"10.0")) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
            if( !error ){
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
        }];
    }
    else {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

#pragma mark - Remote Notification Delegate below iOS 9

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSString *device_token = [[NSString alloc]initWithFormat:@"%@",[[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""]];
    NSLog(@"Device Token = %@",device_token);
    [[Jason client] onRemoteNotificationDeviceRegistered: device_token];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[Jason client] onRemoteNotification:userInfo];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Error = %@",error);
}

#pragma mark - UNUserNotificationCenter Delegate above iOS 10

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    
    [[Jason client] onRemoteNotification:notification.request.content.userInfo];
    
    completionHandler(UNNotificationPresentationOptionNone);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    
    if(response.notification.request.content.userInfo) {
        if(response.notification.request.content.userInfo[@"href"]){
            [[Jason client] go:response.notification.request.content.userInfo[@"href"]];
        } else if(response.notification.request.content.userInfo[@"action"]) {
            [[Jason client] call:response.notification.request.content.userInfo[@"action"]];
        }
    }
    
    completionHandler();
}
#endif

@end
