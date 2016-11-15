//
//  JasonAppDelegate.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "JasonViewController.h"
#import "GCDWebServer.h"

@interface JasonAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) GCDWebServer *webServer;

@end

