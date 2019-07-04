//
//  AHKActionSheet.m
//  AHKActionSheetExample
//
//  Created by Arkadiusz on 08-04-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "AHKActionSheet.h"
#import "AHKActionSheetViewController.h"
#import "UIImage+AHKAdditions.h"
#import "UIWindow+AHKAdditions.h"


static const NSTimeInterval kDefaultAnimationDuration = 0.5f;
// Length of the range at which the blurred background is being hidden when the user scrolls the tableView to the top.
static const CGFloat kBlurFadeRangeSize = 200.0f;
static NSString * const kCellIdentifier = @"Cell";
// How much user has to scroll beyond the top of the tableView for the view to dismiss automatically.
static const CGFloat kAutoDismissOffset = 80.0f;
// Offset at which there's a check if the user is flicking the tableView down.
static const CGFloat kFlickDownHandlingOffset = 20.0f;
static const CGFloat kFlickDownMinVelocity = 2000.0f;
// How much free space to leave at the top (above the tableView's contents) when there's a lot of elements. It makes this control look similar to the UIActionSheet.
static const CGFloat kTopSpaceMarginFraction = 0.333f;
// cancelButton's shadow height as the ratio to the cancelButton's height
static const CGFloat kCancelButtonShadowHeightRatio = 0.333f;


/// Used for storing button configuration.
@interface AHKActionSheetItem : NSObject
@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic) UIImage *image;
@property (nonatomic) AHKActionSheetButtonType type;
@property (strong, nonatomic) AHKActionSheetHandler handler;
@end

@implementation AHKActionSheetItem
@end



@interface AHKActionSheet() <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) NSMutableArray *items;
@property (weak, nonatomic, readwrite) UIWindow *previousKeyWindow;
@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) UIImageView *blurredBackgroundView;
@property (weak, nonatomic) UITableView *tableView;
@property (weak, nonatomic) UIButton *cancelButton;
@property (weak, nonatomic) UIView *cancelButtonShadowView;
@end

@implementation AHKActionSheet

#pragma mark - Init

+ (void)initialize
{
    if (self != [AHKActionSheet class]) {
        return;
    }

    AHKActionSheet *appearance = [self appearance];
    [appearance setBlurRadius:16.0f];
    [appearance setBlurTintColor:[UIColor colorWithWhite:1.0f alpha:0.5f]];
    [appearance setBlurSaturationDeltaFactor:1.8f];
    [appearance setButtonHeight:60.0f];
    [appearance setCancelButtonHeight:44.0f];
    [appearance setAutomaticallyTintButtonImages:@YES];
    [appearance setSelectedBackgroundColor:[UIColor colorWithWhite:0.1f alpha:0.2f]];
    [appearance setCancelButtonTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:17.0f],
                                                 NSForegroundColorAttributeName : [UIColor darkGrayColor] }];
    [appearance setButtonTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:17.0f]}];
    [appearance setDisabledButtonTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:14.0f],
                                                   NSForegroundColorAttributeName : [UIColor colorWithWhite:0.6f alpha:1.0] }];
    [appearance setDestructiveButtonTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:17.0f],
                                                      NSForegroundColorAttributeName : [UIColor redColor] }];
    [appearance setTitleTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:14.0f],
                                          NSForegroundColorAttributeName : [UIColor grayColor] }];
    [appearance setCancelOnPanGestureEnabled:@(YES)];
    [appearance setCancelOnTapEmptyAreaEnabled:@(NO)];
    [appearance setAnimationDuration:kDefaultAnimationDuration];
}

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super init];

    if (self) {
        _title = [title copy];
        _cancelButtonTitle = @"Cancel";
    }

    return self;
}

