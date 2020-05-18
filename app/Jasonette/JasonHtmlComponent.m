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
    WKWebViewConfiguration * config = [[WKWebViewConfiguration alloc] init];
    if (!component) {
        [config setAllowsInlineMediaPlayback:YES];
        [config setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];

        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;

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

        component.navigationDelegate = [[Jason client] self].services[@"JasonAgentService"];
    }

    component.opaque = YES;
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

        [component loadHTMLString:html baseURL:nil];

        component.scrollView.scrollEnabled = NO;

        // Enforce no padding on the webview as the padded area should be represented in the actual html
        // and clicking on this "fake" padded area will cause error warnings for the user.
        NSMutableDictionary * newJson = [json mutableCopy];
        NSMutableDictionary * newStyle = [newJson[@"style"] mutableCopy];
        newStyle[@"padding"] = @"0";
        newJson[@"style"] = newStyle;
        [self stylize:newJson component:component];
    }

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

@end
