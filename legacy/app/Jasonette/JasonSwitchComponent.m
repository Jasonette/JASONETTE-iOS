//
//  JasonSwitchComponent.m
//  Jasonette
//
//  Created by Camilo Castro on 13-10-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonSwitchComponent.h"
#import "JasonOptionHelper.h"

@implementation JasonSwitchComponent

+ (UIView *) build: (UISwitch *) component
         withJSON: (NSDictionary *) json
       withOptions: (NSDictionary *) options
{
  
  if(!component)
  {
    component = [UISwitch new];
  }
  
  component.payload = [[NSMutableDictionary alloc] init];
  if(json && json[@"name"]) component.payload[@"name"] = [json[@"name"] description];
  if(json && json[@"action"]) component.payload[@"action"] = json[@"action"];

  JasonOptionHelper * data = [[JasonOptionHelper alloc] initWithOptions:options];
  
  BOOL isOn = [data getBoolean:@"value"];

  [component setOn:isOn animated:YES];
  
  if(component.isOn)
  {
    if(component.payload && component.payload[@"name"])
    {
      [self updateForm:@{component.payload[@"name"]: @(component.isOn)}];
    }
  }
  
  [component removeTarget:self action:@selector(switchUpdated:) forControlEvents:UIControlEventValueChanged];
  [component addTarget:self action:@selector(switchUpdated:) forControlEvents:UIControlEventValueChanged];
  
  // Apply Common Style
  [self stylize:json component:component];
  
  // Custom Styles
  NSMutableDictionary * style;
  if(json[@"style"])
  {
    style = [json[@"style"] mutableCopy];
  }
  
  
  if(style[@"color"])
  {
    NSString * colorHex = style[@"color"];
    UIColor * color = [JasonHelper colorwithHexString:colorHex alpha:1.0];
    [component setOnTintColor:color];
  }
  
  if(style[@"color:disabled"])
  {
    NSString * colorHex = style[@"color:disabled"];
    UIColor * color = [JasonHelper colorwithHexString:colorHex alpha:1.0];
    [component setTintColor:color];
    [component setBackgroundColor:color];
    component.layer.cornerRadius = 16;
  }
  
  return component;
}


+ (void) switchUpdated: (UISwitch *) component
{
  
  if(component.payload && component.payload[@"name"])
  {
    [self updateForm:@{component.payload[@"name"]: @(component.isOn)}];
  }
  
  if(component.payload[@"action"])
  {
    [[Jason client] call:component.payload[@"action"]];
  }
}

@end
