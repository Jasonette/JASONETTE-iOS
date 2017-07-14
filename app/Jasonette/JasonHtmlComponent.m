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
    
    // allow autoplay
    component.mediaPlaybackRequiresUserAction = NO;
    
    // allow inline playback
    component.allowsInlineMediaPlayback = YES;
    
    // user interaction enable/disable => disabled by default
    component.userInteractionEnabled = NO;
    if(json[@"action"]){
        // if there's an 'action' attribute, delegate the event handling to this component
        component.userInteractionEnabled = YES;

        NSString *type = json[@"action"][@"type"];
        if(type && [type isEqualToString:@"$default"]){
            // don't add button so the event passes all the way to the web canvas
        } else {
            // add a button so the event gets processed without reaching the web canvas
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.frame = CGRectMake(0, 0, component.frame.size.width, component.frame.size.height);
            [component addSubview:b];
            
            b.payload = [@{@"action": json[@"action"]} mutableCopy];
            [b removeTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [b addTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];            
        }
        

    }
    
    return component;
}
+ (void)actionButtonClicked:(UIButton *)sender{
    NSLog(@"sender.payload = %@", sender.payload);
    if(sender.payload && sender.payload[@"action"]){
        [[Jason client] call: sender.payload[@"action"]];
    }
}


@end
