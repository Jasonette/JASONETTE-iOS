//
//  JasonAppDelegate.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "JasonViewController.h"
#include "Constants.h"

@interface JasonAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
@property (strong, nonatomic) UIWindow * window;

#pragma mark - Lifecycle
+ (BOOL)              application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

+ (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

// For iOS <= 9
+ (BOOL)  application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation;

+ (void)applicationDidBecomeActive:(UIApplication *)application;

#pragma mark - Notifications
// This method is for iOS <= 8
+ (void)                    application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;

+ (void)                                 application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

+ (void)             application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo;

+ (void)                                 application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

@end
