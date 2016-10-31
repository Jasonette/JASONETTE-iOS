//
//  JasonActionProtocol.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol JasonActionProtocol <NSObject>
@optional
@property (nonatomic, strong) UIViewController<RussianDollView> *VC;
@property (nonatomic, strong) NSDictionary *options;
@end
