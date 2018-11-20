/* Copyright 2017 Urban Airship and Contributors */

#import "UAOverlayViewController.h"

#import "UABespokeCloseView.h"
#import "UABeveledLoadingIndicator.h"
#import "UAUtils.h"
#import "UAirship.h"
#import "UAGlobal.h"
#import "UAInboxMessage.h"

#import "UAWKWebViewNativeBridge.h"

#import <QuartzCore/QuartzCore.h>

#define kUAOverlayViewControllerWebViewPadding 15

#define kUAOverlayViewNibName @"UAOverlayView"

static NSMutableSet *overlayControllers_ = nil;

@interface UAOverlayView : UIView

/**
 * The WKWebView used to display the message content.
 */
@property (strong, nonatomic) IBOutlet WKWebView *webView;

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UIView *shadeView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIView *closeButtonView;
@property (strong, nonatomic) IBOutlet UIView *backgroundInsetView;
@property (strong, nonatomic) IBOutlet UABeveledLoadingIndicator *loadingIndicatorView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *containerViewWidthConstraint;

/**
 * Block invoked whenever the [UIView layoutSubviews] method is called.
 */
@property(nonatomic, copy) void (^onLayoutSubviews)(void);

@property(nonatomic, assign) CGSize size;
@property(nonatomic, assign) BOOL aspectLock;


@end

@implementation UAOverlayView

- (id)initWithSize:(CGSize)size aspectLock:(BOOL)aspectLock {
    NSBundle *bundle = [UAirship resources];
    self = [[bundle loadNibNamed:kUAOverlayViewNibName owner:self options:nil] firstObject];

    if (self) {
        self.size = size;
        self.aspectLock = aspectLock;
    }

    return self;
}

// Normalizes the provided size to aspect fill the current screen
- (CGSize)normalizeSizeForScreen:(CGSize)size {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;

    CGFloat screenAspect = screenSize.width/screenSize.height;
    CGFloat landingPageAspect = size.width/size.height;

    BOOL sizeIsValid = ([self validateWidth:size.width] && [self validateHeight:size.height]);

    if (self.aspectLock && [self validateAspectRatio:landingPageAspect] && !sizeIsValid) {

        if (screenAspect > landingPageAspect) {
            return CGSizeMake(size.width * (screenSize.height/size.height), screenSize.height);
        } else {
            return CGSizeMake(screenSize.width, size.height * (screenSize.width/size.width));
        }
    }

    // Fill screen width if width is invalid
    if (![self validateWidth:size.width]) {
        size.width = screenSize.width;
    }

    // Fill screen height if height is invalid
    if (![self validateHeight:size.height]) {
        size.height = screenSize.height;
    }

    return size;
}

-(BOOL)validateAspectRatio:(CGFloat)aspectRatio {


    if (isnan(aspectRatio) || aspectRatio > INTMAX_MAX) {
        return NO;
    }

    if (aspectRatio == 0) {
        return NO;
    }

    return YES;
}

- (BOOL)validateWidth:(CGFloat)width {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat maximumOverlayViewWidth = screenSize.width;
    CGFloat minimumOverlayViewWidth = (kUAOverlayViewControllerWebViewPadding * 2) * 2;

    if (width < minimumOverlayViewWidth) {
        if (width != 0) {
            UA_LDEBUG(@"Overlay view width is less than the minimum allowed width. Resizing to fit screen.");
        }
        return NO;
    }

    if (width > maximumOverlayViewWidth) {
        UA_LDEBUG(@"Overlay view width is greater than the maximum allowed width. Resizing to fit screen.");
        return NO;
    }

    return YES;
}

- (BOOL)validateHeight:(CGFloat)height {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat maximumOverlayViewHeight = screenSize.height;
    CGFloat minimumOverlayViewHeight = (kUAOverlayViewControllerWebViewPadding * 4) * 2;

    if (height < minimumOverlayViewHeight) {
        if (height != 0) {
            UA_LDEBUG(@"Overlay view height is less than the minimum allowed height. Resizing to fit screen.");
        }
        return NO;
    }

    if (height > maximumOverlayViewHeight) {
        UA_LDEBUG(@"Overlay view height is greater than the maximum allowed height. Resizing to fit screen.");
        return NO;
    }

    return YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGSize screenSize = [UIScreen mainScreen].bounds.size;

    CGSize normalizedSize = [self normalizeSizeForScreen:self.size];

    CGFloat widthConstant = normalizedSize.width - screenSize.width;
    CGFloat heightConstant = normalizedSize.height - screenSize.height;

    self.containerViewHeightConstraint.constant = heightConstant;
    self.containerViewWidthConstraint.constant = widthConstant;

    [self.containerView layoutIfNeeded];

    if (self.onLayoutSubviews) {
        self.onLayoutSubviews();
    }
}

