//
//  JasonAgentService.m
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonAgentService.h"

@implementation JasonAgentService
- (void) initialize: (NSDictionary *)launchOptions {
}
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *identifier = message.webView.payload[@"identifier"];
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];

    // 1. Only support "trigger"
    // 2. No "success" or "error" callbacks supported
    NSString *type = message.body[@"type"];
    if(type) {
        if([type isEqualToString:@"event"]) {
            event[@"$source"] = identifier;
            event[@"trigger"] = message.body[@"event"];
            if(message.body[@"options"]) {
                event[@"options"] = message.body[@"options"];
            }
            [[Jason client] call: event];
        } else if([type isEqualToString:@"request"]) {
            event[@"method"] = message.body[@"rpc"][@"method"];
            event[@"params"] = message.body[@"rpc"][@"params"];
            event[@"id"] = message.body[@"rpc"][@"id"];
            event[@"$source"] = identifier;
            event[@"$nonce"] = message.body[@"nonce"];
            [self request:event];
        } else if([type isEqualToString:@"return"]) {
            NSString *identifier = message.webView.payload[@"$source"][@"id"];
            [self request: @{
              @"method": [NSString stringWithFormat: @"$agent.callbacks[\"%@\"]", message.webView.payload[@"$source"][@"nonce"]],
              @"id": identifier,
              @"params": @[message.body[@"data"]]
            }];
        }

    }
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // After loading, trigger $agent.[ID].ready event

    NSString *url = webView.payload[@"content"];
    if(url) {
        NSString *urlArrayString = [JasonHelper stringify:@[url]];
        NSString *inject = [JasonHelper read_local_file:@"file://inject.js"];
        NSString *injectionScript = [NSString stringWithFormat: inject, urlArrayString];
        [webView evaluateJavaScript:injectionScript completionHandler:^(id _Nullable res, NSError * _Nullable error) {
            NSLog(@"Injected");
        }];
    }
    
    NSString *identifier = webView.payload[@"identifier"];
    NSString *raw = [JasonHelper read_local_file:@"file://agent.js"];
    NSString *summon = [NSString stringWithFormat: raw, identifier, identifier, identifier];
    [webView evaluateJavaScript:summon completionHandler:^(id _Nullable res, NSError * _Nullable error) {
        NSLog(@"Injected");
    }];

    [[Jason client] call: @{
        @"trigger": [NSString stringWithFormat: @"$agent.%@.ready", identifier],
        @"options": @{
            @"url": webView.URL
        }
    }];
    
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSDictionary *action = webView.payload[@"action"];
    if(navigationAction.sourceFrame) {
        if(action) {
            if(action[@"type"] && [action[@"type"] isEqualToString:@"$default"]) {
                // just regular navigate like a browser
                decisionHandler(WKNavigationActionPolicyAllow);
            } else {
                if([navigationAction.sourceFrame isEqual:navigationAction.targetFrame]) {
                    // normal navigation
                    // Need to handle JASON action
                    decisionHandler(WKNavigationActionPolicyCancel);
                    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
                    NSString *identifier = webView.payload[@"identifier"];
                    if(action[@"trigger"]) {
                        event[@"$id"] = identifier;
                        event[@"trigger"] = action[@"trigger"];
                        event[@"options"] = @{ @"url": navigationAction.request.URL.absoluteString };
                        [[Jason client] call: event];
                    }
                } else {
                    // different frame, maybe a parent frame requesting its child iframe request
                    decisionHandler(WKNavigationActionPolicyAllow);
                }
            }
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }

    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
/**********************************************
    "url": "file://app.html",
    "id": "view",
    "action": [{
        "{{#if /localhost/.test($jason)}}": {
            "type": "$href",
            "options": {
                "url": "{{$env.view.url}}",
                "options": {
                    "url": "{{$jason}}"
                }
            }
        }
    }]
**********************************************/

- (WKWebView *) setup: (NSDictionary *)options withId: (NSString *)identifier{
    NSString *text = options[@"text"];
    NSString *type = options[@"type"];
    NSString *url = options[@"url"];
    NSArray *components = options[@"components"];
    NSDictionary *action = options[@"action"];
    
    // Initialize
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    
    
    [controller addScriptMessageHandler:self name:identifier];
    config.userContentController = controller;
    
    WKWebView *agent;
    JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];

    // 1. Initialize
    if(vc.agents && vc.agents[identifier]) {
        // Already existing agent, juse reuse the old one
        agent = vc.agents[identifier];
    } else {
        // New Agent
        agent = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) configuration:config];
        agent.navigationDelegate = self;

        // Inject in to the current view
        [vc.view addSubview:agent];
        [vc.view sendSubviewToBack:agent];
        agent.hidden = YES;
        
        // Setup Payload
        agent.payload = [@{@"identifier": identifier, @"state": @"empty"} mutableCopy];

    }
    
    // Set action payload
    // This needs to be handled separately than other payloads since "action" is empty in the beginning.
    if(action) {
        agent.payload[@"action"] = action;
    }
    
    BOOL isempty = NO;
    
    
    // 2. Fill in the container with HTML or JS
    // Only when the agent is empty.
    // If it's not empty, it means it's already been loaded. => Multiple render of the same agent shouldn't reload the entire page
    if([agent.payload[@"state"] isEqualToString:@"empty"]) {
        if(url) {
            // contains "url" attribute
            if([url containsString:@"file://"]) {
                // File URL
                NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
                NSString *loc = @"file:/";
                NSString *path = [url stringByReplacingOccurrencesOfString:loc withString:resourcePath];
                NSURL *u = [NSURL fileURLWithPath:path isDirectory:NO];
                [agent loadFileURL:u allowingReadAccessToURL:u];
            } else {
                // Remote URL
                NSURL *nsurl=[NSURL URLWithString:url];
                NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
                [agent loadRequest:nsrequest];
            }
        } else if(text) {
            // contains "text" attribute
            [agent loadHTMLString:text baseURL:nil];
        } else {
            // neither "url" nor "text" => Just empty agent
            isempty = YES;
        }
    }
    if(isempty) {
        agent.payload[@"state"] = @"empty";
    } else {
        agent.payload[@"state"] = @"loaded";
    }
    if(action) {
        agent.userInteractionEnabled = YES;
    } else {
        agent.userInteractionEnabled = NO;
    }
    vc.agents[identifier] = agent;
    return agent;
}


- (void) request: (NSDictionary *) options {
    NSString *method = options[@"method"];
    NSString *identifier = options[@"id"];
    NSArray *params = options[@"params"];
    NSString *arguments = @"";
    if(params) {
        arguments = [JasonHelper stringify:params];
    }
    NSString *callstring = [NSString stringWithFormat:@"%@.apply(this, %@);", method, arguments];
    JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];

    // Find the container and execute
    WKWebView *agent = vc.agents[identifier];
    
    if(options[@"$source"]) {
        agent.payload[@"$source"] = @{
            @"id": options[@"$source"],
            @"nonce": options[@"$nonce"]
        };
    }
    [vc.agents[identifier] evaluateJavaScript:callstring completionHandler:^(id _Nullable res, NSError * _Nullable error) {
        NSLog(@"Called");
        if(res) {
            [[Jason client] success: res];
        }
    }];
}

@end
