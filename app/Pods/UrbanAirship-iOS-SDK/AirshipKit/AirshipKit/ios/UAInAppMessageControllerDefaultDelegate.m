/* Copyright 2017 Urban Airship and Contributors */

#import "UAInAppMessageControllerDefaultDelegate.h"
#import "UAInAppMessage.h"
#import "UAInAppMessageView+Internal.h"
#import "UAirship.h"
#import "UAInAppMessaging.h"
#import "UAInAppMessageButtonActionBinding.h"
#import "UANotificationCategory.h"
#import "UAUtils.h"
#import "NSString+UALocalizationAdditions.h"


#define kUAInAppMessageAnimationDuration 0.2
#define kUAInAppMessageiPhoneScreenWidthPercentage 0.95
#define kUAInAppMessagePadScreenWidthPercentage 0.45

@interface UAInAppMessageControllerDefaultDelegate ()

@property(nonatomic, assign) UAInAppMessagePosition position;
@property(nonatomic, strong) UIColor *primaryColor;
@property(nonatomic, strong) UIColor *secondaryColor;
@property(nonatomic, strong) NSArray *layoutConstraints;
@property(nonatomic, copy) void (^updateLayoutConstraintsBlock)(void);
@property(nonatomic, assign) BOOL isInverted;

@property(nonatomic, assign) UIUserInterfaceSizeClass lastHorizontalSizeClass;

