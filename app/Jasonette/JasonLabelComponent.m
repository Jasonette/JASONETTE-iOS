//
//  JasonLabelComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonLabelComponent.h"

@implementation JasonLabelComponent
+ (UIView *)build:(NSDictionary *)json withOptions:(NSDictionary *)options{
    TTTAttributedLabel  *component = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    if(json){
        component.numberOfLines = 0;
        if(json[@"text"] && ![json[@"text"] isEqual:[NSNull null]]){
            if([json[@"text"] length] > 0){
                component.text = json[@"text"];
            }
        }
    }
    
    // Apply Common Style
    [self stylize:json component:component];
    
    return component;
}
@end
