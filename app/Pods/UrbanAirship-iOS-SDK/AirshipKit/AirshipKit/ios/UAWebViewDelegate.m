/* Copyright 2017 Urban Airship and Contributors */

#import "UAWebViewDelegate.h"
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
#import "UABaseNativeBridge+Internal.h"

@interface UAWebViewDelegate()
@property (nonatomic, strong) NSMapTable *injectedWebViews;
@end

@implementation UAWebViewDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        self.injectedWebViews = [NSMapTable weakToStrongObjectsMapTable];
    }

    return self;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    // This will be nil if we are not loading a Rich Push message
    UAInboxMessage *message = [[UAirship inbox].messageList messageForBodyURL:webView.request.mainDocumentURL];

    NSURL *url = request.URL;

    BOOL shouldLoad = YES;

    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        shouldLoad = [strongDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }

    // Always handle uairship urls
    // uairship://command/[<arguments>][?<dictionary>]
    if ([[url scheme] isEqualToString:@"uairship"]) {
        if ([[UAirship shared].whitelist isWhitelisted:webView.request.mainDocumentURL]) {
            if ((navigationType == UIWebViewNavigationTypeLinkClicked) || (navigationType == UIWebViewNavigationTypeOther)) {
                UAWebViewCallData *data = [UAWebViewCallData callDataForURL:url webView:webView message:message];
                [self performJSDelegateWithData:data webView:webView];
            }
        }

        shouldLoad = NO;
    }

    // Override any special link actions
    if (shouldLoad && navigationType == UIWebViewNavigationTypeLinkClicked) {
        shouldLoad = ![self handleLinkClick:url];
    }

    // Check if we are loading a new top-level URL - if so, indicate we haven't yet injected the JS Native Bridge.
    if (shouldLoad && [request.URL isEqual:[request mainDocumentURL]]) {
        [self.injectedWebViews setObject:@(NO) forKey:webView];
    }

    return shouldLoad;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [strongDelegate webViewDidFinishLoad:webView];
    }

    // if we haven't yet tried to inject the JS Native Bridge for this webView, do so now.
    if (![[self.injectedWebViews objectForKey:webView] boolValue]) {
        [self.injectedWebViews setObject:@(YES) forKey:webView];

        [self populateJavascriptEnvironmentIfWhitelisted:webView requestURL:webView.request.mainDocumentURL];
    }

}

- (void)closeWindowAnimated:(BOOL)animated {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(closeWindowAnimated:)]) {
        [strongDelegate closeWindowAnimated:animated];
    }
}

#pragma mark UARichContentWindow

- (void)closeWebView:(UIWebView *)webView animated:(BOOL)animated {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    id strongContentWindow = self.richContentWindow;
    if ([strongContentWindow respondsToSelector:@selector(closeWebView:animated:)]) {
        UA_LIMPERR(@"closeWebView:animated: will be deprecated in SDK version 9.0");
        [strongContentWindow closeWebView:webView animated:animated];
#pragma GCC diagnostic pop
    } else {
        [self closeWindowAnimated:animated];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [strongDelegate webViewDidStartLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    id strongDelegate = self.forwardDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [strongDelegate webView:webView didFailLoadWithError:error];
    }
}

@end
