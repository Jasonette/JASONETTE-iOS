//
//  UIWindow+AHKAdditions.h
//  AHKActionSheetExample
//
//  Created by Arkadiusz on 14-04-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//
// Original source: https://github.com/Sumi-Interactive/SIAlertView/blob/master/SIAlertView/UIWindow%2BSIUtils.h

#import <UIKit/UIKit.h>

@interface UIWindow (AHKAdditions)

- (UIViewController *)ahk_viewControllerForStatusBarStyle;
- (UIViewController *)ahk_viewControllerForStatusBarHidden;
- (UIImage *)ahk_snapshot;

@end