@property(nonatomic, strong) NSLayoutConstraint *topConstraint;
@property(nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@end

@implementation UAInAppMessageControllerDefaultDelegate

- (instancetype)initWithMessage:(UAInAppMessage *)message {
    self = [super init];
    if (self) {
        // The primary and secondary colors aren't set in the model, choose sensible defaults
        self.position = message.position;
        self.primaryColor = message.primaryColor ?: [UAirship inAppMessaging].defaultPrimaryColor;
        self.secondaryColor = message.secondaryColor ?: [UAirship inAppMessaging].defaultSecondaryColor;
    }
    return self;
}

/**
 * Configures primary and secondary colors in the message view, inverting the color
 * scheme if necessary.
 */
- (void)configureColorsWithMessageView:(UAInAppMessageView *)messageView inverted:(BOOL)inverted {

    UIColor *primaryColor;
    UIColor *secondaryColor;

    if (inverted) {
        primaryColor = self.secondaryColor;
        secondaryColor = self.primaryColor;
    } else {
        primaryColor = self.primaryColor;
        secondaryColor = self.secondaryColor;
    }

    messageView.backgroundColor = primaryColor;

    messageView.tab.backgroundColor = secondaryColor;

    messageView.messageLabel.textColor = secondaryColor;

    [messageView.button1 setTitleColor:primaryColor forState:UIControlStateNormal];
    [messageView.button2 setTitleColor:primaryColor forState:UIControlStateNormal];
    messageView.button1.backgroundColor = secondaryColor;
    messageView.button2.backgroundColor = secondaryColor;
}

- (void)invertColorsWithMessageView:(UAInAppMessageView *)messageView {
    if (!self.isInverted) {
        [self configureColorsWithMessageView:messageView inverted:YES];
        self.isInverted = YES;
    }
}

- (void)uninvertColorsWithMessageView:(UAInAppMessageView *)messageView {
    if (self.isInverted) {
        [self configureColorsWithMessageView:messageView inverted:NO];
        self.isInverted = NO;
    }
}

- (NSString *)localizedButtonTitleForKey:(NSString *)key {
    return [key localizedStringWithTable:@"UrbanAirship"];
}

/**
 * Builds the UAInAppMessageView, configuring it with data from the message
 */
- (UAInAppMessageView *)buildMessageViewForMessage:(UAInAppMessage *)message {

    UIFont *messageFont = [UAirship inAppMessaging].font;

    // Button action bindings are an array of UAInAppMessageButtonActionBinding instances,
    // which represent a binding between an in-app message button, a localized title and action
    // name/argument pairs.
    NSArray *buttonActionBindings = message.buttonActionBindings;

    UAInAppMessageView *messageView = [[UAInAppMessageView alloc] initWithPosition:message.position
                                                                   numberOfButtons:buttonActionBindings.count];

    // Configure all the subviews
    messageView.messageLabel.text = message.alert;
    messageView.messageLabel.numberOfLines = 4;
    messageView.messageLabel.font = messageFont;

    messageView.button1.titleLabel.font = messageFont;
    messageView.button2.titleLabel.font = messageFont;

    // Set button titles accordingly
    if (buttonActionBindings.count) {
        UAInAppMessageButtonActionBinding *button1 = buttonActionBindings[0];

        [messageView.button1 setTitle:button1.title forState:UIControlStateNormal];
        if (buttonActionBindings.count > 1) {
            UAInAppMessageButtonActionBinding *button2 = buttonActionBindings[1];
            [messageView.button2 setTitle:button2.title forState:UIControlStateNormal];
        }
    }

    // Configure default colors
    [self configureColorsWithMessageView:messageView inverted:NO];

    // Update layout constraints if needed
    messageView.onLayoutSubviews = ^{
        self.updateLayoutConstraintsBlock();
    };

    return messageView;
}

/**
 * Adds the message view to the parent view with default constraints and generates the
 * updateLayoutConstraintsBlock for managing dynamic constraints.
 */
- (UIView *)viewForMessage:(UAInAppMessage *)message parentView:(UIView *)parentView {

    // Build the messageView, configuring it with data from the message
    UIView *messageView = [self buildMessageViewForMessage:message];

    [parentView addSubview:messageView];

    // Activate center on X axis constraint
    [NSLayoutConstraint constraintWithItem:messageView
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:parentView
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1
                                  constant:0].active = YES;

    if (self.position == UAInAppMessagePositionTop) {
        // Top constraint is used for animating the message in the top position.
        self.topConstraint = [NSLayoutConstraint constraintWithItem:messageView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:parentView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:-messageView.bounds.size.height];
        self.topConstraint.active = YES;
    } else if (self.position == UAInAppMessagePositionBottom) {
        // Bottom constraint is used for animating the message in the bottom position.
        self.bottomConstraint = [NSLayoutConstraint constraintWithItem:messageView
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:parentView
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1
                                                              constant:messageView.bounds.size.height];

        self.bottomConstraint.active = YES;
    }

    /**
     * Any internal method calls for dynamically adding or removing constraints
     * should be done from within this block.
     */
    __weak UAInAppMessageControllerDefaultDelegate *weakSelf = self;
    self.updateLayoutConstraintsBlock = ^{
        UAInAppMessageControllerDefaultDelegate *strongSelf = weakSelf;

        // Update size class constraints
        [strongSelf updateSizeClassConstraints:parentView messageView:messageView];
    };

    self.updateLayoutConstraintsBlock();

    return messageView;
}

- (void)updateSizeClassConstraints:(UIView *)parentView messageView:(UIView *)messageView {

    // Get the current horizontal size class
    UIUserInterfaceSizeClass horizontalSizeClass = [UAUtils mainWindow].traitCollection.horizontalSizeClass;
    // If there has been no orientation change, return early
    if (horizontalSizeClass == self.lastHorizontalSizeClass) {
        return;
    }

    self.lastHorizontalSizeClass = horizontalSizeClass;

    if (self.lastHorizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        // Unlike constants, multiplier changes require recreating the constraint
        [NSLayoutConstraint constraintWithItem:messageView
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:parentView
                                     attribute:NSLayoutAttributeWidth
                                    multiplier:kUAInAppMessageiPhoneScreenWidthPercentage
                                      constant:0].active = YES;
    } else if (self.lastHorizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        // Unlike constants, multiplier changes require recreating the constraint
      [NSLayoutConstraint constraintWithItem:messageView
                                   attribute:NSLayoutAttributeWidth
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:parentView
                                   attribute:NSLayoutAttributeWidth
                                  multiplier:kUAInAppMessagePadScreenWidthPercentage
                                    constant:0].active = YES;
    }

    [parentView layoutIfNeeded];
    [messageView layoutIfNeeded];
}

- (UIControl *)messageView:(UIView *)messageView buttonAtIndex:(NSUInteger)index {
    UAInAppMessageView *uaMessageView = (UAInAppMessageView *)messageView;

    // Index 0 corresponds to button 1, index 1 corresponds to button 2.
    if (index == 0) {
        return uaMessageView.button1;
    } else {
        return uaMessageView.button2;
    }
}

- (void)messageView:(UIView *)messageView didChangeTouchState:(BOOL)touchDown {
    UAInAppMessageView *uaMessageView = (UAInAppMessageView *)messageView;

    // If YES invert the primary and secondary colors, otherwise uninvert.
    if (touchDown) {
        [self invertColorsWithMessageView:uaMessageView];
    } else {
        [self uninvertColorsWithMessageView:uaMessageView];
    }
}

- (void)messageView:(UIView *)messageView animateInWithParentView:(UIView *)parentView completionHandler:(void (^)(void))completionHandler {
    if (self.position == UAInAppMessagePositionTop) {
        self.topConstraint.constant = 0;
    } else if (self.position == UAInAppMessagePositionBottom) {
        self.bottomConstraint.constant = 0;
    }

    [UIView animateWithDuration:kUAInAppMessageAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [parentView layoutIfNeeded];
        [messageView layoutIfNeeded];
    } completion:^(BOOL finished) {
        completionHandler();
    }];
}

- (void)messageView:(UIView *)messageView animateOutWithParentView:(UIView *)parentView completionHandler:(void (^)(void))completionHandler {

    if (self.position == UAInAppMessagePositionTop) {
        self.topConstraint.constant = -messageView.bounds.size.height;
    } else if (self.position == UAInAppMessagePositionBottom) {
        self.bottomConstraint.constant = messageView.bounds.size.height;
    }

    [UIView animateWithDuration:kUAInAppMessageAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [parentView layoutIfNeeded];
        [messageView layoutIfNeeded];
    } completion:^(BOOL finished){
        completionHandler();
    }];
}

@end
