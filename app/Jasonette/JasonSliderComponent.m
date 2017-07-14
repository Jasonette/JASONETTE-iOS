//
//  JasonSliderComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonSliderComponent.h"

@implementation JasonSliderComponent
+ (UIView *)build: (UISlider *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if(!component){
        CGRect frame = CGRectMake(0,0, [[UIScreen mainScreen] bounds].size.width-20, 20);
        component = [[UISlider alloc] initWithFrame:frame];
    }
    component.continuous = YES;
    component.value = 0.5;
    component.payload = [@{@"name": json[@"name"], @"action": json[@"action"]} mutableCopy];

    if(options && options[@"value"] && [options[@"value"] length] > 0){
        component.value = [options[@"value"] floatValue];
    }
    
    if(component.value){
        if(component.payload && component.payload[@"name"]){
            [self updateForm:@{component.payload[@"name"]: [NSString stringWithFormat:@"%f", component.value]}];
        }
    }

    [component removeTarget:self action:@selector(sliderStarted:) forControlEvents:UIControlEventTouchDown];
    [component removeTarget:self action:@selector(sliderUpdated:) forControlEvents:UIControlEventTouchUpInside];
    [component addTarget:self action:@selector(sliderStarted:) forControlEvents:UIControlEventTouchDown];
    [component addTarget:self action:@selector(sliderUpdated:) forControlEvents:UIControlEventTouchUpInside];
    
    // Apply Common Style
    [self stylize:json component:component];
    
    return component;
}
+ (void)sliderStarted: (UISlider *)slider{
    [Jason client].touching = YES;
}
+ (void)sliderUpdated: (UISlider *)slider{
    [Jason client].touching = NO;
    if(slider.payload && slider.payload[@"name"]){
      [self updateForm:@{slider.payload[@"name"]: [NSString stringWithFormat:@"%f", slider.value]}];
    }
    if(slider.payload[@"action"]){
        [[Jason client] call:slider.payload[@"action"]];
    }
}

@end
