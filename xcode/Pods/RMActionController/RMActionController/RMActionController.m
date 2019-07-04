//
//  RMActionController.m
//  RMActionController
//
//  Created by Roland Moers on 01.05.15.
//  Copyright (c) 2015 Roland Moers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "RMActionController.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - Defines

#if !__has_feature(attribute_availability_app_extension)
//Normal App
#define RM_CURRENT_ORIENTATION_IS_LANDSCAPE_PREDICATE UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
#else
//App Extension
#define RM_CURRENT_ORIENTATION_IS_LANDSCAPE_PREDICATE [UIScreen mainScreen].bounds.size.height < [UIScreen mainScreen].bounds.size.width
#endif

typedef NS_ENUM(NSInteger, RMActionControllerAnimationStyle) {
    RMActionControllerAnimationStylePresenting,
    RMActionControllerAnimationStyleDismissing
};

#pragma mark - Interfaces

@interface RMActionController () <UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, assign, readwrite) RMActionControllerStyle style;

@property (nonatomic, strong) UIView *topContainer;
@property (nonatomic, strong) UIView *bottomContainer;

@property (nonatomic, strong) UILabel *headerTitleLabel;
@property (nonatomic, strong) UILabel *headerMessageLabel;

@property (nonatomic, strong) NSMutableArray *additionalActions;
@property (nonatomic, strong) NSMutableArray *doneActions;
@property (nonatomic, strong) NSMutableArray *cancelActions;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) BOOL hasBeenDismissed;

@property (nonatomic, weak) NSLayoutConstraint *yConstraint;

- (nonnull instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

@interface RMActionControllerAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) RMActionControllerAnimationStyle animationStyle;

@end

@interface RMAction ()

@property (nonatomic, weak) RMActionController *controller;

@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, assign, readwrite) RMActionStyle style;

@property (nonatomic, copy) void (^handler)(RMActionController *controller);

@property (nonatomic, strong) UIView *view;
- (UIView *)loadView;

- (BOOL)containsCancelAction;
- (void)executeHandlerOfCancelActionWithController:(RMActionController *)controller;

@end

@interface RMGroupedAction ()

@property (nonatomic, strong, readwrite) NSArray *actions;

@end

#pragma mark - Categories

@interface UIView (RMActionViewSeperators)

+ (UIView *)seperatorView;

@end

@implementation UIView (RMActionViewSeperators)

+ (UIView *)seperatorView {
    UIView *seperatorView = [[UIView alloc] initWithFrame:CGRectZero];
    seperatorView.backgroundColor = [UIColor grayColor];
    seperatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    return seperatorView;
}

@end

#pragma mark - Implementations

@implementation RMActionController

@synthesize disableMotionEffects = _disableMotionEffects;

#pragma mark - Class
+ (nullable instancetype)actionControllerWithStyle:(RMActionControllerStyle)style {
    return [self actionControllerWithStyle:style selectAction:nil andCancelAction:nil];
}

+ (nullable instancetype)actionControllerWithStyle:(RMActionControllerStyle)style selectAction:(nullable RMAction *)selectAction andCancelAction:(nullable RMAction *)cancelAction {
    return [self actionControllerWithStyle:style title:nil message:nil selectAction:selectAction andCancelAction:cancelAction];
}

+ (nullable instancetype)actionControllerWithStyle:(RMActionControllerStyle)style title:(nullable NSString *)aTitle message:(nullable NSString *)aMessage selectAction:(nullable RMAction *)selectAction andCancelAction:(nullable RMAction *)cancelAction {
    return [[self alloc] initWithStyle:style title:aTitle message:aMessage selectAction:selectAction andCancelAction:cancelAction];
}

#pragma mark - Init and Dealloc
- (nonnull instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        [self setup];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(RMActionControllerStyle)aStyle title:(NSString *)aTitle message:(NSString *)aMessage selectAction:(RMAction *)selectAction andCancelAction:(RMAction *)cancelAction {
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        [self setup];
        
        self.style = aStyle;
        self.title = aTitle;
        self.message = aMessage;
        
        if(selectAction && cancelAction) {
            RMGroupedAction *action = [RMGroupedAction actionWithStyle:RMActionStyleDefault andActions:@[cancelAction, selectAction]];
            [self addAction:action];
        } else {
            if(cancelAction) {
                [self addAction:cancelAction];
            }
            
            if(selectAction) {
                [self addAction:selectAction];
            }
        }
    }
    return self;
}

