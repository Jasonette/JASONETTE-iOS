//
//  JasonAction.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RussianDollView.h"
#import "Jason.h"

@interface JasonAction : NSObject
@property (nonatomic, strong) UIViewController<RussianDollView> *VC;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) NSMutableDictionary *cache;
@end