@end

@interface UAOverlayViewController() <UAWKWebViewDelegate>


/**
 * The URL being displayed.
 */
@property (nonatomic, strong) NSURL *url;

/**
 * The request headers
 */
@property (nonatomic, strong) NSDictionary *headers;

/**
 * The message being displayed, if applicable. This value may be nil.
 */
@property (nonatomic, strong) UAInboxMessage *message;
@property (nonatomic, strong) UIViewController *parentViewController;
@property (nonatomic, strong) UAOverlayView *overlayView;
@property (nonatomic, strong) UIView *background;
@property (nonatomic, strong) UIView *backgroundInset;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UABespokeCloseView *closeButtonView;
@property (nonatomic, strong) UABeveledLoadingIndicator *loadingIndicator;
@property (nonatomic, strong) UAWKWebViewNativeBridge *nativeBridge;
@property (nonatomic, assign) UIUserInterfaceSizeClass lastHorizontalSizeClass;

@end

@implementation UAOverlayViewController

/**
 * Setup a container for the newly allocated controllers, will be released by OS.
 */
+ (void)initialize {
    if (self == [UAOverlayViewController class]) {
        overlayControllers_ = [[NSMutableSet alloc] initWithCapacity:1];
    }
}

+ (void)showOverlayViewController:(UAOverlayViewController *)overlayController {
    // Close existing windows
    [UAOverlayViewController closeAll:NO];
    // Add the overlay controller to our static collection
    [overlayControllers_ addObject:overlayController];
    //load it
    [overlayController load];
}

+ (void)showURL:(NSURL *)url withHeaders:(NSDictionary *)headers {
    CGSize defaultsToFullSize = CGSizeZero;
    UAOverlayViewController *overlayController = [[UAOverlayViewController alloc] initWithParentViewController:[UAUtils topController]
                                                                                                                      andURL:url
                                                                                                                  andMessage:nil
                                                                                                                  andHeaders:headers
                                                                                                                     size:defaultsToFullSize
                                                                                                               aspectLock:false];
    [self showOverlayViewController:overlayController];
}

+ (void)showURL:(NSURL *)url withHeaders:(NSDictionary *)headers size:(CGSize)size aspectLock:(BOOL)aspectLock {
    UAOverlayViewController *overlayController = [[UAOverlayViewController alloc] initWithParentViewController:[UAUtils topController]
                                                                                                                      andURL:url
                                                                                                                  andMessage:nil
                                                                                                                  andHeaders:headers
                                                                                                                     size:size
                                                                                                               aspectLock:aspectLock];
    [self showOverlayViewController:overlayController];
}

+ (void)showMessage:(UAInboxMessage *)message {
    NSDictionary *headers = @{@"Authorization":[UAUtils userAuthHeaderString]};
    [UAOverlayViewController showMessage:message withHeaders:headers];
}

+ (void)showMessage:(UAInboxMessage *)message withHeaders:(NSDictionary *)headers {
    CGSize defaultsToFullSize = CGSizeZero;
    UAOverlayViewController *overlayController = [[UAOverlayViewController alloc] initWithParentViewController:[UAUtils topController]
                                                                                                                      andURL:message.messageBodyURL
                                                                                                                  andMessage:message
                                                                                                                  andHeaders:headers
                                                                                                                     size:defaultsToFullSize
                                                                                                               aspectLock:false];
    [self showOverlayViewController:overlayController];
}

+ (void)showMessage:(UAInboxMessage *)message withHeaders:(NSDictionary *)headers size:(CGSize)size aspectLock:(BOOL)aspectLock {
    UAOverlayViewController *overlayController = [[UAOverlayViewController alloc] initWithParentViewController:[UAUtils topController]
                                                                                                                      andURL:message.messageBodyURL
                                                                                                                  andMessage:message
                                                                                                                  andHeaders:headers
                                                                                                                     size:size
                                                                                                               aspectLock:aspectLock];
    [self showOverlayViewController:overlayController];
}

