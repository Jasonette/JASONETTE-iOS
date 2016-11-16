// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSLoginView.h"
#import "MSClientConnection.h"
#import "MSClient.h"
#import <WebKit/WebKit.h>

#pragma mark * MSLoginViewErrorDomain


NSString *const MSLoginViewErrorDomain = @"com.Microsoft.MicrosoftAzureMobile.LoginViewErrorDomain";


#pragma mark * UserInfo Request and Response Keys


NSString *const MSLoginViewErrorResponseData = @"com.Microsoft.MicrosoftAzureMobile.LoginViewErrorResponseData";


#pragma mark * MSLoginController Private Interface


@interface MSLoginView() <WKNavigationDelegate>

// Private instance properties
@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong, readwrite) NSURL* currentURL;
@property (nonatomic, strong, readwrite) NSString* endURLString;
@property (nonatomic, copy, readwrite)   MSLoginViewBlock completion;

@end


#pragma mark * MSLoginController Implementation


@implementation MSLoginView

@synthesize client = client_;
@synthesize startURL = startURL_;
@synthesize endURL = endURL_;
@synthesize toolbar = toolbar_;
@synthesize showToolbar = showToolbar_;
@synthesize toolbarPosition = toolbarPosition_;
@synthesize activityIndicator = activityIndicator_;
@synthesize webView = webView_;
@synthesize currentURL = currentURL_;
@synthesize endURLString = endURLString_;
@synthesize completion = completion_;


#pragma mark * Public Initializer and Dealloc Methods


-(id) initWithFrame:(CGRect)frame
             client:(MSClient *)client
           startURL:(NSURL *)startURL
             endURL:(NSURL *)endURL
         completion:(MSLoginViewBlock)completion;
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Capture all of the initializer values as properties
        client_ = client;
        startURL_ = startURL;
        endURL_ = endURL;
        endURLString_ = endURL_.absoluteString;        
        completion_ = [completion copy];
        
        // Create the activity indicator and toolbar
        activityIndicator_ = [[UIActivityIndicatorView alloc]
                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        toolbar_ = [self createToolbar:activityIndicator_];
        [self addSubview:toolbar_];
        
        // Set the toolbar defaults
        showToolbar_ = YES;
        toolbarPosition_ = UIToolbarPositionBottom;
        
        // Create the webview
        webView_ = [[WKWebView alloc] init];
        webView_.navigationDelegate = self;
        [self addSubview:webView_];
        
        // Call setViewFrames to update the subview frames
        [self setViewFrames];
        
        // Start the first request
        NSURLRequest *firstRequest = [NSURLRequest requestWithURL:startURL];
        [webView_ loadRequest:firstRequest];
    }
    return self;
}

#pragma mark * Public ShowToolbar Property Accessor Methods


-(void) setShowToolbar:(BOOL)showToolbar
{
    if (showToolbar != showToolbar_) {
        showToolbar_ = showToolbar;
        [self setViewFrames];
    }
}


#pragma mark * Public ToolbarPosition Property Accessor Methods


-(void) setToolbarPosition:(UIToolbarPosition)toolbarPosition
{
    if (toolbarPosition != toolbarPosition_) {
        toolbarPosition_ = toolbarPosition;
        [self setViewFrames];
    }
}


#pragma mark * WKNavigationDelegate Private Implementation

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    WKNavigationResponsePolicy shouldLoad = WKNavigationResponsePolicyAllow;
    NSURL *navResponseURL = navigationResponse.response.URL;
    NSString *responseURLString = navigationResponse.response.URL.absoluteString;
    //Check if we've reached the end URL
    if ([responseURLString rangeOfString:self.endURLString options:NSCaseInsensitiveSearch].location == 0) {
        [self callCompletion:navResponseURL orError:nil];
        shouldLoad = WKNavigationResponsePolicyCancel;
    }
    //Continue until we reach end URL
    decisionHandler(shouldLoad);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{    
    // Ignore "Fame Load Interrupted" errors.  These are caused by us
    // taking over the HTTP calls to the Microsoft Azure Mobile Service
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) {
        return;
    }
    
    // Ignore the NSURLErrorCancelled error which occurs if a user navigates
    // before the current request completes
    if ([error code] == NSURLErrorCancelled) {
        return;
    }

    [self callCompletion:nil orError:error];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self.activityIndicator stopAnimating];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [self.activityIndicator startAnimating];
}


#pragma mark * Private Methods


-(UIToolbar *) createToolbar:(UIActivityIndicatorView *)activityIndicatorView
{
    // Create the toolbar
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.barStyle = UIBarStyleDefault;
    
    // Create the three toolbar items
    UIBarButtonItem *activity = [[UIBarButtonItem alloc]
                                 initWithCustomView:activityIndicatorView];
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                        target:self
                        action:@selector(cancel:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                 initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                 target:self
                 action:nil];
    
    // Add the items to the toolbar
    [toolbar setItems:[NSArray arrayWithObjects:cancel, space, activity, nil]];
    
    return toolbar;
}

- (IBAction)cancel:(id)sender
{
    [self.activityIndicator stopAnimating];
    
    NSError *error =[self errorForLoginViewCanceled];
    [self callCompletion:nil orError:error];
}

-(void) setViewFrames
{
    CGRect rootFrame = self.frame;
    CGFloat toolBarHeight = 44;
    CGFloat webViewHeightOffset = 0;
    CGFloat webViewYOffset = 0;
    
    // Set the toolbar's frame if it should be displayed
    if (self.showToolbar) {
        if (self.toolbarPosition == UIToolbarPositionTop) {
            self.toolbar.frame = CGRectMake(0,
                                            0,
                                            rootFrame.size.width,
                                            toolBarHeight);
            self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleBottomMargin;
            
            // Offset the webView to make room for the toolbar at the top
            webViewYOffset = toolBarHeight;
        }
        else {
            self.toolbar.frame = CGRectMake(0,
                                            rootFrame.size.height-toolBarHeight,
                                            rootFrame.size.width,
                                            toolBarHeight);
            self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleTopMargin;
            
            // Shorten the webview to make room for the toolbar at the bottom
            webViewHeightOffset = toolBarHeight;
        }
    }
    
    // Set the webview's frame
    self.webView.frame = CGRectMake(0,
                                    webViewYOffset,
                                    rootFrame.size.width,
                                    rootFrame.size.height - webViewHeightOffset);
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
}

-(void) callCompletion:(NSURL *)endURL orError:(NSError *)error
{
    // Call the completion and then set it to nil so that it does not
    // get called twice.
    if (self.completion) {
        self.completion(endURL, error);
        self.completion = nil;
    }
}


#pragma mark * Private NSError Generation Methods

    
-(NSError *) errorForLoginViewCanceled
{
    return [self errorWithDescriptionKey:@"The login operation was canceled."
                            andErrorCode:MSLoginViewCanceled
                             andUserInfo:nil];
}

-(NSError *) errorWithDescriptionKey:(NSString *)descriptionKey
                        andErrorCode:(NSInteger)errorCode
                         andUserInfo:(NSDictionary *)userInfo
{
    NSString *description = NSLocalizedString(descriptionKey, nil);
    
    if (!userInfo) {
        userInfo = [[NSMutableDictionary alloc] init];
    }
    else {
        userInfo = [userInfo mutableCopy];
    }
    
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:MSLoginViewErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}

@end
