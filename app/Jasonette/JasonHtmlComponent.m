//
//  JasonHtmlComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonHtmlComponent.h"

@implementation JasonHtmlComponent
+ (UIView *)build: (UIWebView *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if(!component){
        component = [[UIWebView alloc] initWithFrame:CGRectZero];
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;
        if(json[@"style"]){
            if(json[@"style"][@"width"]){
                width = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:json[@"style"][@"width"]];
            }
            if(json[@"style"][@"height"]){
                height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:json[@"style"][@"height"]];
            }
        }
        CGRect frame = CGRectMake(0,0, width, height);
        component = [[UIWebView alloc] initWithFrame:frame];
    }
    
    component.opaque = NO;
    component.backgroundColor = [UIColor clearColor];

    
    if(json[@"text"] && ![[NSNull null] isEqual:json[@"text"]]){
        NSString *html = json[@"text"];
        [((UIWebView*)component) loadHTMLString:html baseURL:nil];
        component.scrollView.scrollEnabled = NO;

        component.delegate = [self self];
        [self stylize:json component:component];
    }
    
    
    // user interaction enable/disable => disabled by default
    component.userInteractionEnabled = NO;
    if(json[@"action"]){
        NSString *type = json[@"action"][@"type"];
        if(type){
            if([type isEqualToString:@"$default"]){
                // enable input only when action type is $default
                component.userInteractionEnabled = YES;
            }
        }
    }
    
    return component;
}


@end
