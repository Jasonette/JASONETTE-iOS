//
//  JasonAgentService.m
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonAgentService.h"
#import "JasonViewController.h"

@interface JasonAgentService(){
    NSDictionary *pending_injections;
}
@end

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
    
    // don't listent to dead agents
    if (message.webView.payload[@"lifecycle"] && [message.webView.payload[@"lifecycle"] isEqualToString:@"dead"]) {
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
    
    // Don't evaluate if about:blank
    if ([webView.URL.absoluteString isEqualToString:@"about:blank"]) {
        return;
    }

    // Inject agent.js into agent context
    NSString *identifier = webView.payload[@"identifier"];
    NSString *raw = [JasonHelper read_local_file:@"file://agent.js"];
    NSString *interface = [NSString stringWithFormat:@"$agent.interface = window.webkit.messageHandlers[\"%@\"];\n", identifier];
    NSString *summon = [raw stringByAppendingString:interface];
    webView.payload[@"state"] = @"rendered";
    [webView evaluateJavaScript:summon completionHandler:^(id _Nullable res, NSError * _Nullable error) {
        NSLog(@"Injected");
    }];
    
    // If there's a pending agent (because the method was called before the agent was initialized)
    // Try the request again.
    JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];
    WKWebView *agent = vc.agents[identifier];
    if(agent && agent.payload && agent.payload[@"pending"]) {
        [self request:agent.payload[@"pending"]];
        agent.payload[@"pending"] = nil;
    }
    if (pending_injections && pending_injections.count > 0) {
        [self inject: pending_injections];
        pending_injections = nil;
    }
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSDictionary *action = webView.payload[@"action"];
    if(navigationAction.sourceFrame) {
        if(action) {
            
            // Trigger processing
            if (action[@"trigger"]) {
                JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];
                id event = vc.events[action[@"trigger"]];
                NSDictionary *resolved;
                NSMutableDictionary *data_stub = [[[Jason client] variables] mutableCopy];
                
                // Prepare the url to return
                NSString *url;
                if([navigationAction.request.URL.absoluteString hasPrefix:@"file://"]) {
                    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
                    if ([navigationAction.request.URL.absoluteString containsString:resourcePath]) {
                        // it's an internal path. Convert it to regular file format
                        url = [navigationAction.request.URL.absoluteString stringByReplacingOccurrencesOfString:resourcePath withString:@""];
                        
                        // Turn 'file:///' into 'file://'
                        url = [url stringByReplacingOccurrencesOfString:@"file:///" withString:@"file://"];
                    } else {
                        // it's a regular file url, like: file://local.json
                        url = navigationAction.request.URL.absoluteString;
                    }
                } else {
                    url = navigationAction.request.URL.absoluteString;
                }
                data_stub[@"$jason"] = @{ @"url": url };
                
                if ([event isKindOfClass:[NSArray class]]) {
                    // if it's a trigger, must figure out whether it resolves to type: "$default"
                    resolved = [[Jason client] filloutTemplate: event withData: data_stub];
                } else {
                    resolved = event;
                }
                action = [[Jason client] filloutTemplate: resolved withData: data_stub];
            }
            
            if(action[@"type"] && [action[@"type"] isEqualToString:@"$default"]) {
                // just regular navigate like a browser
                decisionHandler(WKNavigationActionPolicyAllow);
            } else {
                if([navigationAction.sourceFrame isEqual:navigationAction.targetFrame]) {
                    // normal navigation
                    // Need to handle JASON action
                    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
                        decisionHandler(WKNavigationActionPolicyCancel);
                        NSMutableDictionary *event = [action mutableCopy];
                        NSString *identifier = webView.payload[@"identifier"];
                        if(action[@"trigger"] || action[@"type"]) {
                            event[@"$id"] = identifier;
                            [[Jason client] call: event];
                        }
                    } else {
                        decisionHandler(WKNavigationActionPolicyAllow);
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

- (void) refresh: (WKWebView *)agent withOptions: (NSDictionary *)options {
    NSString *text = options[@"text"];
    NSString *url = options[@"url"];
    NSDictionary *action = options[@"action"];
    
    BOOL isempty = NO;
    
    // 2. Fill in the container with HTML or JS
    // Only when the agent is empty.
    // If it's not empty, it means it's already been loaded. => Multiple render of the same agent shouldn't reload the entire page
    if([agent.payload[@"state"] isEqualToString:@"empty"]) {
        if(url) {
            // contains "url" attribute
            if([url containsString:@"file://"]) {
                // File URL
                NSString *path = [JasonHelper get_local_path:url];
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
    
}
- (void) refresh: (NSDictionary *) options {
    if (options[@"id"]) {
        JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];
        NSString *identifier = options[@"id"];
        // 1. Initialize
        if(vc.agents && vc.agents[identifier]) {
            // Already existing agent, juse reuse the old one
            WKWebView *agent = vc.agents[identifier];
            agent.payload[@"state"] = @"empty";
            NSMutableDictionary *new_options = [options mutableCopy];
            new_options[@"text"] = agent.payload[@"text"];
            new_options[@"url"] = agent.payload[@"url"];
            new_options[@"action"] = agent.payload[@"action"];
            [self refresh:agent withOptions:new_options];
            [[Jason client] success];
        } else {
            [[Jason client] error: @{@"message": @"An agent with the ID doesn't exist"}];
        }
    } else {
        [[Jason client] error: @{@"message": @"Please support an ID to refresh"}];
    }
}
- (void) clear: (NSString *) identifier forVC: (JasonViewController *) vc{
    if(vc.agents && vc.agents[identifier]) {
        WKWebView *agent = vc.agents[identifier];
        @try {
            [agent removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
        } @catch (id exception) {
            
        }
        agent.payload[@"lifecycle"] = @"dead";
        [agent loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    }
}
- (void) clear: (NSDictionary *)options {
    if (options[@"id"]) {
        JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];
        [self clear: options[@"id"] forVC: vc];
        [[Jason client] success];
    } else {
        [[Jason client] error: @{@"message": @"Please support an ID to clear"}];
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
        
        // Adding progressView
        [agent addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
        
        agent.hidden = YES;
        
        
    }
    
    // Setup Payload
    agent.payload = [@{@"identifier": identifier, @"state": @"empty"} mutableCopy];
    
    if(![agent isDescendantOfView: vc.view]) {
        // Inject in to the current view
        [vc.view addSubview:agent];
        [vc.view sendSubviewToBack:agent];
    }
    
    if (vc.url) {
        agent.payload[@"parent"] = vc.url;
    }
    
    agent.payload[@"lifecycle"] = @"alive";
    
    // Set action payload
    // This needs to be handled separately than other payloads since "action" is empty in the beginning.
    if(action) {
        agent.payload[@"action"] = action;
    }
    
    agent.payload[@"url"] = url;
    agent.payload[@"text"] = text;
    
    [self refresh:agent withOptions:options];
    
    vc.agents[identifier] = agent;
    
    return agent;
}

- (void) inject: (NSDictionary *) options {
    NSString *identifier = options[@"id"];
    JasonViewController *vc = (JasonViewController *)[[Jason client] getVC];
    WKWebView *agent = vc.agents[identifier];
    if (agent) {
        NSArray *items = options[@"items"];
        dispatch_group_t requireGroup = dispatch_group_create();
        NSMutableArray *codes = [[NSMutableArray alloc] init];
        NSMutableArray *errors = [[NSMutableArray alloc] init];
        if (items && items.count > 0) {
            for(int i=0; i<items.count; i++) {
                dispatch_group_enter(requireGroup);
                NSDictionary *item = items[i];
                NSString *inject_text = item[@"text"];
                NSString *inject_type = item[@"type"];
                NSString *inject_url = item[@"url"];
                [codes addObject:@""];
                if (inject_url) {
                    if ([inject_url hasPrefix:@"file://"]) {
                        NSString *code = [JasonHelper read_local_file:inject_url];
                        if (code) {
                            codes[i] = code;
                        } else {
                            [errors addObject: @"the file doesn't exist"];
                        }
                        dispatch_group_leave(requireGroup);
                    } else if([inject_url hasPrefix:@"http"]) {
                        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/javascript", @"text/plain", @"application/javascript", nil];
                        [manager GET:inject_url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                            // Nothing
                        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                            NSString *code = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                            codes[i] = code;
                            dispatch_group_leave(requireGroup);
                        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                            [errors addObject: @"Failed to fetch script"];
                            dispatch_group_leave(requireGroup);
                        }];
                    } else {
                        [errors addObject: @"the injection must load from a file:// or http[s]:// url"];
                        dispatch_group_leave(requireGroup);
                    }
                } else if (inject_text) {
                    codes[i] = inject_text;
                    dispatch_group_leave(requireGroup);
                } else {
                    [errors addObject: @"must specify either a url or text"];
                    dispatch_group_leave(requireGroup);
                }
            }
            dispatch_group_notify(requireGroup, dispatch_get_main_queue(), ^{
                if (errors.count > 0) {
                    [[Jason client] error: @{@"message": [errors componentsJoinedByString:@"; "]}];
                } else {
                    NSString *code_string = [codes componentsJoinedByString:@"\n"];
                    [self inject: code_string into: agent];
                }
            });
        }
    } else {
        pending_injections = options;
    }
}

- (void) inject: (NSString *) code into: (WKWebView*) agent{
    [agent evaluateJavaScript:code completionHandler:^(id _Nullable res, NSError * _Nullable error) {
        // Step 2. Execute the method with params
        [[Jason client] success];
    }];
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
            if (error) {
                NSLog(@"%@", error);
                agent.payload[@"pending"] = options;
                // The agent might not be ready. Put it in a queue.
            }
        }];
        // Agent doesn't exist, return with the error callback
    } else {
        [[Jason client] error];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    UIProgressView *progressView = (UIProgressView*)[object viewWithTag:42];
    if (progressView) {
        [progressView setAlpha:1.0f];
        [progressView setProgress:((WKWebView*)object).estimatedProgress animated:YES];
        NSLog(@"%f", progressView.progress);
        if(((WKWebView*)object).estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [progressView setProgress:0.0f animated:NO];
            }];
        }
        
    }
}
@end