- (void)setup {
    self.additionalActions = [NSMutableArray array];
    self.doneActions = [NSMutableArray array];
    self.cancelActions = [NSMutableArray array];
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    } else {
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    
    self.transitioningDelegate = self;
    
    [self setupUIElements];
}

- (void)setupUIElements {
    //Instantiate elements
    self.headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.headerMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    //Setup properties of elements
    self.headerTitleLabel.backgroundColor = [UIColor clearColor];
    self.headerTitleLabel.textColor = [UIColor grayColor];
    self.headerTitleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
    self.headerTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.headerTitleLabel.numberOfLines = 0;
    
    self.headerMessageLabel.backgroundColor = [UIColor clearColor];
    self.headerMessageLabel.textColor = [UIColor grayColor];
    self.headerMessageLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    self.headerMessageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerMessageLabel.textAlignment = NSTextAlignmentCenter;
    self.headerMessageLabel.numberOfLines = 0;
}

- (void)setupContainerElements {
    //Top container
    if(self.disableBlurEffects) {
        self.topContainer = [[UIView alloc] initWithFrame:CGRectZero];
        
        [self.topContainer addSubview:self.contentView];
        
        if([self.headerTitleLabel.text length] > 0) {
            [self.topContainer addSubview:self.headerTitleLabel];
        }
        
        if([self.headerMessageLabel.text length] > 0) {
            [self.topContainer addSubview:self.headerMessageLabel];
        }
        
        for(RMAction *anAction in self.additionalActions) {
            [self.topContainer addSubview:anAction.view];
        }
        
        for(RMAction *anAction in self.doneActions) {
            [self.topContainer addSubview:anAction.view];
        }
    } else {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:[self containerBlurEffectStyleForCurrentStyle]];
        UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:blur];
        
        UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        vibrancyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        if(!self.disableBlurEffectsForContentView) {
            [vibrancyView.contentView addSubview:self.contentView];
        }
        
        if([self.headerTitleLabel.text length] > 0) {
            [vibrancyView.contentView addSubview:self.headerTitleLabel];
        }
        
        if([self.headerMessageLabel.text length] > 0) {
            [vibrancyView.contentView addSubview:self.headerMessageLabel];
        }
        
        for(RMAction *anAction in self.additionalActions) {
            [vibrancyView.contentView addSubview:anAction.view];
        }
        
        for(RMAction *anAction in self.doneActions) {
            [vibrancyView.contentView addSubview:anAction.view];
        }
        
        UIVisualEffectView *container = [[UIVisualEffectView alloc] initWithEffect:blur];
        [container.contentView addSubview:vibrancyView];
        
        self.topContainer = container;
        
        if(self.disableBlurEffectsForContentView) {
            [self.topContainer addSubview:self.contentView];
        }
    }
    
    //Botoom container
    if(self.disableBlurEffects) {
        self.bottomContainer = [[UIView alloc] initWithFrame:CGRectZero];
        
        for(RMAction *anAction in self.cancelActions) {
            [self.bottomContainer addSubview:anAction.view];
        }
    } else {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:[self containerBlurEffectStyleForCurrentStyle]];
        UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:blur];
        
        UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        vibrancyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        for(RMAction *anAction in self.cancelActions) {
            [vibrancyView.contentView addSubview:anAction.view];
        }
        
        UIVisualEffectView *container = [[UIVisualEffectView alloc] initWithEffect:blur];
        [container.contentView addSubview:vibrancyView];
        
        self.bottomContainer = container;
    }
    
    //Container properties
    self.topContainer.layer.cornerRadius = 4;
    self.topContainer.clipsToBounds = YES;
    self.topContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    if(!self.disableBlurEffects) {
        self.topContainer.backgroundColor = [UIColor clearColor];
    } else {
        self.topContainer.backgroundColor = [UIColor whiteColor];
    }
    
    self.bottomContainer.layer.cornerRadius = 4;
    self.bottomContainer.clipsToBounds = YES;
    self.bottomContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    if(!self.disableBlurEffects) {
        self.bottomContainer.backgroundColor = [UIColor clearColor];
    } else {
        self.bottomContainer.backgroundColor = [UIColor whiteColor];
    }
    
    //Debugging Accessibility Labels
