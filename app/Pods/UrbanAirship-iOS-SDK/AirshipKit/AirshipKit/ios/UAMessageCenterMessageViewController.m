/* Copyright 2017 Urban Airship and Contributors */

#import "UAMessageCenterMessageViewController.h"
#import "UAWKWebViewNativeBridge.h"
#import "UAInbox.h"
#import "UAirship.h"
#import "UAInboxMessageList.h"
#import "UAInboxMessage.h"
#import "UAUtils.h"
#import "UAMessageCenterLocalization.h"
#import "UABeveledLoadingIndicator.h"

#define kMessageUp 0
#define kMessageDown 1

@interface UAMessageCenterMessageViewController () <UAWKWebViewDelegate, UAMessageCenterMessageViewProtocol>

@property (nonatomic, strong) UAWKWebViewNativeBridge *nativeBridge;

/**
 * The WebView used to display the message content.
 */
@property (nonatomic, strong) WKWebView *webView;

/**
 * The loading indicator.
 */
@property (weak, nonatomic) IBOutlet UABeveledLoadingIndicator *loadingIndicatorView;

/**
 * The view displayed when there are no messages.
 */
@property (nonatomic, weak) IBOutlet UIView *coverView;

/**
 * The label displayed in the coverView.
 */
@property (nonatomic, weak) IBOutlet UILabel *coverLabel;

/**
 * Boolean indicating whether or not the view is visible
 */
@property (nonatomic, assign) BOOL isVisible;

/**
 * The UAInboxMessage being displayed.
 */
@property (nonatomic, strong) UAInboxMessage *message;

/**
 * State of message waiting to load, loading, loaded or currently displayed.
 */
typedef enum MessageState {
    NONE,
    FETCHING,
    TO_LOAD,
    LOADING,
    LOADED
} MessageState;

@property (nonatomic, assign) MessageState messageState;

@end

@implementation UAMessageCenterMessageViewController

@synthesize message = _message;
@synthesize closeBlock = _closeBlock;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.messageState = NONE;
    }
    return self;
}

- (void)dealloc {
    self.message = nil;
    self.webView.navigationDelegate = nil;
    self.webView.UIDelegate = nil;
    [self.webView stopLoading];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.nativeBridge = [[UAWKWebViewNativeBridge alloc] init];
    self.nativeBridge.forwardDelegate = self;
    self.webView.navigationDelegate = self.nativeBridge;

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}]) {
        // Allow the webView to detect data types (e.g. phone numbers, addresses) at will
        [self.webView.configuration setDataDetectorTypes:WKDataDetectorTypeAll];
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:UAMessageCenterLocalizedString(@"ua_delete")
                                                                               style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(delete:)];

    // load message or cover view if no message waiting to load
    switch (self.messageState) {
        case NONE:
            [self coverWithMessageAndHideLoadingIndicator:UAMessageCenterLocalizedString(@"ua_message_not_selected")];
            break;
        case FETCHING:
            [self coverWithBlankViewAndShowLoadingIndicator];
            break;
        case TO_LOAD:
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [self loadMessage:self.message onlyIfChanged:NO];
#pragma GCC diagnostic pop
            break;
        default:
            UA_LWARN(@"WARNING: messageState = %u. Should be \"NONE\", \"FETCHING\", or \"TO_LOAD\"",self.messageState);
            break;
    }
    
    self.isVisible = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.messageState == NONE) {
        [self coverWithMessageAndHideLoadingIndicator:UAMessageCenterLocalizedString(@"ua_message_not_selected")];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    self.isVisible = YES;

    if (self.messageState == LOADED) {
        [self uncoverAndHideLoadingIndicator];
    }

    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.isVisible = NO;
}

#pragma mark -
#pragma mark UI

- (void)delete:(id)sender {
    if (self.messageState != LOADED) {
        UA_LWARN(@"WARNING: messageState = %u. Should be \"LOADED\"",self.messageState);
    }
    if (self.message) {
        self.messageState = NONE;
        [[UAirship inbox].messageList markMessagesDeleted:@[self.message] completionHandler:nil];
    }
}

- (void)coverWithMessageAndHideLoadingIndicator:(NSString *)message {
    self.title = nil;
    self.coverLabel.text = message;
    self.coverView.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self hideLoadingIndicator];
}

- (void)coverWithBlankViewAndShowLoadingIndicator {
    self.title = nil;
    self.coverLabel.text = nil;
    self.coverView.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self showLoadingIndicator];
}

- (void)uncoverAndHideLoadingIndicator {
    self.coverView.hidden = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self hideLoadingIndicator];
}

- (void)showLoadingIndicator {
    [self.loadingIndicatorView show];
}

- (void)hideLoadingIndicator {
    [self.loadingIndicatorView hide];
}

static NSString *urlForBlankPage = @"about:blank";

- (void)loadMessageForID:(NSString *)messageID {
    [self loadMessageForID:messageID onlyIfChanged:NO onError:nil];
}

