/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UAInAppMessageView+Internal.h"
#import "UAirship.h"

// shadow offset on the y axis of 1 point
#define kUAInAppMessageViewShadowOffsetY 1

// shadow radius of 3 points
#define kUAInAppMessageViewShadowRadius 3

// 25% shadow opacity
#define kUAInAppMessageViewShadowOpacity 0.25

// a corner radius of 4 points
#define kUAInAppMessageViewCornerRadius 4

// UAInAppMessageView nib name
#define kUAInAppMessageViewNibName @"UAInAppMessageView"


@interface UAInAppMessageView ()

@property(strong, nonatomic) IBOutlet UILabel *messageLabel;

@property(strong, nonatomic) IBOutlet UIButton *button1;
@property(strong, nonatomic) IBOutlet UIButton *button2;

// Subviews
@property(strong, nonatomic) IBOutlet UIView *containerView;
@property(strong, nonatomic) IBOutlet UIView *tab;
@property(strong, nonatomic) IBOutlet UIView *maskView;

// Constraints required for dynamic resizing
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *button1TrailingSpace;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *labelToBottom;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *labelToTop;

@end

@implementation UAInAppMessageView

- (instancetype)initWithPosition:(UAInAppMessagePosition)position numberOfButtons:(NSUInteger)numberOfButtons {
    NSString *nibName = kUAInAppMessageViewNibName;
    NSBundle *bundle = [UAirship resources];

    // Top and bottom IAP views are firstObject and lastObject, respectively.
    if (position == UAInAppMessagePositionTop) {
        self = [[bundle loadNibNamed:nibName owner:self options:nil] firstObject];
    } else {
        self = [[bundle loadNibNamed:nibName owner:self options:nil] lastObject];
    }

    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.userInteractionEnabled = YES;

        // Be transparent at the top, in order to facilitate masking of subviews
        self.backgroundColor = [UIColor clearColor];

        // Contains all the meaningful subviews
        self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.containerView.backgroundColor = [UIColor whiteColor];

        // Covers up rounded corners in the appropriate area
        self.maskView.translatesAutoresizingMaskIntoConstraints = NO;
        self.maskView.userInteractionEnabled = NO;
        self.maskView.backgroundColor = [UIColor whiteColor];

        CGFloat shadowOffsetY;

        // If on the bottom, project the shadow on the top edge
        if (position == UAInAppMessagePositionBottom) {
            shadowOffsetY = -kUAInAppMessageViewShadowOffsetY;
        } else {
            // Otherwise project it on the bottom edge
            shadowOffsetY = kUAInAppMessageViewShadowOffsetY;
        }

        // Configure container view
        self.containerView.layer.shadowOffset = CGSizeMake(0, shadowOffsetY);
        self.containerView.layer.shadowRadius = kUAInAppMessageViewShadowRadius;
        self.containerView.layer.shadowOpacity = kUAInAppMessageViewShadowOpacity;
        self.containerView.layer.cornerRadius = 4;

        // Configure label
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.messageLabel.userInteractionEnabled = NO;

        // Configure tab
        self.tab.translatesAutoresizingMaskIntoConstraints = NO;
        self.tab.layer.cornerRadius = 4;
        self.tab.autoresizesSubviews = YES;

        // Configure buttons
        self.button1.hidden = true;
        self.button2.hidden = true;
        self.button1.layer.cornerRadius = 4;
        self.button2.layer.cornerRadius = 4;

        switch (numberOfButtons) {
            case 0:
                self.button1TrailingSpace.priority = UILayoutPriorityDefaultLow;
                self.labelToBottom.priority = UILayoutPriorityRequired;
                self.button1.hidden = true;
                self.button2.hidden = true;
                break;
            case 1:
                self.button1TrailingSpace.priority = UILayoutPriorityRequired;
                self.labelToBottom.priority = UILayoutPriorityDefaultLow;
                self.button1.hidden = false;
                self.button2.hidden = true;
                break;
            case 2:
                self.button1TrailingSpace.priority = UILayoutPriorityDefaultLow;
                self.labelToBottom.priority = UILayoutPriorityDefaultLow;
                self.button1.hidden = false;
                self.button2.hidden = false;
                break;
        }

#if !TARGET_OS_TV   // No status bar in tvOS
        // If the message is at the top, listen for changes to the status bar frame
        if (position == UAInAppMessagePositionTop) {

            [self updateStatusBarConstraints];

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameDidChange:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
        }
#endif
    }

    return self;
}

// When setting the background color, pass through to the
// containerView and maskView, leaving self clear.
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.containerView.backgroundColor = backgroundColor;
    self.maskView.backgroundColor = backgroundColor;
}

#if !TARGET_OS_TV   // No status bar in tvOS
- (void)updateStatusBarConstraints {

    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;

    self.labelToTop.constant = CGRectGetHeight(statusBarFrame) + 3;
}


- (void)statusBarFrameDidChange:(NSNotification *)notification {
    /*
     * Note: iOS 8 appears to have a bug where the status bar geometry isn't updated
     * at the time this notification fires. Delaying the layout update by a runloop
     * iteration is a workaround.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateStatusBarConstraints];
    });
}
#endif

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.onLayoutSubviews) {
        self.onLayoutSubviews();
    }
}

@end
