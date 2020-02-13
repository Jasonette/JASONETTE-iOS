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
        if(json[@"line_limit"] && ![json[@"line_limit"] isEqual:[NSNull null]]){
            component.numberOfLines = [json[@"line_limit"] integerValue];
        }
        if(json[@"text"] && ![json[@"text"] isEqual:[NSNull null]]){
            component.text = [json[@"text"] description];
            
            if(json[@"label"] && ![json[@"label"] isEqual:[NSNull null]]) {
                component.accessibilityLabel = json[@"label"];
                component.accessibilityValue = component.text;
            }
                                                
            if([component.text length] == 0){
                [component setIsAccessibilityElement:NO];
                [component setAccessibilityTraits:UIAccessibilityTraitNone];
            } else {
                [component setIsAccessibilityElement:YES];
                [component setAccessibilityTraits:UIAccessibilityTraitStaticText];
            }
        }
        
        [component setContentCompressionResistancePriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisVertical];
        [component setContentHuggingPriority:UILayoutPriorityRequired -1 forAxis:UILayoutConstraintAxisVertical];
        [component setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [component setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    
    // Apply Common Style
    [self stylize:json component:component];
    
    return component;
}
@end