+ (void)closeAll:(BOOL)animated {
    for (UAOverlayViewController *oc in overlayControllers_) {
        [oc closeWindowAnimated:animated];
    }
}

- (instancetype)initWithParentViewController:(UIViewController *)parent andURL:(NSURL *)url andMessage:(UAInboxMessage *)message andHeaders:(NSDictionary *)headers size:(CGSize)size aspectLock:(BOOL)aspectLock {
    self = [super init];
    if (self) {

        self.overlayView = [[UAOverlayView alloc] initWithSize:size aspectLock:aspectLock];
        self.overlayView.alpha = 0.0;

        self.parentViewController = parent;
        self.url = url;
        self.message = message;
        self.headers = headers;

        // Set the frame later
        self.overlayView.webView.backgroundColor = [UIColor clearColor];
        self.overlayView.webView.opaque = NO;
        self.nativeBridge = [[UAWKWebViewNativeBridge alloc] init];
        self.nativeBridge.forwardDelegate = self;
        self.overlayView.webView.navigationDelegate = self.nativeBridge;

        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}]) {
            [self.overlayView.webView.configuration setDataDetectorTypes:WKDataDetectorTypeNone];
        }
    }

    return self;
}

- (void)dealloc {
    self.overlayView.webView.navigationDelegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void)load {

    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:self.url];

    for (id key in self.headers) {
        id value = [self.headers objectForKey:key];
        if (![key isKindOfClass:[NSString class]] || ![value isKindOfClass:[NSString class]]) {
            UA_LERR(@"Invalid header value.  Only string values are accepted for header names and values.");
            continue;
        }

        [requestObj addValue:value forHTTPHeaderField:key];
    }

    [requestObj setTimeoutInterval:30];

    [self.overlayView.webView stopLoading];
    [self.overlayView.webView loadRequest:requestObj];
    [self showOverlay];

    [self.overlayView.loadingIndicatorView show];
}

- (void)showOverlay {

    UIView *parentView = self.parentViewController.view;

    [parentView addSubview:self.overlayView];
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;

    if (parentView != nil) {
        // Constrain overlay view to center of parent view
        NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:parentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:parentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];

        // Constrain overlay view to size of parent view
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:parentView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:parentView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];

        xConstraint.active = YES;
        yConstraint.active = YES;
        widthConstraint.active = YES;
        heightConstraint.active = YES;
    }


    // Technically UABespokeCloseView is a not a UIButton, so we will be adding it as a subView of an actual, transparent one.
    self.closeButtonView.userInteractionEnabled = NO;

    // Tapping the button will finish the overlay and dismiss all views
    [self.overlayView.closeButton addTarget:self action:@selector(finish) forControlEvents:UIControlEventTouchUpInside];

    // Fade in
    [UIView animateWithDuration:0.5 animations:^{
        self.overlayView.alpha = 1.0;
    }];
}

- (void)finish {
    [self finish:YES];
}


/**
 * Removes all views from the hierarchy and releases self, animated if desired.
 * @param animated `YES` to animate the transition, otherwise `NO`
 */
- (void)finish:(BOOL)animated {

    void (^remove)(void) = ^{
        [self.overlayView removeFromSuperview];
        [overlayControllers_ removeObject:self];
    };

    if (animated) {
        // Fade out and remove
        [UIView
         animateWithDuration:0.5
         animations:^{
             self.overlayView.alpha = 0.0;
         } completion:^(BOOL finished){
             remove();
         }];
    } else {
        remove();
    }
}


#pragma mark UAWKWebViewDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self.overlayView.loadingIndicatorView hide];

    if (self.message) {
        [self.message markMessageReadWithCompletionHandler:nil];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error {

    __typeof(self) __weak weakSelf = self;

    // Wait twenty seconds, try again if necessary
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        __typeof(self) __strong strongSelf = weakSelf;
        if (strongSelf) {
            UA_LINFO(@"Retrying url: %@", strongSelf.url);
            [strongSelf load];
        }
    });
}

- (void)closeWindowAnimated:(BOOL)animated {
    UA_LDEBUG(@"Closing overlay controller: %@", [self.url absoluteString]);
    [self finish:animated];
}

@end

