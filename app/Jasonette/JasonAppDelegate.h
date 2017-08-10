//
//  JasonAppDelegate.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "JasonViewController.h"
#include "Constants.h"
#ifdef PUSH
#import <UserNotifications/UserNotifications.h>
#endif

#ifdef PUSH
@interface JasonAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UNUserNotificationCenterDelegate>
#else
@interface JasonAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
#endif
@property (strong, nonatomic) UIWindow *window;
@end
