//
//  UIView+Extension.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
//  Enable attaching payloads to UIView subviews
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIView (JasonComponentPayload)

@property ( nonatomic, strong ) NSMutableDictionary* payload;

@end
