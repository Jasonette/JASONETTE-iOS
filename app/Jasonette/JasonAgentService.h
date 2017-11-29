//
//  JasonAgentService.h
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Jason.h"
@class JasonViewController;

@import WebKit;

@interface JasonAgentService : NSObject <WKNavigationDelegate, WKScriptMessageHandler>
- (void) request:(NSDictionary *)options;
- (WKWebView *) setup:(NSDictionary *)options withId:(NSString *)identifier;
- (void) refresh: (NSString *) identifier forVC: (JasonViewController *)vc;
- (void) clear: (NSString *) identifier forVC: (JasonViewController *)vc;
@end
