//
//  JasonAction.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JasonViewController.h"
#import "Jason.h"

@interface JasonAction : NSObject
@property (nonatomic, strong) JasonViewController *VC;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) NSMutableDictionary *cache;
@end
