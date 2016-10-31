//
//  JasonButtonComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonButtonComponent.h"

@implementation JasonButtonComponent
+ (UIView *)build:(NSDictionary *)json withOptions:(NSDictionary *)options{
    UIButton *component = [[UIButton alloc] init];
    [self stylize:json component:component];
    [component setTitle:json[@"text"] forState:UIControlStateNormal];
    if(json[@"action"]){
        component.payload = [@{@"action": json[@"action"]} mutableCopy];
    }
    [component removeTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [component addTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    // 1. Apply Common Style
    [self stylize:json component:component];
    
    // 2. Custom Style
    NSDictionary *style = json[@"style"];
    if(style){
        [self stylize:json text:component.titleLabel];
        
        if(style[@"color"]){
            NSString *colorHex = style[@"color"];
            component.tintColor = [JasonHelper colorwithHexString:colorHex alpha:1.0];
            UIColor *c = [JasonHelper colorwithHexString:colorHex alpha:1.0];
            [component setTitleColor:c forState:UIControlStateNormal];
        } else {
            component.tintColor = [UIColor whiteColor];
        }
    }
    [component setSelected:NO];
    
    return component;
}
+ (void)actionButtonClicked:(UIButton *)sender{
    if(sender.payload && sender.payload[@"action"]){
        [[Jason client] call: sender.payload[@"action"]];
    }
}

@end
