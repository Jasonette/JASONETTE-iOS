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
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSURL *launchURL;
@end
