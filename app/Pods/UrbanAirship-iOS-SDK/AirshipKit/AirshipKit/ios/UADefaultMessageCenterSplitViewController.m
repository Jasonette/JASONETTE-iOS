/* Copyright 2017 Urban Airship and Contributors */

#import "UADefaultMessageCenterSplitViewController.h"
#import "UADefaultMessageCenterListViewController.h"
#import "UADefaultMessageCenterMessageViewController.h"
#import "UAMessageCenterMessageViewController.h"
#import "UADefaultMessageCenter.h"
#import "UADefaultMessageCenterStyle.h"
#import "UAirship.h"
#import "UAMessageCenterLocalization.h"
#import "UAConfig.h"

@interface UADefaultMessageCenterSplitViewController ()

@property (nonatomic, strong) UADefaultMessageCenterListViewController *listViewController;
@property (nonatomic, strong) UIViewController<UAMessageCenterMessageViewProtocol> *messageViewController;
@property (nonatomic, strong) UINavigationController *listNav;
@property (nonatomic, strong) UINavigationController *messageNav;
@property (nonatomic, assign) BOOL showMessageViewOnViewDidAppear;

@end

@implementation UADefaultMessageCenterSplitViewController

- (void)configure {

    self.listViewController = [[UADefaultMessageCenterListViewController alloc] initWithNibName:@"UADefaultMessageCenterListViewController"
                                                                     bundle:[UAirship resources]];
    self.listNav = [[UINavigationController alloc] initWithRootViewController:self.listViewController];
    self.viewControllers = @[self.listNav];
    
    self.title = UAMessageCenterLocalizedString(@"ua_message_center_title");

    self.delegate = self.listViewController;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        [self configure];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self configure];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.listViewController.messageViewController) {
        self.messageViewController = self.listViewController.messageViewController;
        self.showMessageViewOnViewDidAppear = YES;
   } else {
        if (UAirship.shared.config.useWKWebView) {
            self.messageViewController = [[UAMessageCenterMessageViewController alloc] initWithNibName:@"UAMessageCenterMessageViewController"
                                                                                                bundle:[UAirship resources]];
        } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            self.messageViewController = [[UADefaultMessageCenterMessageViewController alloc] initWithNibName:@"UADefaultMessageCenterMessageViewController"
                                                                                                       bundle:[UAirship resources]];
            
            ((UADefaultMessageCenterMessageViewController *)self.messageViewController).filter = self.filter;
#pragma GCC diagnostic pop
        }
        self.listViewController.messageViewController = self.messageViewController;
        self.showMessageViewOnViewDidAppear = NO;
    }

    self.messageNav = [[UINavigationController alloc] initWithRootViewController:self.messageViewController];
    self.viewControllers = @[self.listNav,self.messageNav];
    
    // display both view controllers in horizontally regular contexts
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    
    if (self.style) {
        [self applyStyle];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.showMessageViewOnViewDidAppear) {
        self.showMessageViewOnViewDidAppear = NO;
        if (self.collapsed) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [self.listViewController displayMessage:self.messageViewController.message];
#pragma GCC diagnostic pop
        }
    }
}

- (void)setStyle:(UADefaultMessageCenterStyle *)style {
    _style = style;
    self.listViewController.style = style;

    if (self.listNav && self.messageNav) {
        [self applyStyle];
    }
}

- (void)applyStyle {
    if (self.style.navigationBarColor) {
        self.listNav.navigationBar.barTintColor = self.style.navigationBarColor;
        self.messageNav.navigationBar.barTintColor = self.style.navigationBarColor;
    }

    // Only apply opaque property if a style is set
    if (self.style) {
        self.listNav.navigationBar.translucent = !self.style.navigationBarOpaque;
        self.messageNav.navigationBar.translucent = !self.style.navigationBarOpaque;
    }

    NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionary];

    if (self.style.titleColor) {
        titleAttributes[NSForegroundColorAttributeName] = self.style.titleColor;
    }

    if (self.style.titleFont) {
        titleAttributes[NSFontAttributeName] = self.style.titleFont;
    }

    if (titleAttributes.count) {
        self.listNav.navigationBar.titleTextAttributes = titleAttributes;
        self.messageNav.navigationBar.titleTextAttributes = titleAttributes;
    }

    if (self.style.tintColor) {
        self.view.tintColor = self.style.tintColor;
    }
}

- (void)setFilter:(NSPredicate *)filter {
    _filter = filter;
    self.listViewController.filter = filter;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    if ([self.messageViewController isKindOfClass:[UADefaultMessageCenterMessageViewController class]]) {
        ((UADefaultMessageCenterMessageViewController *)self.messageViewController).filter = self.filter;
    }
#pragma GCC diagnostic pop
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.listViewController.title = title;
}

@end
