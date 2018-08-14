//
//  JasonLabelComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonLabelComponent.h"

@implementation JasonLabelComponent
+ (UIView *)build: (TTTAttributedLabel *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if(!component){
        component = (TTTAttributedLabel*)[[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    }
    if(json){
        component.numberOfLines = 0;
        if(json[@"text"] && ![json[@"text"] isEqual:[NSNull null]]){
            component.text = [json[@"text"] description];
        }
    }
    
    // Apply Common Style
    [self stylize:json component:component];
    
    return component;
}
@end
