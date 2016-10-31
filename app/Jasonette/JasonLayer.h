//
//  JasonLayer.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIView+JasonComponentPayload.h"
#import "Jason.h"

@interface JasonLayer : NSObject
@property (class, nonatomic, strong) NSMutableArray *layers;
@property (class, nonatomic, strong) NSMutableDictionary *stylesheet;
+ (void)setupLayers: (NSDictionary *)body withView: (UIView *)rootView;
+ (NSMutableDictionary *)applyStylesheet:(NSDictionary *)item;
@end
