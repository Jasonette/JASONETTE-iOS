/* Copyright 2017 Urban Airship and Contributors */

#import "UADefaultMessageCenterMessageViewController.h"
#import "UAWebViewDelegate.h"
#import "UAInbox.h"
#import "UAirship.h"
#import "UAInboxMessageList.h"
#import "UAInboxMessage.h"
#import "UAUtils.h"
#import "UIWebView+UAAdditions.h"
#import "UAMessageCenterLocalization.h"
#import "UABeveledLoadingIndicator.h"

#define kMessageUp 0
#define kMessageDown 1

@interface UADefaultMessageCenterMessageViewController () <UAUIWebViewDelegate, UARichContentWindow, UAMessageCenterMessageViewProtocol>

@property (nonatomic, strong) UAWebViewDelegate *webViewDelegate;

/**
 * The UIWebView used to display the message content.
 */
@property (nonatomic, strong) UIWebView *webView;

/**
 * The loading indicator.
 */
@property (weak, nonatomic) IBOutlet UABeveledLoadingIndicator *loadingIndicatorView;

/**
 * The index of the currently displayed message.
 */
@property (nonatomic, assign) NSUInteger messageIndex;

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
 * The messages displayed in the message table.
 */
@property (nonatomic, copy) NSArray *messages;

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

@implementation UADefaultMessageCenterMessageViewController

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
    self.webView.delegate = nil;
    [self.webView stopLoading];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webViewDelegate = [[UAWebViewDelegate alloc] init];
    self.webViewDelegate.forwardDelegate = self;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    self.webViewDelegate.richContentWindow = self;
#pragma GCC diagnostic pop
    self.webView.delegate = self.webViewDelegate;

    // Allow the webView to detect data types (e.g. phone numbers, addresses) at will
    [self.webView setDataDetectorTypes:UIDataDetectorTypeAll];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:UAMessageCenterLocalizedString(@"ua_delete")
                                                                               style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(delete:)];
    
    // get initial list of messages in the inbox
    [self copyMessages];
    
    // load message or cover view if no message waiting to load
    switch (self.messageState) {
        case NONE:
            [self coverWithMessageAndHideLoadingIndicator:UAMessageCenterLocalizedString(@"ua_message_not_selected")];
            break;
        case FETCHING:
            [self coverWithBlankViewAndShowLoadingIndicator];
            break;
        case TO_LOAD:
            [self loadMessage:self.message onlyIfChanged:NO];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageListUpdated)
                                                 name:UAInboxMessageListUpdatedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    self.isVisible = YES;

    if (self.messageState == LOADED) {
        [self uncoverAndHideLoadingIndicator];
    }
    
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UAInboxMessageListUpdatedNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.isVisible = NO;
}

#pragma mark -
#pragma mark UI

- (void)delete:(id)sender {
    if (self.message) {
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

- (void)loadMessageForID:(NSString *)messageID {
    [self loadMessage:[self messageForID:messageID] onlyIfChanged:NO];
}

- (void)loadMessageForID:(NSString *)messageID onlyIfChanged:(BOOL)onlyIfChanged onError:(void (^)(void))errorCompletion {
    // start by covering the view and showing the loading indicator
    [self coverWithBlankViewAndShowLoadingIndicator];
    
    // Refresh the list to see if the message is available in the cloud
    self.messageState = FETCHING;

    __weak id weakSelf = self;

    [[UAirship inbox].messageList retrieveMessageListWithSuccessBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            id strongSelf = weakSelf;
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
        });
        return;
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

- (void)loadMessageAtIndex:(NSUInteger)index {
    [self loadMessage:[self messageAtIndex:index] onlyIfChanged:NO];
}

static NSString *urlForBlankPage = @"about:blank";

- (void)loadMessage:(UAInboxMessage *)message onlyIfChanged:(BOOL)onlyIfChanged {
    if (!message) {
        if (self.messageState == LOADING) {
            [self.webView stopLoading];
        }
        self.messageState = NONE;
        self.message = nil;
        self.messageIndex=NSNotFound;
        [self coverWithMessageAndHideLoadingIndicator:UAMessageCenterLocalizedString(@"ua_message_not_selected")];
        return;
    }
    
    self.messageIndex = [self indexOfMessage:message];
    
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
    }
}

// load the message into the web view
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

#pragma mark -
#pragma mark Methods to manage copy of inbox message list

- (void)copyMessages {
    if (self.filter) {
        self.messages = [NSArray arrayWithArray:[[UAirship inbox].messageList.messages filteredArrayUsingPredicate:self.filter]];
    } else {
        self.messages = [NSArray arrayWithArray:[UAirship inbox].messageList.messages];
    }
}


- (UAInboxMessage *)messageAtIndex:(NSUInteger)index {
    if (index < self.messages.count) {
        return [self.messages objectAtIndex:index];
    } else {
        return nil;
    }
}

- (NSUInteger)indexOfMessage:(UAInboxMessage *)messageToFind {
    if (!messageToFind) {
        return NSNotFound;
    }
    
    for (NSUInteger index = 0;index<self.messages.count;index++) {
        UAInboxMessage *message = [self messageAtIndex:index];
        if ([messageToFind.messageID isEqualToString:message.messageID]) {
            return index;
        }
    }
    
    return NSNotFound;
}

- (UAInboxMessage *)messageForID:(NSString *)messageIDToFind {
    if (!messageIDToFind) {
        return nil;
    } else {
        for (UAInboxMessage *message in self.messages) {
            if ([messageIDToFind isEqualToString:message.messageID]) {
                return message;
            }
        }
    }
    
    return nil;
}


#pragma mark UAUIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    if (self.messageState != LOADING) {
        UA_LWARN(@"WARNING: messageState = %u. Should be \"LOADING\"",self.messageState);
    }
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:wv.request];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)cachedResponse.response;
    NSInteger status = httpResponse.statusCode;

    // If the server returns something in the error range, load a blank page
    if (status >= 400 && status <= 599) {
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
    } else if ([wv.request.URL.absoluteString isEqualToString:urlForBlankPage]) {
        [self loadMessageIntoWebView];
        return;
    }

    self.messageState = LOADED;

    // Mark message as read after it has finished loading
    if (self.message.unread) {
        [self.message markMessageReadWithCompletionHandler:nil];
    }

    [self.webView injectInterfaceOrientation:(UIInterfaceOrientation)[[UIDevice currentDevice] orientation]];
    
    [self uncoverAndHideLoadingIndicator];
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error {
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
}

#pragma mark UARichContentWindow

- (void)closeWebView:(UIWebView *)webView animated:(BOOL)animated {
    [self closeWindowAnimated:animated];
}

#pragma mark NSNotificationCenter callbacks

- (void)messageListUpdated {
    __weak id weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(self) strongSelf = weakSelf;
        // copy the back-end list of messages as it can change from under the UI
        [strongSelf copyMessages];
        if ((strongSelf.messages.count == 0) || (!strongSelf.message && strongSelf.messageState != FETCHING && strongSelf.messageState != TO_LOAD)) {
            [strongSelf coverWithMessageAndHideLoadingIndicator:UAMessageCenterLocalizedString(@"ua_message_not_selected")];
        } else {
            if ((strongSelf.messageState == LOADED) && ([strongSelf indexOfMessage:strongSelf.message] == NSNotFound)) {
                // If the index path is still accessible,
                // find the nearest accessible neighbor
                NSUInteger index = MIN(strongSelf.messages.count - 1, strongSelf.messageIndex);
                
                [strongSelf loadMessageAtIndex:index];
            }
        }
    });
}

@end
