//
//  JasonPushService.m
//  Jasonette
//
//  Created by e on 8/25/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonPushService.h"
#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation JasonPushService
- (void) initialize: (NSDictionary *)launchOptions {
    
    
#ifdef PUSH
    
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(userInfo) {
        if(userInfo[@"href"]){
            [[Jason client] call: @{
                @"type": @"$href",
                @"options": userInfo[@"href"]
            }];
        } else if(userInfo[@"action"]) {
            [[Jason client] call:userInfo[@"action"]];
        }
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"onRemoteNotification:" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRemoteNotification:) name:@"onRemoteNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"onRemoteNotificationDeviceRegistered:" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRemoteNotificationDeviceRegistered:) name:@"onRemoteNotificationDeviceRegistered" object:nil];
#else
    NSLog(@"Push notification turned off by default. If you'd like to suport push, uncomment the #define statement in Constants.h and turn on the push notification feature from the capabilities tab.");
#endif
    
    
}

// The "PUSH" constant is defined in Constants.h
// By default PUSH is disabled. To turn it on, go to Constants.h and uncomment the #define statement, and then go to the capabilities tab and switch the push notification feature on.

// Common remote notification processor

- (void)process: (NSDictionary *) payload {
    NSDictionary *events = [[[Jason client] getVC] valueForKey:@"events"];
    if(events){
        if(events[@"$push.onmessage"]){
            [[Jason client] call:events[@"$push.onmessage"] with: @{@"$jason": payload}];
        }
    }
}




- (void)onRemoteNotification: (NSNotification *)notification{
    [self process:notification.userInfo];
}

- (void)onRemoteNotificationDeviceRegistered: (NSNotification *)notification{
    NSDictionary *payload = notification.userInfo;
    NSDictionary *events = [[[Jason client] getVC] valueForKey:@"events"];
    if(events){
        if(events[@"$push.onregister"]){
            [[Jason client] call:events[@"$push.onregister"] with: @{@"$jason": @{@"token": payload[@"token"]}}];
        }
    }
}


#pragma mark - UNUserNotificationCenter Delegate above iOS 10

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    [self process:notification.request.content.userInfo];
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


@end
