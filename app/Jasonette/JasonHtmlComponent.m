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
    if(json[@"style"] && json[@"style"][@"height"]){
        component.payload = [@{@"height": json[@"style"][@"height"]} mutableCopy];
    }
    
    if(json[@"text"] && ![[NSNull null] isEqual:json[@"text"]]){
        NSString *html = [json[@"text"] description];
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
+ (void) webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *summon = @"var JASON={call: function(e){var n=document.createElement(\"IFRAME\");n.setAttribute(\"src\",\"jason:\"+JSON.stringify(e)),document.documentElement.appendChild(n),n.parentNode.removeChild(n),n=null}};";
    [webView stringByEvaluatingJavaScriptFromString:summon];

    // If a height wasn't given then try to measure it
    if(!webView.payload || !webView.payload[@"height"]){
        // Find the parent table view and trigger an update so it calculates the new height on the cell
        id view = [webView superview];
        while (view && [view isKindOfClass:[UITableView class]] == NO) {
            view = [view superview];
        }
        UITableView *tableView = (UITableView *)view;
        [tableView beginUpdates];
        
        // Adjust the height according to the contents of the webview frame
        CGFloat height = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] floatValue];
        
        // Look for any height constraint
        NSLayoutConstraint *constraint_to_update = nil;
        for(NSLayoutConstraint *constraint in webView.constraints){
            if([constraint.identifier isEqualToString:@"height"]){
                constraint_to_update = constraint;
                break;
            }
        }
        
        // if the height constraint exists, we just update. Otherwise create and add.
        if(constraint_to_update){
            constraint_to_update.constant = height;
        } else {
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:webView
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:height];
            constraint.identifier = @"height";
            [webView addConstraint:constraint];
        }
        [webView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [webView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

        [tableView endUpdates]; // trigger parent table view to adjust to new constraint
    }
}
+ (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    if ([[[request URL] absoluteString] hasPrefix:@"jason:"]) {
        // Extract the selector name from the URL
        NSString *json = [[[request URL] absoluteString] substringFromIndex:6];
        json = [json stringByRemovingPercentEncoding];

        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *action = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [[Jason client] call: action];
        
        return NO;
    }
    
    // open links in the proper application
    if (navigationType == UIWebViewNavigationTypeLinkClicked ) {
        UIApplication *application = [UIApplication sharedApplication];
        [application openURL:[request URL] options:@{} completionHandler:nil];
        return NO;
    }
    
    return YES;
}

@end
