/* Copyright 2017 Urban Airship and Contributors */

#import "UAWKWebViewNativeBridge.h"
#import "UAUser.h"
#import "UAWhitelist.h"
#import "UAInboxMessage.h"
#import "UAGlobal.h"
#import "UAUtils.h"
#import "UAirship+Internal.h"
#import "UAInbox.h"
#import "UAInboxMessage.h"
#import "UAInboxMessageList.h"
#import "UAJavaScriptDelegate.h"
#import "UAWebViewCallData.h"
#import "NSString+UAURLEncoding.h"
#import "UANamedUser.h"
#import "UAPush.h"
#import "UAConfig.h"
#import "UAWebView+Internal.h"
#import "UABaseNativeBridge+Internal.h"

@implementation UAWKWebViewNativeBridge

#pragma mark UANavigationDelegate

/**
 * Decide whether to allow or cancel a navigation.
 * 
 * If a uairship:// URL, process it ourselves
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationType navigationType = navigationAction.navigationType;
    NSURLRequest *request = navigationAction.request;
    
    // This will be nil if we are not loading a Rich Push message
    UAInboxMessage *message = [[UAirship inbox].messageList messageForBodyURL:request.mainDocumentURL];
    
    __block WKNavigationActionPolicy policyForThisURL = WKNavigationActionPolicyAllow;
    
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [strongDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:^(WKNavigationActionPolicy delegatePolicyForThisURL) {
            policyForThisURL = delegatePolicyForThisURL;
        }];
    }
    
    // Always handle uairship urls
    if ([self isWhiteListedAirshipRequest:request]) {
        if ((navigationType == WKNavigationTypeLinkActivated) || (navigationType == WKNavigationTypeOther)) {
            UAWebViewCallData *data = [UAWebViewCallData callDataForURL:request.URL
                                                               delegate:strongDelegate
                                                                message:message];
            [self performJSDelegateWithData:data webView:webView];
        }
        policyForThisURL = WKNavigationActionPolicyCancel;
    }
    
    // Override any special link actions
    if ((policyForThisURL == WKNavigationActionPolicyAllow) && (navigationType == WKNavigationTypeLinkActivated)) {
        policyForThisURL = ([self handleLinkClick:request.URL]) ? WKNavigationActionPolicyCancel : WKNavigationActionPolicyAllow;
    }
    
    decisionHandler(policyForThisURL);

}

/**
 * Decide whether to allow or cancel a navigation after its response is known.
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [strongDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

/**
 * Called when the navigation is complete.
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [strongDelegate webView:webView didFinishNavigation:navigation];
    }
    
    [self populateJavascriptEnvironmentIfWhitelisted:webView requestURL:webView.URL];

}

/**
 * Called when the web view’s web content process is terminated.
 */
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
        [strongDelegate webViewWebContentProcessDidTerminate:webView];
    }
}

/**
 * Called when the web view begins to receive web content.
 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [strongDelegate webView:webView didCommitNavigation:navigation];
    }
}

/**
 * Called when web content begins to load in a web view.
 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [strongDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

/**
 * Called when an error occurs during navigation.
 */
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [strongDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

/**
 * Called when an error occurs while the web view is loading content.
 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [strongDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

/**
 * Called when a web view receives a server redirect.
 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didReceiveServerRedirectForProvisionalNavigation:)]) {
        [strongDelegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

/**
 * Called when the web view needs to respond to an authentication challenge.
 */
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [strongDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)closeWindowAnimated:(BOOL)animated {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(closeWindowAnimated:)]) {
        [strongDelegate closeWindowAnimated:animated];
    }
}

@end
