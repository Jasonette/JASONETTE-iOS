//
//  JasonSwitchComponent.m
//  Jasonette
//
//  Created by Camilo Castro on 13-10-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonSwitchComponent.h"
#import "UILabelledSwitch.h"
#import "JasonOptionHelper.h"

@implementation JasonSwitchComponent

+ (UIView *) build: (UILabelledSwitch *) component
         withJSON: (NSDictionary *) json
       withOptions: (NSDictionary *) options
{
    if(!component) {
        component = [UILabelledSwitch new];
    }
        
    component.payload = [[NSMutableDictionary alloc] init];
    if (json) {
        if(json[@"name"]) component.payload[@"name"] = [json[@"name"] description];
        if(json[@"action"]) component.payload[@"action"] = json[@"action"];
        if(json[@"label"]) [component setLabel:json[@"label"]];
    }

    JasonOptionHelper * data = [[JasonOptionHelper alloc] initWithOptions:options];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SwitchUpdated" object:component];

    BOOL isOn = [data getBoolean:@"value"];

    [component setOn:isOn animated:NO];
  
    if(component.isOn && component.payload && component.payload[@"name"]) {
        [self updateForm:@{component.payload[@"name"]: @(component.isOn)}];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchUpdated:) name:@"SwitchUpdated" object:component];
  
    // Apply Common Style
    [self stylize:json component:component];

    return component;
}

+ (void) switchUpdated: (NSNotification *) notification {
    UILabelledSwitch *component = notification.object;

    if(component.payload && component.payload[@"name"]) {
        [self updateForm:@{component.payload[@"name"]: @(component.isOn)}];
    }

    if(component.payload[@"action"]) {
        [[Jason client] call:component.payload[@"action"]];
    }
}

@end