- (instancetype)init
{
    return [self initWithTitle:nil];
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    AHKActionSheetItem *item = self.items[(NSUInteger)indexPath.row];

    NSDictionary *attributes = nil;
    switch (item.type)
    {
        case AHKActionSheetButtonTypeDefault:
            attributes = self.buttonTextAttributes;
            break;
        case AHKActionSheetButtonTypeDisabled:
            attributes = self.disabledButtonTextAttributes;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        case AHKActionSheetButtonTypeDestructive:
            attributes = self.destructiveButtonTextAttributes;
            break;
    }

    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:item.title attributes:attributes];
    cell.textLabel.attributedText = attrTitle;
    cell.textLabel.textAlignment = [self.buttonTextCenteringEnabled boolValue] ? NSTextAlignmentCenter : NSTextAlignmentLeft;

    // Use image with template mode with color the same as the text (when enabled).
    BOOL useTemplateMode = [UIImage instancesRespondToSelector:@selector(imageWithRenderingMode:)] && [self.automaticallyTintButtonImages boolValue];
    cell.imageView.image = useTemplateMode ? [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : item.image;

    if ([UIImageView instancesRespondToSelector:@selector(tintColor)]){
        cell.imageView.tintColor = attributes[NSForegroundColorAttributeName] ? attributes[NSForegroundColorAttributeName] : [UIColor blackColor];
    }

    cell.backgroundColor = [UIColor clearColor];

    if (self.selectedBackgroundColor && ![cell.selectedBackgroundView.backgroundColor isEqual:self.selectedBackgroundColor]) {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = self.selectedBackgroundColor;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AHKActionSheetItem *item = self.items[(NSUInteger)indexPath.row];
    
    if (item.type != AHKActionSheetButtonTypeDisabled) {
        [self dismissAnimated:YES duration:self.animationDuration completion:item.handler];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.buttonHeight;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove separator inset as described here: http://stackoverflow.com/a/25877725/783960
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![self.cancelOnPanGestureEnabled boolValue]) {
        return;
    }

    [self fadeBlursOnScrollToTop];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (![self.cancelOnPanGestureEnabled boolValue]) {
        return;
    }

    CGPoint scrollVelocity = [scrollView.panGestureRecognizer velocityInView:self];

    BOOL viewWasFlickedDown = scrollVelocity.y > kFlickDownMinVelocity && scrollView.contentOffset.y < -self.tableView.contentInset.top - kFlickDownHandlingOffset;
    BOOL shouldSlideDown = scrollView.contentOffset.y < -self.tableView.contentInset.top - kAutoDismissOffset;
    if (viewWasFlickedDown) {
        // use a shorter duration for a flick down animation
        static const NSTimeInterval duration = 0.2f;
        [self dismissAnimated:YES duration:duration completion:self.cancelHandler];
    } else if (shouldSlideDown) {
        [self dismissAnimated:YES duration:self.animationDuration completion:self.cancelHandler];
    }
}

#pragma mark - Properties

- (NSMutableArray *)items
{
    if (!_items) {
        _items = [NSMutableArray array];
    }

    return _items;
}

#pragma mark - Actions

- (void)cancelButtonTapped:(id)sender
{
    [self dismissAnimated:YES duration:self.animationDuration completion:self.cancelHandler];
}

#pragma mark - Public

- (void)addButtonWithTitle:(NSString *)title type:(AHKActionSheetButtonType)type handler:(AHKActionSheetHandler)handler
{
    [self addButtonWithTitle:title image:nil type:type handler:handler];
}

- (void)addButtonWithTitle:(NSString *)title image:(UIImage *)image type:(AHKActionSheetButtonType)type handler:(AHKActionSheetHandler)handler
{
    AHKActionSheetItem *item = [[AHKActionSheetItem alloc] init];
    item.title = title;
    item.image = image;
    item.type = type;
    item.handler = handler;
    [self.items addObject:item];
}

- (void)show
{
    NSAssert([self.items count] > 0, @"Please add some buttons before calling -show.");

    if ([self isVisible]) {
        return;
    }

    self.previousKeyWindow = [UIApplication sharedApplication].keyWindow;
    UIImage *previousKeyWindowSnapshot = [self.previousKeyWindow ahk_snapshot];

    [self setUpNewWindow];
    [self setUpBlurredBackgroundWithSnapshot:previousKeyWindowSnapshot];
    [self setUpCancelButton];
    [self setUpTableView];
    
    if (self.cancelOnTapEmptyAreaEnabled.boolValue) {
        [self setUpCancelTapGestureForView:self.tableView];
    }
    
    CGFloat slideDownMinOffset = (CGFloat)fmin(CGRectGetHeight(self.frame) + self.tableView.contentOffset.y, CGRectGetHeight(self.frame));
    self.tableView.transform = CGAffineTransformMakeTranslation(0, slideDownMinOffset);

    void(^immediateAnimations)(void) = ^(void) {
        self.blurredBackgroundView.alpha = 1.0f;
    };

    void(^delayedAnimations)(void) = ^(void) {
        self.cancelButton.frame = CGRectMake(0,
                                             CGRectGetMaxY(self.bounds) - self.cancelButtonHeight,
                                             CGRectGetWidth(self.bounds),
                                             self.cancelButtonHeight);
            
        self.tableView.transform = CGAffineTransformMakeTranslation(0, 0);


        // manual calculation of table's contentSize.height
        CGFloat tableContentHeight = [self.items count] * self.buttonHeight + CGRectGetHeight(self.tableView.tableHeaderView.frame);

        CGFloat topInset;
        BOOL buttonsFitInWithoutScrolling = tableContentHeight < CGRectGetHeight(self.tableView.frame) * (1.0 - kTopSpaceMarginFraction);
        if (buttonsFitInWithoutScrolling) {
            // show all buttons if there isn't many
            topInset = CGRectGetHeight(self.tableView.frame) - tableContentHeight;
        } else {
            // leave an empty space on the top to make the control look similar to UIActionSheet
            topInset = (CGFloat)round(CGRectGetHeight(self.tableView.frame) * kTopSpaceMarginFraction);
        }
        self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);

        self.tableView.bounces = [self.cancelOnPanGestureEnabled boolValue] || !buttonsFitInWithoutScrolling;
    };

    if ([UIView respondsToSelector:@selector(animateKeyframesWithDuration:delay:options:animations:completion:)]){
        // Animate sliding in tableView and cancel button with keyframe animation for a nicer effect.
        [UIView animateKeyframesWithDuration:self.animationDuration delay:0 options:0 animations:^{
            immediateAnimations();

            [UIView addKeyframeWithRelativeStartTime:0.3f relativeDuration:0.7f animations:^{
                delayedAnimations();
            }];
        } completion:nil];

    } else {

        [UIView animateWithDuration:self.animationDuration animations:^{
            immediateAnimations();
            delayedAnimations();
        }];
    }
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissAnimated:animated duration:self.animationDuration completion:self.cancelHandler];
}

