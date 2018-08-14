//
//  JasonActionProtocol.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "JasonViewController.h"

@protocol JasonActionProtocol <NSObject>
@optional
@property (nonatomic, strong) JasonViewController *VC;
@property (nonatomic, strong) NSDictionary *options;
@end
