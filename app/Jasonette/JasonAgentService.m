//
//  JasonAgentService.m
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonAgentService.h"
#import "JasonViewController.h"


@implementation JasonAgentService
- (void) initialize: (NSDictionary *)launchOptions {
}
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    // agent.js handler
    // triggered by calling "window.webkit.messageHanders[__].postMessage" from agents
    
    // Figure out which agent the message is coming from
    NSString *identifier = message.webView.payload[@"identifier"];
    JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];

    // If the source agent has a different parent than the current view, ignore.
    if (![message.webView.payload[@"parent"] isEqualToString:vc.url]) {
        return;
    }
    
    // Message classification: Only support safe actions
    // 1. trigger: Trigger Jasonette event
    // 2. request: Make a request to an agent
    // 3. response: The message contains a response back from an agent
    // 4. href: Make an href transition to another Jasonette view
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    // 1. Trigger Jasonette event
    if(message.body[@"trigger"]) {
        NSDictionary *m = message.body[@"trigger"];
        event[@"$source"] = @{ @"id": identifier };
        event[@"trigger"] = m[@"name"];
        if(m[@"data"]) {
            event[@"options"] = m[@"data"];
        }
        [[Jason client] call: event];
    // 2. Make an agent request
    } else if(message.body[@"request"]) {
        NSDictionary *m = message.body[@"request"];
        NSDictionary *rpc = m[@"data"];
        if(rpc) {
            event = [rpc mutableCopy];
            
            // Coming from an agent, so need to specify $source object
            // to keep track of the source agent so that a response
            // can be sent back to the $source later.
            event[@"$source"] = @{
                @"id": identifier,
                @"nonce": m[@"nonce"]
            };
            [self request:event];
        }
    // 3. It's a response message from an agent
    } else if(message.body[@"response"]) {
        NSDictionary *m = message.body[@"response"];
        NSDictionary *source = message.webView.payload[@"$source"];
        
        // $source exists => the original request was from an agent
        if (source) {
            NSString *identifier = source[@"id"];
            
            // $agent.callbacks is a JavaScript object used for keeping track of
            // all the pending callbacks an agent is waiting on.
            // Whenever there's a response that targets an agent,
            // 1. We look up the relevant callback by querying $agent.callbacks[NONCE]
            // 2. When the callback is found, it's executed with the data passed in
            
            [self request: @{
                @"method": [NSString stringWithFormat: @"$agent.callbacks[\"%@\"]", source[@"nonce"]],
                @"id": identifier,
                @"params": @[m[@"data"]]
            }];
            
        // $source doesn't exist => the original request was from Jasonette action
        } else {
            // Run the caller Jasonette action's "success" callback
            [[Jason client] success: m[@"data"]];
        }
        
    // 4. Tell Jasonette to make an href transition to another view
    } else if(message.body[@"href"]) {
        [[Jason client] go: message.body[@"href"][@"data"]];
    }
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    // Inject agent.js into agent context
    NSString *identifier = webView.payload[@"identifier"];
    NSString *raw = [JasonHelper read_local_file:@"file://agent.js"];
    NSString *interface = [NSString stringWithFormat:@"$agent.interface = window.webkit.messageHandlers[\"%@\"];", identifier];
    NSString *summon = [raw stringByAppendingString:interface];

    [webView evaluateJavaScript:summon completionHandler:^(id _Nullable res, NSError * _Nullable error) {
        NSLog(@"Injected");
    }];

    // After loading, trigger $agent.[ID].ready event
    [[Jason client] call: @{
        @"trigger": @"$agent.ready",
        @"options": @{
            @"id": identifier,
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

- (void) refresh: (NSString *) identifier forVC: (JasonViewController *)vc{
    if(vc.agents && vc.agents[identifier]) {
        WKWebView *agent = vc.agents[identifier];
        [agent reload];
        [[Jason client] success];
    } else {
        [[Jason client] error: @{@"message": @"An agent with the ID doesn't exist"}];
    }
}
- (void) clear: (NSString *) identifier forVC: (JasonViewController *)vc{
    if(vc.agents && vc.agents[identifier]) {
        WKWebView *agent = vc.agents[identifier];
        [agent loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [[Jason client] success];
    } else {
        [[Jason client] error: @{@"message": @"An agent with the ID doesn't exist"}];
    }
}

- (WKWebView *) setup: (NSDictionary *)options withId: (NSString *)identifier{
    NSString *text = options[@"text"];
    NSString *url = options[@"url"];
    NSDictionary *action = options[@"action"];
    
    // Initialize
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    
    
    [controller addScriptMessageHandler:self name:identifier];
    config.userContentController = controller;
    [config setAllowsInlineMediaPlayback: YES];
    [config setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];

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
        

    }
    // Setup Payload
    agent.payload = [@{@"identifier": identifier, @"state": @"empty", @"parent": vc.url} mutableCopy];

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
    
    // Turn params into string so it can be turned into a JS callstring
    NSString *arguments = @"null";
    if(params) {
        arguments = [JasonHelper stringify:params];
    }
    
    // Construct JS Callstring
    NSString *callstring = [NSString stringWithFormat:@"%@.apply(this, %@);", method, arguments];

    // Agents are tied to a view. First get the current view.
    JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];

    // Find the agent by id
    WKWebView *agent = vc.agents[identifier];

    // Agent exists
    if (agent) {
        // If "$source" attribute exists, it means the request came from another agent
        // Therefore must set the nonce and $source id for later retrievability
        agent.payload[@"$source"] = options[@"$source"];
        
        // Evaluate JavaScript on the agent
        [agent evaluateJavaScript:callstring completionHandler:^(id _Nullable res, NSError * _Nullable error) {
            // Don't process return value.
            // Instead all communication back to Jasonette is taken care of by an explicit $agent.response() call
        }];
    // Agent doesn't exist, return with the error callback
    } else {
        [[Jason client] error];
    }
}

@end