#pragma mark - Private

- (BOOL)isVisible
{
    // action sheet is visible iff it's associated with a window
    return !!self.window;
}

- (void)dismissAnimated:(BOOL)animated duration:(NSTimeInterval)duration completion:(AHKActionSheetHandler)completionHandler
{
    if (![self isVisible]) {
        return;
    }

    // delegate isn't needed anymore because tableView will be hidden (and we don't want delegate methods to be called now)
    self.tableView.delegate = nil;
    self.tableView.userInteractionEnabled = NO;
    // keep the table from scrolling back up
    self.tableView.contentInset = UIEdgeInsetsMake(-self.tableView.contentOffset.y, 0, 0, 0);

    void(^tearDownView)(void) = ^(void) {
        // remove the views because it's easiest to just recreate them if the action sheet is shown again
        for (UIView *view in @[self.tableView, self.cancelButton, self.blurredBackgroundView, self.window]) {
            [view removeFromSuperview];
        }

        self.window = nil;
        [self.previousKeyWindow makeKeyAndVisible];

        if (completionHandler) {
            completionHandler(self);
        }
    };

    if (animated) {
        // animate sliding down tableView and cancelButton.
        [UIView animateWithDuration:duration animations:^{
            self.blurredBackgroundView.alpha = 0.0f;
            self.cancelButton.transform = CGAffineTransformTranslate(self.cancelButton.transform, 0, self.cancelButtonHeight);
            self.cancelButtonShadowView.alpha = 0.0f;

            // Shortest shift of position sufficient to hide all tableView contents below the bottom margin.
            // contentInset isn't used here (unlike in -show) because it caused weird problems with animations in some cases.
            CGFloat slideDownMinOffset = (CGFloat)fmin(CGRectGetHeight(self.frame) + self.tableView.contentOffset.y, CGRectGetHeight(self.frame));
            self.tableView.transform = CGAffineTransformMakeTranslation(0, slideDownMinOffset);
        } completion:^(BOOL finished) {
            tearDownView();
        }];
    } else {
        tearDownView();
    }
}

- (void)setUpNewWindow
{
    AHKActionSheetViewController *actionSheetVC = [[AHKActionSheetViewController alloc] initWithNibName:nil bundle:nil];
    actionSheetVC.actionSheet = self;

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.window.opaque = NO;
    self.window.rootViewController = actionSheetVC;
    [self.window makeKeyAndVisible];
}

- (void)setUpBlurredBackgroundWithSnapshot:(UIImage *)previousKeyWindowSnapshot
{
    UIImage *blurredViewSnapshot = [previousKeyWindowSnapshot
                                    ahk_applyBlurWithRadius:self.blurRadius
                                    tintColor:self.blurTintColor
                                    saturationDeltaFactor:self.blurSaturationDeltaFactor
                                    maskImage:nil];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:blurredViewSnapshot];
    backgroundView.frame = self.bounds;
    backgroundView.alpha = 0.0f;
    [self addSubview:backgroundView];
    self.blurredBackgroundView = backgroundView;
}

- (void)setUpCancelTapGestureForView:(UIView*)view {
    UITapGestureRecognizer *cancelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelButtonTapped:)];
    cancelTap.delegate = self;
    [view addGestureRecognizer:cancelTap];
}

