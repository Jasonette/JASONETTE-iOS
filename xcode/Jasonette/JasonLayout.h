//
//  JasonLayout.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JasonComponentFactory.h"
#import "UIView+JasonComponentPayload.h"

@interface JasonLayout : NSObject
@property (class, nonatomic, strong) NSMutableDictionary *stylesheet;
+ (NSMutableDictionary *)applyStylesheet:(NSDictionary *)item;
+ (NSDictionary *)build: (NSDictionary *)item atIndexPath: (NSIndexPath *)indexPath withForm: (NSDictionary *)form;
+ (NSDictionary *)fill:(UIStackView *)layout with:(NSDictionary *)item atIndexPath: (NSIndexPath *)indexPath withForm: (NSDictionary *)form;
@end