#ifdef DEBUG
    self.topContainer.accessibilityLabel = @"TopContainer";
    self.bottomContainer.accessibilityLabel = @"BottomContainer";
#endif
}

- (void)setupConstraints {
    NSDictionary *metrics = @{@"seperatorHeight": @(1.f / [[UIScreen mainScreen] scale])};
    
    UIView *topContainer = self.topContainer;
    UIView *bottomContainer = self.bottomContainer;
    
    UILabel *headerTitleLabel = self.headerTitleLabel;
    UILabel *headerMessageLabel = self.headerMessageLabel;
    
    NSDictionary *bindingsDict = NSDictionaryOfVariableBindings(topContainer, bottomContainer, headerTitleLabel, headerMessageLabel);
    
    //Container constraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[topContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    
    if([self.cancelActions count] <= 0) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[bottomContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topContainer]-(10)-[bottomContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    }
    
    //Top container content constraints
    __block UIView *currentTopView = nil;
    __weak RMActionController *blockself = self;
    [self.doneActions enumerateObjectsUsingBlock:^(RMAction *action, NSUInteger index, BOOL *stop) {
        UIView *seperator = [UIView seperatorView];
        [self addSubview:seperator toContainer:self.topContainer];
        
        if(!currentTopView) {
            NSDictionary *bindings = @{@"actionView": action.view, @"seperator": seperator};
            
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[seperator]-(0)-|" options:0 metrics:nil views:bindings]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[seperator(seperatorHeight)]-(0)-[actionView]-(0)-|" options:0 metrics:metrics views:bindings]];
        } else {
            NSDictionary *bindings = @{@"actionView": action.view, @"seperator": seperator, @"currentTopView": currentTopView};
            
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[seperator]-(0)-|" options:0 metrics:nil views:bindings]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[seperator(seperatorHeight)]-(0)-[actionView]-(0)-[currentTopView]" options:0 metrics:metrics views:bindings]];
        }
        
        currentTopView = seperator;
    }];
    
    [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[contentView]-(0)-|" options:0 metrics:nil views:@{@"contentView": self.contentView}]];
    
    if(currentTopView) {
        [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView]-(0)-[currentTopView]" options:0 metrics:nil views:@{@"contentView": self.contentView, @"currentTopView": currentTopView}]];
    } else {
        [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView]-(0)-|" options:0 metrics:nil views:@{@"contentView": self.contentView}]];
    }
    
    if([self.additionalActions count] > 0 || [self.headerMessageLabel.text length] > 0 || [self.headerTitleLabel.text length] > 0) {
        __weak RMActionController *blockself = self;
        __block UIView *currentTopView = self.contentView;
        
        [self.additionalActions enumerateObjectsUsingBlock:^(RMAction *action, NSUInteger index, BOOL *stop) {
            UIView *actionView = action.view;
            
            UIView *seperatorView = [UIView seperatorView];
            [self addSubview:seperatorView toContainer:blockself.topContainer];
            
            NSDictionary *actionBindingsDict = NSDictionaryOfVariableBindings(currentTopView, seperatorView, actionView);
            
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[seperatorView]-(0)-|" options:0 metrics:nil views:actionBindingsDict]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:actionBindingsDict]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionView]-(0)-[seperatorView(seperatorHeight)]-(0)-[currentTopView]" options:0 metrics:metrics views:actionBindingsDict]];
            
            currentTopView = actionView;
        }];
        
        if([self.headerMessageLabel.text length] > 0 || [self.headerTitleLabel.text length] > 0) {
            UIView *seperatorView = [UIView seperatorView];
            [self addSubview:seperatorView toContainer:self.topContainer];
            
            NSDictionary *bindings = NSDictionaryOfVariableBindings(seperatorView, currentTopView);
            
            [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[seperatorView]-(0)-|" options:0 metrics:nil views:bindings]];
            [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[seperatorView(seperatorHeight)]-(0)-[currentTopView]" options:0 metrics:metrics views:bindings]];
            
            currentTopView = seperatorView;
            
            if([self.headerMessageLabel.text length] > 0) {
                bindings = @{@"messageLabel": self.headerMessageLabel, @"currentTopView": currentTopView};
                
                [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(5)-[messageLabel]-(5)-|" options:0 metrics:nil views:bindings]];
                [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[messageLabel]-(10)-[currentTopView]" options:0 metrics:nil views:bindings]];
                
                currentTopView = self.headerMessageLabel;
            }
            
            if([self.headerTitleLabel.text length] > 0) {
                bindings = @{@"titleLabel": self.headerTitleLabel, @"currentTopView": currentTopView};
                NSDictionary *metrics = @{@"Margin": [currentTopView isKindOfClass:[UILabel class]] ? @(2) : @(10)};
                
                [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(5)-[titleLabel]-(5)-|" options:0 metrics:nil views:bindings]];
                [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[titleLabel]-(Margin)-[currentTopView]" options:0 metrics:metrics views:bindings]];
                
                currentTopView = self.headerTitleLabel;
            }
        }
        
        NSDictionary *metrics = @{@"Margin": (currentTopView == self.headerMessageLabel || currentTopView == self.headerTitleLabel) ? @(10) : @(0)};
        NSDictionary *bindings = NSDictionaryOfVariableBindings(currentTopView);
        
        [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(Margin)-[currentTopView]" options:0 metrics:metrics views:bindings]];
    } else  {
        [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[contentView]" options:0 metrics:nil views:@{@"contentView": self.contentView}]];
    }
    
    //Bottom container content constraints
    if([self.cancelActions count] == 1) {
        RMAction *action = [self.cancelActions lastObject];
        NSDictionary *bindings = @{@"actionView": action.view};
        
        [self.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
        [self.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
    } else if([self.cancelActions count] > 1) {
        __weak RMActionController *blockself = self;
        __block UIView *currentTopView = nil;
        
        [self.cancelActions enumerateObjectsUsingBlock:^(RMAction *action, NSUInteger index, BOOL *stop) {
            if(!currentTopView) {
                NSDictionary *bindings = @{@"actionView": action.view};
                
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            } else {
                UIView *seperatorView = [UIView seperatorView];
                [self addSubview:seperatorView toContainer:self.bottomContainer];
                
                NSDictionary *bindings = @{@"actionView": action.view, @"currentTopView": currentTopView, @"seperator": seperatorView};
                
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[seperator]-(0)-|" options:0 metrics:nil views:bindings]];
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionView]-(0)-[seperator(seperatorHeight)]-(0)-[currentTopView]" options:0 metrics:metrics views:bindings]];
            }
            
            currentTopView = action.view;
        }];
        
        [self.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[currentTopView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(currentTopView)]];
    }
}

- (void)setupTopContainersTopMarginConstraint {
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[topContainer]" options:0 metrics:nil views:@{@"topContainer": self.topContainer}]];
}

- (void)viewDidLoad {
    NSAssert(self.contentView != nil, @"Error: The view of an RMActionController has been loaded before a contentView has been set. You have to set the contentView before presenting a RMActionController.");
    
    [super viewDidLoad];
    
#ifdef DEBUG
    self.view.accessibilityLabel = @"ActionControllerView";
#endif
    
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.layer.masksToBounds = YES;
    
    [self setupContainerElements];
    
    if(self.modalPresentationStyle != UIModalPresentationPopover) {
        [self.view addSubview:self.backgroundView];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[BGView]-(0)-|" options:0 metrics:nil views:@{@"BGView": self.backgroundView}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[BGView]-(0)-|" options:0 metrics:nil views:@{@"BGView": self.backgroundView}]];
    }
    
    [self.view addSubview:self.topContainer];
    if([self.cancelActions count] > 0) {
        [self.view addSubview:self.bottomContainer];
    }
    
    [self setupConstraints];
    if(self.modalPresentationStyle == UIModalPresentationPopover) {
        [self setupTopContainersTopMarginConstraint];
    }
    
    if(!self.disableMotionEffects) {
        UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        verticalMotionEffect.minimumRelativeValue = @(-10);
        verticalMotionEffect.maximumRelativeValue = @(10);
        
        UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(-10);
        horizontalMotionEffect.maximumRelativeValue = @(10);
        
        UIMotionEffectGroup *motionEffectGroup = [UIMotionEffectGroup new];
        motionEffectGroup.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
        
        [self.view addMotionEffect:motionEffectGroup];
    }
    
    CGSize minimalSize = [self.view systemLayoutSizeFittingSize:CGSizeMake(999, 999)];
    self.preferredContentSize = CGSizeMake(minimalSize.width, minimalSize.height+10);
    
    if([self respondsToSelector:@selector(popoverPresentationController)]) {
        self.popoverPresentationController.delegate = self;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.hasBeenDismissed = NO;
}

#pragma mark - Helper
- (UIBlurEffectStyle)containerBlurEffectStyleForCurrentStyle {
    switch (self.style) {
        case RMActionControllerStyleWhite:
            return UIBlurEffectStyleExtraLight;
        case RMActionControllerStyleBlack:
            return UIBlurEffectStyleDark;
        default:
            return UIBlurEffectStyleExtraLight;
    }
}

- (UIBlurEffectStyle)backgroundBlurEffectStyleForCurrentStyle {
    switch (self.style) {
        case RMActionControllerStyleWhite:
            return UIBlurEffectStyleDark;
        case RMActionControllerStyleBlack:
            return UIBlurEffectStyleLight;
        default:
            return UIBlurEffectStyleDark;
    }
}

- (void)handleCancelNotAssociatedWithAnyButton {
    // Grouped Actions are stored in the doneActions array, so we'll need to check them as well
    for(RMAction *anAction in [self.cancelActions arrayByAddingObjectsFromArray:self.doneActions]) {
        if([anAction containsCancelAction]) {
            [anAction executeHandlerOfCancelActionWithController:self];
            return;
        }
    }
}

- (void)backgroundViewTapped:(UIGestureRecognizer *)sender {
    if(!self.disableBackgroundTaps) {
        [self handleCancelNotAssociatedWithAnyButton];
    }
}

- (void)addSubview:(UIView *)subview toContainer:(UIView *)container {
    if([container isKindOfClass:[UIVisualEffectView class]]) {
        [[[[[(UIVisualEffectView *)container contentView] subviews] objectAtIndex:0] contentView] addSubview:subview];
    } else {
        [container addSubview:subview];
    }
}

#pragma mark - iOS Properties
- (UIStatusBarStyle)preferredStatusBarStyle {
    switch (self.style) {
        case RMActionControllerStyleWhite:
            return UIStatusBarStyleLightContent;
        case RMActionControllerStyleBlack:
            return UIStatusBarStyleDefault;
        default:
            return UIStatusBarStyleLightContent;
    }
}

#pragma mark - Custom Properties
- (BOOL)disableBlurEffects {
    if(!NSClassFromString(@"UIBlurEffect") || !NSClassFromString(@"UIVibrancyEffect") || !NSClassFromString(@"UIVisualEffectView")) {
        return YES;
    } else if(&UIAccessibilityIsReduceTransparencyEnabled && UIAccessibilityIsReduceTransparencyEnabled()) {
        return YES;
    }
    
    return _disableBlurEffects;
}

- (BOOL)disableBlurEffectsForBackgroundView {
    if(self.disableBlurEffects) {
        return YES;
    }
    
    return _disableBlurEffectsForBackgroundView;
}

- (BOOL)disableBlurEffectsForContentView {
    if(self.disableBlurEffects) {
        return YES;
    }
    
    return _disableBlurEffectsForContentView;
}

- (BOOL)disableBouncingEffects {
    if(&UIAccessibilityIsReduceMotionEnabled && UIAccessibilityIsReduceMotionEnabled()) {
        return YES;
    }
    
    return _disableBouncingEffects;
}

- (BOOL)disableMotionEffects {
    if(&UIAccessibilityIsReduceMotionEnabled && UIAccessibilityIsReduceMotionEnabled()) {
        return YES;
    }
    
    return _disableMotionEffects;
}

- (UIView *)backgroundView {
    if(!_backgroundView) {
        if(self.disableBlurEffectsForBackgroundView) {
            self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
            _backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        } else {
            UIVisualEffect *effect = [UIBlurEffect effectWithStyle:[self backgroundBlurEffectStyleForCurrentStyle]];
            self.backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
        }
        
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTapped:)];
        [_backgroundView addGestureRecognizer:tapRecognizer];
    }
    
    return _backgroundView;
}

- (NSString *)title {
    return self.headerTitleLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.headerTitleLabel.text = title;
}

- (NSString *)message {
    return self.headerMessageLabel.text;
}

- (void)setMessage:(NSString *)message {
    self.headerMessageLabel.text = message;
}

#pragma mark - Custom Transitions
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    RMActionControllerAnimationController *animationController = [[RMActionControllerAnimationController alloc] init];
    animationController.animationStyle = RMActionControllerAnimationStylePresenting;
    
    return animationController;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    RMActionControllerAnimationController *animationController = [[RMActionControllerAnimationController alloc] init];
    animationController.animationStyle = RMActionControllerAnimationStyleDismissing;
    
    return animationController;
}

#pragma mark - Actions
- (NSArray *)actions {
    return [[self.additionalActions arrayByAddingObjectsFromArray:self.doneActions] arrayByAddingObjectsFromArray:self.cancelActions];
}

- (void)addAction:(RMAction *)action {
    switch (action.style) {
        case RMActionStyleAdditional:
            [self.additionalActions addObject:action];
            break;
        case RMActionStyleDone:
            [self.doneActions addObject:action];
            break;
        case RMActionStyleCancel:
            [self.cancelActions addObject:action];
            break;
        case RMActionStyleDestructive:
            [self.doneActions addObject:action];
            break;
    }
    
    action.controller = self;
}

#pragma mark - UIpopopverPresentationController Delegates
- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    popoverPresentationController.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    [self handleCancelNotAssociatedWithAnyButton];
}

@end

@implementation RMActionControllerAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    if(self.animationStyle == RMActionControllerAnimationStylePresenting) {
        UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        if([toVC isKindOfClass:[RMActionController class]]) {
            RMActionController *actionController = (RMActionController *)toVC;
            
            if(actionController.disableBouncingEffects) {
                return 0.3f;
            } else {
                return 1.0f;
            }
        }
    } else if(self.animationStyle == RMActionControllerAnimationStyleDismissing) {
        return 0.3f;
    }
    
    return 1.0f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    
    if(self.animationStyle == RMActionControllerAnimationStylePresenting) {
        UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        if([toVC isKindOfClass:[RMActionController class]]) {
            RMActionController *actionController = (RMActionController *)toVC;
            
            [actionController setupTopContainersTopMarginConstraint];
            
            actionController.backgroundView.alpha = 0;
            [containerView addSubview:actionController.backgroundView];
            [containerView addSubview:actionController.view];
            
            NSDictionary *bindingsDict = @{@"BGView": actionController.backgroundView};
            
            [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[BGView]-(0)-|" options:0 metrics:nil views:bindingsDict]];
            [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[BGView]-(0)-|" options:0 metrics:nil views:bindingsDict]];
            
            [containerView addConstraint:[NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
            [containerView addConstraint:[NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
            
            actionController.yConstraint = [NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            [containerView addConstraint:actionController.yConstraint];
            
            [containerView setNeedsUpdateConstraints];
            [containerView layoutIfNeeded];
            
            [containerView removeConstraint:actionController.yConstraint];
            actionController.yConstraint = [NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            [containerView addConstraint:actionController.yConstraint];
            
            [containerView setNeedsUpdateConstraints];
            
            CGFloat damping = 1.0f;
            CGFloat duration = 0.3f;
            if(!actionController.disableBouncingEffects) {
                damping = 0.6f;
                duration = 1.0f;
            }
            
            [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:damping initialSpringVelocity:1 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
                actionController.backgroundView.alpha = 1;
                
                [containerView layoutIfNeeded];
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }
    } else if(self.animationStyle == RMActionControllerAnimationStyleDismissing) {
        UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        if([fromVC isKindOfClass:[RMActionController class]]) {
            RMActionController *actionController = (RMActionController *)fromVC;
            
            [containerView removeConstraint:actionController.yConstraint];
            actionController.yConstraint = [NSLayoutConstraint constraintWithItem:actionController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            [containerView addConstraint:actionController.yConstraint];
            
            [containerView setNeedsUpdateConstraints];
            
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                actionController.backgroundView.alpha = 0;
                
                [containerView layoutIfNeeded];
            } completion:^(BOOL finished) {
                [actionController.view removeFromSuperview];
                [actionController.backgroundView removeFromSuperview];
                
                actionController.hasBeenDismissed = NO;
                [transitionContext completeTransition:YES];
            }];
        }
    }
}

@end

@implementation RMAction

#pragma mark - Class
+ (nullable instancetype)actionWithTitle:(nonnull NSString *)title style:(RMActionStyle)style andHandler:(nullable void (^)( RMActionController * _Nonnull controller))handler {
    RMAction *action = [RMAction actionWithStyle:style andHandler:handler];
    action.title = title;
    
    return action;
}

+ (nullable instancetype)actionWithImage:(nonnull UIImage *)image style:(RMActionStyle)style andHandler:(nullable void (^)( RMActionController * _Nonnull controller))handler {
    RMAction *action = [RMAction actionWithStyle:style andHandler:handler];
    action.image = image;
    
    return action;
}

+ (instancetype)actionWithStyle:(RMActionStyle)style andHandler:(void (^)(RMActionController *controller))handler {
    RMAction *action = [[RMAction alloc] init];
    action.style = style;
    
    __weak RMAction *weakAction = action;
    [action setHandler:^(RMActionController *controller) {
        if(handler) {
            handler(controller);
        }
        
        if(weakAction.dismissesActionController) {
            if(controller.modalPresentationStyle == UIModalPresentationPopover || controller.yConstraint != nil) {
                [controller dismissViewControllerAnimated:YES completion:nil];
            } else {
                [controller dismissViewControllerAnimated:NO completion:nil];
            }
        }
    }];
    
    return action;
}

#pragma mark - Init and Dealloc
- (instancetype)init {
    self = [super init];
    if(self) {
        self.dismissesActionController = YES;
    }
    return self;
}

#pragma mark - Cancel Helper
- (BOOL)containsCancelAction {
    return self.style == RMActionStyleCancel;
}

- (void)executeHandlerOfCancelActionWithController:(RMActionController *)controller {
    if(self.style == RMActionStyleCancel) {
        self.handler(controller);
    }
}

#pragma mark - Other Helper
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - View
- (UIView *)view {
    if(!_view) {
        _view = [self loadView];
    }
    
    return _view;
}

- (UIView *)loadView {
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [actionButton addTarget:self action:@selector(viewTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    if(self.style == RMActionStyleCancel) {
        actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
    } else {
        actionButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    }
    
    if(!self.controller.disableBlurEffects) {
        [actionButton setBackgroundImage:[self imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3]] forState:UIControlStateHighlighted];
    } else {
        switch (self.controller.style) {
            case RMActionControllerStyleWhite:
                [actionButton setBackgroundImage:[self imageWithColor:[UIColor colorWithWhite:230./255. alpha:1]] forState:UIControlStateHighlighted];
                break;
            case RMActionControllerStyleBlack:
                [actionButton setBackgroundImage:[self imageWithColor:[UIColor colorWithWhite:0.2 alpha:1]] forState:UIControlStateHighlighted];
                break;
        }
    }
    
    if(self.title) {
        [actionButton setTitle:self.title forState:UIControlStateNormal];
    } else if(self.image) {
        [actionButton setImage:self.image forState:UIControlStateNormal];
    } else {
        [actionButton setTitle:@"Unknown title" forState:UIControlStateNormal];
    }
    
    [actionButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionButton(44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(actionButton)]];
    
    if(self.controller.disableBlurEffects) {
        if(self.style == RMActionStyleDestructive) {
            [actionButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        } else {
            [actionButton setTitleColor:[UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        }
    } else {
        if(self.style == RMActionStyleDestructive) {
            [actionButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        }
    }
    
    return actionButton;
}

- (void)viewTapped:(id)sender {
    self.handler(self.controller);
}

@end

@implementation RMGroupedAction

#pragma mark - Class
+ (nullable instancetype)actionWithTitle:(nonnull NSString *)title style:(RMActionStyle)style andHandler:(nullable void (^)(RMActionController * __nonnull))handler {
    [NSException raise:@"RMIllegalCallException" format:@"Tried to initialize a grouped action with +[%@ %@]. Please use +[%@ %@] instead.", NSStringFromClass(self), NSStringFromSelector(_cmd), NSStringFromClass(self), NSStringFromSelector(@selector(actionWithStyle:andActions:))];
    return nil;
}

+ (nullable instancetype)actionWithImage:(nonnull UIImage *)image style:(RMActionStyle)style andHandler:(nullable void (^)(RMActionController * __nonnull))handler {
    [NSException raise:@"RMIllegalCallException" format:@"Tried to initialize a grouped action with +[%@ %@]. Please use +[%@ %@] instead.", NSStringFromClass(self), NSStringFromSelector(_cmd), NSStringFromClass(self), NSStringFromSelector(@selector(actionWithStyle:andActions:))];
    return nil;
}

+ (nullable instancetype)actionWithStyle:(RMActionStyle)style andActions:(nonnull NSArray<RMAction<RMActionController *> *> *)actions {
    NSAssert([actions count] > 0, @"Tried to initialize RMGroupedAction with less than one action.");
    NSAssert([actions count] > 1, @"Tried to initialize RMGroupedAction with one action. Use RMAction in this case.");
    
    [actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSAssert([obj isKindOfClass:[RMAction class]], @"Tried to initialize RMGroupedAction with objects of types other than RMAction.");
    }];
    
    RMGroupedAction *groupedAction = [[RMGroupedAction alloc] init];
    groupedAction.style = style;
    groupedAction.actions = actions;
    
    [groupedAction setHandler:^(RMActionController *controller) {
        [NSException raise:@"RMInconsistencyException" format:@"The handler of a grouped action has been called."];
    }];
    
    return groupedAction;
}

#pragma mark - Cancel Helper
- (BOOL)containsCancelAction {
    for(RMAction *anAction in self.actions) {
        if([anAction containsCancelAction]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)executeHandlerOfCancelActionWithController:(RMActionController *)controller {
    for(RMAction *anAction in self.actions) {
        if([anAction containsCancelAction]) {
            [anAction executeHandlerOfCancelActionWithController:controller];
            return;
        }
    }
}

#pragma mark - Properties
- (RMActionController *)controller {
    return [[self.actions firstObject] controller];
    
}

- (void)setController:(RMActionController *)controller {
    for(RMAction *anAction in self.actions) {
        anAction.controller = controller;
    }
}

#pragma mark - View
- (UIView *)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor clearColor];
    
    NSDictionary *metrics = @{@"seperatorHeight": @(1.f / [[UIScreen mainScreen] scale])};
    
    __block UIView *currentLeft = nil;
    [self.actions enumerateObjectsUsingBlock:^(RMAction *action, NSUInteger index, BOOL *stop) {
        [action.view setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [view addSubview:action.view];
        
        if(index == 0) {
            NSDictionary *bindings = @{@"actionView": action.view};
            
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]" options:0 metrics:nil views:bindings]];
        } else {
            UIView *seperatorView = [UIView seperatorView];
            [view addSubview:seperatorView];
            
            NSDictionary *bindings = @{@"actionView": action.view, @"seperator": seperatorView, @"currentLeft": currentLeft};
            
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[seperator]-(0)-|" options:0 metrics:nil views:bindings]];
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[currentLeft(==actionView)]-(0)-[seperator(seperatorHeight)]-(0)-[actionView(==currentLeft)]" options:0 metrics:metrics views:bindings]];
        }
        
        currentLeft = action.view;
    }];
    
    NSDictionary *bindings = @{@"currentLeft": currentLeft};
    
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[currentLeft]-(0)-|" options:0 metrics:nil views:bindings]];
    
    return view;
}

@end
