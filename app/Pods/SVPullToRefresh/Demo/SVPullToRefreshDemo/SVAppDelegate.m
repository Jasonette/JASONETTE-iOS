//
//  SVAppDelegate.m
//  SVPullToRefreshDemo
//
//  Created by Sam Vermette on 23.04.12.
//  Copyright (c) 2012 samvermette.com. All rights reserved.
//

#import "SVAppDelegate.h"

#import "SVViewController.h"

@implementation SVAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[SVViewController alloc] initWithNibName:@"SVViewController" bundle:nil];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
