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
    if(json[@"text"] && ![[NSNull null] isEqual:json[@"text"]]){
        NSString *html = json[@"text"];
        [((UIWebView*)component) loadHTMLString:html baseURL:nil];
        ((UIWebView*)component).scrollView.scrollEnabled = NO;
        
        component.scrollView.scrollEnabled = NO;
        component.delegate = [self self];
        [self stylize:json component:component];
        //[component sizeToFit];
    }
    
    return component;
}
+ (void) webViewDidFinishLoad:(UIWebView *)webView
{
    /*
     NSString* js;
     if(webView.payload && webView.payload[@"css"]){
     js = [NSString stringWithFormat:@"var meta = document.createElement('meta'); " \
     "meta.setAttribute( 'name', 'viewport' ); " \
     "meta.setAttribute( 'content', 'width = device-width, initial-scale = 1' ); " \
     "document.getElementsByTagName('head')[0].appendChild(meta); " \
     "var style = document.createElement('style'); " \
     "style.innerHTML = \"%@\"; " \
     "document.body.appendChild(style); ", webView.payload[@"css"]];
     } else {
     js = [NSString stringWithFormat: @"var meta = document.createElement('meta'); " \
     "meta.setAttribute( 'name', 'viewport' ); " \
     "meta.setAttribute( 'content', 'width = %f, initial-scale = 1' ); " \
     "document.getElementsByTagName('head')[0].appendChild(meta); ", webView.frame.size.width];
     }
     */
    /*
     NSString * js = [NSString stringWithFormat: @"var meta = document.createElement('meta'); " \
     "meta.setAttribute( 'name', 'viewport' ); " \
     "meta.setAttribute( 'content', 'width = %f, initial-scale = 1' ); " \
     "document.getElementsByTagName('head')[0].appendChild(meta); ", webView.frame.size.width];
     [webView stringByEvaluatingJavaScriptFromString: js];
     [webView sizeToFit];
     */
    
    CGFloat height = [[webView stringByEvaluatingJavaScriptFromString:@"Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight);"] floatValue];
    webView.frame = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, webView.frame.size.height+height);
    //[webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    
    /*
     CGRect oldBounds = [webView bounds];
     CGFloat height = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"] floatValue];
     CGFloat width = webView.superview.frame.size.width;
     NSLog(@"NEW HEIGHT %f", height);
     NSLog(@"NEW width %f", width);
     [webView setBounds:CGRectMake(oldBounds.origin.x, oldBounds.origin.y, width, height)];
     //webView.superview.frame = CGRectMake(webView.superview.frame.origin.x, webView.superview.frame.origin.y, webView.superview.frame.size.width, webView.superview.frame.size.height + height);
     */
    
}


@end
