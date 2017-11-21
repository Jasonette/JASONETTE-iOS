//
//  JasonAgentService.h
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Jason.h"
#import "JasonViewController.h"
@import WebKit;

@interface JasonAgentService : NSObject <WKNavigationDelegate, WKScriptMessageHandler>
- (void) request:(NSDictionary *)options;
- (WKWebView *) setup:(NSDictionary *)options withId:(NSString *)identifier;
@end
