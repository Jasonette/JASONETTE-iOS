/* Copyright 2017 Urban Airship and Contributors */

#import "UARateAppPromptViewController+Internal.h"
#import "UAUtils.h"

@interface UARateAppPromptViewController ()

// shadow radius of 3 points
#define kUARateAppPromptViewShadowRadius 3

// 25% shadow opacity
#define kUARateAppPromptViewShadowOpacity 0.25

#define kUARateAppPromptViewCornerRadius 20

// UARateAppPromptView nib name
#define kUARateAppPromptViewNibName @"UARateAppPromptView"

@property (strong, nonatomic) void (^completionHandler)(BOOL dismissed);

@property (strong, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UIView *promptContainerView;

@property (weak, nonatomic) IBOutlet UIView *promptBackgroundView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *blurView;

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIButton *rateButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@property (weak, nonatomic) IBOutlet UIView *iconBottonSpaceView;

@property (strong, nonatomic) NSString *promptDescription;
@property (strong, nonatomic) NSString *promptHeader;

@end

@implementation UARateAppPromptViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }

    return self;
}

-(void)displayWithHeader:(NSString *)header description:(NSString *)description completionHandler:(void (^)(BOOL dismissed))completionHandler  {
    self.promptHeader = header;
    self.promptDescription = description;

    self.completionHandler = completionHandler;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topController = [UAUtils topController];
        self.popoverPresentationController.sourceView = topController.view;

        [topController presentViewController:self animated:YES completion:^{

        }];
    });
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self animateIn];
}

- (void) animateIn {
    self.promptContainerView.alpha = 0;
    self.shadowView.alpha = 0;
    self.promptBackgroundView.alpha = 0;
    self.promptContainerView.transform = CGAffineTransformMakeScale(1.2, 1.2);

    [UIView animateWithDuration:0.2 delay:0.4 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.shadowView.alpha = kUARateAppPromptViewShadowOpacity;
        self.promptContainerView.alpha = 1;
        self.promptBackgroundView.alpha = 0.90;
        self.promptContainerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){

    }];
}

- (void)animateOut:(void (^)(void))completion {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.shadowView.alpha = 0;
        self.promptContainerView.alpha = 0;
        self.promptBackgroundView.alpha = 0;
        self.promptContainerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished){
        [self dismissViewControllerAnimated:NO completion:nil];
        completion();
    }];
}

- (IBAction)dismissButtonTapped:(id)sender {
    [self animateOut:^{
        self.completionHandler(YES);
    }];

}

- (IBAction)rateButtonTapped:(id)sender {
    [self animateOut:^{
        self.completionHandler(NO);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImage *appIcon =  [UIImage imageNamed:@"AppIcon60x60"];

    if (appIcon == nil) {
        // Collapses view and falls back to lower priority constraints
        [self.iconImageView removeFromSuperview];
        [self.iconBottonSpaceView removeFromSuperview];
    }

    self.iconImageView.image = appIcon;

    self.promptContainerView.layer.masksToBounds = YES;
    self.promptBackgroundView.layer.masksToBounds = YES;

    self.promptContainerView.layer.cornerRadius = kUARateAppPromptViewCornerRadius;
    self.promptBackgroundView.layer.cornerRadius = kUARateAppPromptViewCornerRadius;

    self.promptBackgroundView.layer.shadowOffset = CGSizeMake(0, 10);
    self.promptBackgroundView.layer.shadowRadius = kUARateAppPromptViewShadowRadius;
    self.promptBackgroundView.layer.shadowOpacity = kUARateAppPromptViewShadowOpacity;

    if (self.promptHeader) {
        self.headerLabel.text = self.promptHeader;
    }

    if (self.promptDescription) {
        self.descriptionLabel.text = self.promptDescription;
    }
}

@end
