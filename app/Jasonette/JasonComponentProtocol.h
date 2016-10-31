//
//  JasonComponentProtocol.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol JasonComponentProtocol <NSObject>

+ (UIView *)build: (NSDictionary *)json withOptions: (NSDictionary *)options;
+ (void)stylize: (NSDictionary *)json component: (UIView *)el;
+ (void)stylize: (NSDictionary *)json text: (UIView *)el;


@end
