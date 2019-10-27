//
//  JasonHtmlComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonHtmlComponent.h"
#import "JasonLogger.h"


@implementation JasonHtmlComponent
+ (UIView *)build:(WKWebView *)component withJSON:(NSDictionary *)json withOptions:(NSDictionary *)options {
    
    if (!component) {
        
        WKWebViewConfiguration * config = [[WKWebViewConfiguration alloc] init];
        
        [config setAllowsInlineMediaPlayback:YES];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        if ([config respondsToSelector:@selector(setMediaPlaybackRequiresUserAction:)]) {
            [config setMediaPlaybackRequiresUserAction:NO];
        }
        
#pragma clang diagnostic pop
        
        if (@available(iOS 10, *)) {
            [config setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];
        }
        
        
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;

        if (json[@"style"]) {
            if (json[@"style"][@"width"]) {
                width = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:json[@"style"][@"width"]];
            }

            if (json[@"style"][@"height"]) {
                height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:json[@"style"][@"height"]];
            }
        }
        
       
        // TODO: Figure it out what this does
        NSString * summon = @"var JASON={call: function(e){var n=document.createElement(\"IFRAME\");n.setAttribute(\"src\",\"jason:\"+JSON.stringify(e)),document.documentElement.appendChild(n),n.parentNode.removeChild(n),n=null}};";
        
        WKUserScript * summonScript = [[WKUserScript alloc] initWithSource:summon injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        WKUserContentController * controller = [WKUserContentController new];
        [controller addUserScript:summonScript];

        config.userContentController = controller;
        
        CGRect frame = CGRectMake (0, 0, width, height);
        component = [[WKWebView alloc] initWithFrame:frame configuration:config];
        
        component.translatesAutoresizingMaskIntoConstraints = NO;
        component.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        component.navigationDelegate = [self self];
    }

    component.opaque = NO;
    component.backgroundColor = [UIColor clearColor];

    if (json[@"text"] && ![[NSNull null] isEqual:json[@"text"]]) {
        
        // Remember to add <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        // if you want to display properly
        NSString * html = [json[@"text"] description];
        NSString * lowerCaseHtml = [html lowercaseString];
        
        if(![lowerCaseHtml containsString:@"viewport"] && ![lowerCaseHtml
             containsString:@"initial-scale"])
        {
            DTLogWarning(@"html <meta name='viewport'> not found. Display could be not properly rendered in html component. Forcing initial-scale=1.0.");
            
            NSRange headRange = [[html lowercaseString] rangeOfString:@"<head>"];
            DTLogDebug(@"Range location %d length %d", headRange.location, headRange.length);

            if(headRange.location != NSNotFound) {
                
                NSString * head = [[html substringToIndex:headRange.location] stringByAppendingString:@"<meta name='viewport' content='width=device-width, initial-scale=1.0'>"];
                
                DTLogDebug(@"Head", head);
                
                NSString * body = [html substringFromIndex:(headRange.location + @"<head>".length)];
                
                DTLogDebug(@"Body", body);
                
                html = [NSString stringWithFormat:@"%@%@", head, body];
            }
            
        }
        
        DTLogDebug(@"Rendering HTML Component %@", html);
        
        [component loadHTMLString:html baseURL:nil];
        
        component.scrollView.scrollEnabled = NO;

        //component.delegate = [self self];
        [self stylize:json component:component];
    }

    // allow autoplay
    //component.mediaPlaybackRequiresUserAction = NO;

    // allow inline playback
    //component.allowsInlineMediaPlayback = YES;

    // user interaction enable/disable => disabled by default
    component.userInteractionEnabled = NO;
    

    if (json[@"action"]) {
        // if there's an 'action' attribute, delegate the event handling to this component
        component.userInteractionEnabled = YES;

        NSString * type = json[@"action"][@"type"];

        if (type && [type isEqualToString:@"$default"]) {
            // don't add button so the event passes all the way to the web canvas
        } else {
            // add a button so the event gets processed without reaching the web canvas
            UIButton * b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.frame = CGRectMake (0, 0, component.frame.size.width, component.frame.size.height);
            [component addSubview:b];

            b.payload = [@{ @"action": json[@"action"] } mutableCopy];
            [b removeTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [b addTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        }
    }

    return component;
}

+ (void)actionButtonClicked:(UIButton *)sender {
    DTLogDebug(@"sender.payload = %@", sender.payload);

    if (sender.payload && sender.payload[@"action"]) {
        [[Jason client] call:sender.payload[@"action"]];
    }
}

// TODO: Check if these two methods are used at all.

//+ (void)webViewDidFinishLoad:(WKWebView *)webView
//{
//    NSString * summon = @"var JASON={call: function(e){var n=document.createElement(\"IFRAME\");n.setAttribute(\"src\",\"jason:\"+JSON.stringify(e)),document.documentElement.appendChild(n),n.parentNode.removeChild(n),n=null}};";
//
//    //[webView stringByEvaluatingJavaScriptFromString:summon];
//    [webView evaluateJavaScript:summon completionHandler:^(id _Nullable result, NSError * _Nullable error) {
//        DTLogDebug(@"%@", result);
//        if(error){
//            DTLogWarning(@"%@", error);
//        }
//    }];
//}
//
//+ (BOOL)webView:(WKWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    if ([[[request URL] absoluteString] hasPrefix:@"jason:"]) {
//        // Extract the selector name from the URL
//        NSString * json = [[[request URL] absoluteString] substringFromIndex:6];
//        json = [json stringByRemovingPercentEncoding];
//
//        NSData * data = [json dataUsingEncoding:NSUTF8StringEncoding];
//        NSDictionary * action = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//        [[Jason client] call:action];
//
//        return NO;
//    }
//
//    return YES;
//}

@end