- (void)setUpCancelButton
{
    UIButton *cancelButton;
    // It's hard to check if UIButtonTypeSystem enumeration exists, so we're checking existence of another method that was introduced in iOS 7.
    if ([UIView instancesRespondToSelector:@selector(tintAdjustmentMode)]) {
        cancelButton= [UIButton buttonWithType:UIButtonTypeSystem];
    } else {
        cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }

    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:self.cancelButtonTitle
                                                                    attributes:self.cancelButtonTextAttributes];
    [cancelButton setAttributedTitle:attrTitle forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.frame = CGRectMake(0,
                                    CGRectGetMaxY(self.bounds) - self.cancelButtonHeight,
                                    CGRectGetWidth(self.bounds),
                                    self.cancelButtonHeight);
    // move the button below the screen (ready to be animated -show)
    cancelButton.transform = CGAffineTransformMakeTranslation(0, self.cancelButtonHeight);
    cancelButton.clipsToBounds = YES;
    [self addSubview:cancelButton];

    self.cancelButton = cancelButton;

    // add a small shadow/glow above the button
    if (self.cancelButtonShadowColor) {
        self.cancelButton.clipsToBounds = NO;
        CGFloat gradientHeight = (CGFloat)round(self.cancelButtonHeight * kCancelButtonShadowHeightRatio);
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, -gradientHeight, CGRectGetWidth(self.bounds), gradientHeight)];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = view.bounds;
        gradient.colors = @[ (id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor, (id)[self.blurTintColor colorWithAlphaComponent:0.1f].CGColor ];
        [view.layer insertSublayer:gradient atIndex:0];
        [self.cancelButton addSubview:view];
        self.cancelButtonShadowView = view;
    }
}

- (void)setUpTableView
{
    CGRect statusBarViewRect = [self convertRect:[UIApplication sharedApplication].statusBarFrame fromView:nil];
    CGFloat statusBarHeight = CGRectGetHeight(statusBarViewRect);
    CGRect frame = CGRectMake(0,
                              statusBarHeight,
                              CGRectGetWidth(self.bounds),
                              CGRectGetHeight(self.bounds) - statusBarHeight - self.cancelButtonHeight);

    UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.showsVerticalScrollIndicator = NO;

    if (self.separatorColor) {
        tableView.separatorColor = self.separatorColor;
    }

    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    [self insertSubview:tableView aboveSubview:self.blurredBackgroundView];
    // move the content below the screen, ready to be animated in -show
    tableView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(self.bounds), 0, 0, 0);
    // removes separators below the footer (between empty cells)
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.tableView = tableView;

    [self setUpTableViewHeader];
}

- (void)setUpTableViewHeader
{
    if (self.title) {
        // paddings similar to those in the UITableViewCell
        static const CGFloat leftRightPadding = 15.0f;
        static const CGFloat topBottomPadding = 8.0f;
        CGFloat labelWidth = CGRectGetWidth(self.bounds) - 2*leftRightPadding;

        NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:self.title attributes:self.titleTextAttributes];

        // create a label and calculate its size
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        [label setAttributedText:attrText];
        CGSize labelSize = [label sizeThatFits:CGSizeMake(labelWidth, MAXFLOAT)];
        label.frame = CGRectMake(leftRightPadding, topBottomPadding, labelWidth, labelSize.height);
        label.backgroundColor = [UIColor clearColor];

        // create and add a header consisting of the label
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), labelSize.height + 2*topBottomPadding)];
        [headerView addSubview:label];
        self.tableView.tableHeaderView = headerView;

    } else if (self.headerView) {
        self.tableView.tableHeaderView = self.headerView;
    }

    // add a separator between the tableHeaderView and a first row (technically at the bottom of the tableHeaderView)
    if (self.tableView.tableHeaderView && self.tableView.separatorStyle != UITableViewCellSeparatorStyleNone) {
        CGFloat separatorHeight = 1.0f / [UIScreen mainScreen].scale;
        CGRect separatorFrame = CGRectMake(0,
                                           CGRectGetHeight(self.tableView.tableHeaderView.frame) - separatorHeight,
                                           CGRectGetWidth(self.tableView.tableHeaderView.frame),
                                           separatorHeight);
        UIView *separator = [[UIView alloc] initWithFrame:separatorFrame];
        separator.backgroundColor = self.tableView.separatorColor;
        [self.tableView.tableHeaderView addSubview:separator];
    }
}

- (void)fadeBlursOnScrollToTop
{
    if (self.tableView.isDragging || self.tableView.isDecelerating) {
        CGFloat alphaWithoutBounds = 1.0f - ( -(self.tableView.contentInset.top + self.tableView.contentOffset.y) / kBlurFadeRangeSize);
        // limit alpha to the interval [0, 1]
        CGFloat alpha = (CGFloat)fmax(fmin(alphaWithoutBounds, 1.0f), 0.0f);
        self.blurredBackgroundView.alpha = alpha;
        self.cancelButtonShadowView.alpha = alpha;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // If the view that is touched is not the view associated with this view's table view, but
    // is one of the sub-views, we should not recognize the touch.
    // Original source: http://stackoverflow.com/questions/10755566/how-to-know-uitableview-is-pressed-when-empty
    if (touch.view != self.tableView && [touch.view isDescendantOfView:self.tableView]) {
        return NO;
    }
    return YES;
}

@end