- (void)loadMessageForID:(NSString *)messageID onlyIfChanged:(BOOL)onlyIfChanged onError:(void (^)(void))errorCompletion {
    // start by covering the view and showing the loading indicator
    [self coverWithBlankViewAndShowLoadingIndicator];
    
    // Refresh the list to see if the message is available in the cloud
    self.messageState = FETCHING;

    __weak id weakSelf = self;

    [[UAirship inbox].messageList retrieveMessageListWithSuccessBlock:^{
         dispatch_async(dispatch_get_main_queue(),^{
            __strong id strongSelf = weakSelf;
            
            UAInboxMessage *message = [[UAirship inbox].messageList messageForID:messageID];
            if (message) {
                // display the message
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                [strongSelf loadMessage:message onlyIfChanged:onlyIfChanged];
#pragma GCC diagnostic pop
            } else {
                // if the message no longer exists, clean up and show an error dialog
                [strongSelf hideLoadingIndicator];
                
                [strongSelf displayAlertOnOK:errorCompletion onRetry:^{
                    [weakSelf loadMessageForID:messageID onlyIfChanged:onlyIfChanged onError:errorCompletion];
                }];
            }
            return;
        });
    } withFailureBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            [weakSelf hideLoadingIndicator];
            if (errorCompletion) {
                errorCompletion();
            }
        });
        return;
    }];
}

- (void)loadMessage:(UAInboxMessage *)message onlyIfChanged:(BOOL)onlyIfChanged {
    if (!message) {
        if (self.messageState == LOADING) {
            [self.webView stopLoading];
        }
        self.messageState = NONE;
        self.message = message;
        [self coverWithMessageAndHideLoadingIndicator:UAMessageCenterLocalizedString(@"ua_message_not_selected")];
        return;
    }
    
    if (!onlyIfChanged || (self.messageState == NONE) || !(self.message && [message.messageID isEqualToString:self.message.messageID])) {
        self.message = message;
        
        if (!self.webView) {
            self.messageState = TO_LOAD;
        } else {
            if (self.messageState == LOADING) {
                [self.webView stopLoading];
            }
            self.messageState = LOADING;
            
            // start by covering the view and showing the loading indicator
            [self coverWithBlankViewAndShowLoadingIndicator];
            
            // now load a blank page, so when the view is uncovered, it isn't still showing the previous web page
            // note: when the blank page has finished loading, it will load the message
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlForBlankPage]]];
        }
    } else {
        if (self.isVisible && (self.messageState == LOADED)) {
            [self uncoverAndHideLoadingIndicator];
        }
    }
}

- (void)loadMessageIntoWebView {
    self.title = self.message.title;
    
    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:self.message.messageBodyURL];
    requestObj.timeoutInterval = 60;
    
    NSString *auth = [UAUtils userAuthHeaderString];
    [requestObj setValue:auth forHTTPHeaderField:@"Authorization"];
    
    [self.webView loadRequest:requestObj];
}

- (void)displayAlertOnOK:(void (^)(void))okCompletion onRetry:(void (^)(void))retryCompletion {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:UAMessageCenterLocalizedString(@"ua_connection_error")
                                                                   message:UAMessageCenterLocalizedString(@"ua_mc_failed_to_load")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:UAMessageCenterLocalizedString(@"ua_ok")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              if (okCompletion) {
                                                                  okCompletion();
                                                              }
                                                          }];
    
    [alert addAction:defaultAction];
    
    if (retryCompletion) {
        UIAlertAction *retryAction = [UIAlertAction actionWithTitle:UAMessageCenterLocalizedString(@"ua_retry_button")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                if (retryCompletion) {
                                                                    retryCompletion();
                                                                }
                                                            }];
        
        [alert addAction:retryAction];
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark UAWKWebViewDelegate

- (void)webView:(WKWebView *)wv decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if (self.messageState != LOADING) {
        UA_LWARN(@"WARNING: messageState = %u. Should be \"LOADING\"",self.messageState);
    }
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)navigationResponse.response;
        NSInteger status = httpResponse.statusCode;
        if (status >= 400 && status <= 599) {
            decisionHandler(WKNavigationResponsePolicyCancel);
            [self coverWithBlankViewAndShowLoadingIndicator];
            if (status >= 500) {
                // Display a retry alert
                [self displayAlertOnOK:nil onRetry:^{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                    [self loadMessage:self.message onlyIfChanged:NO];
#pragma GCC diagnostic pop
                }];
            } else {
                // Display a generic alert
                [self displayAlertOnOK:nil onRetry:nil];
            }
            return;
        }
    }
    
    decisionHandler(WKNavigationResponsePolicyAllow);

}

- (void)webView:(WKWebView *)wv didFinishNavigation:(WKNavigation *)navigation {
    if (self.messageState != LOADING) {
        UA_LWARN(@"WARNING: messageState = %u. Should be \"LOADING\"",self.messageState);
    }
    if ([wv.URL.absoluteString isEqualToString:urlForBlankPage]) {
        [self loadMessageIntoWebView];
        return;
    }
    
    self.messageState = LOADED;
 
    // Mark message as read after it has finished loading
    if (self.message.unread) {
        [self.message markMessageReadWithCompletionHandler:nil];
    }
    
    [self uncoverAndHideLoadingIndicator];
}

- (void)webView:(WKWebView *)wv didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (self.messageState != LOADING) {
        UA_LWARN(@"WARNING: messageState = %u. Should be \"LOADING\"",self.messageState);
    }
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    UA_LDEBUG(@"Failed to load message: %@", error);
    
    self.messageState = NONE;
    
    [self hideLoadingIndicator];

    // Display a retry alert
    [self displayAlertOnOK:nil onRetry:^{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self loadMessage:self.message onlyIfChanged:NO];
#pragma GCC diagnostic pop
    }];
}

- (void)closeWindowAnimated:(BOOL)animated {
    if (self.closeBlock) {
        self.closeBlock(animated);
    }
    self.message=nil;
}

@end
