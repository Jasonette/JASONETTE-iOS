#import <QuartzCore/QuartzCore.h>
#import <PHFDelegateChain/PHFDelegateChain.h>
#import "PHFComposeBarView.h"
#import "PHFComposeBarView_TextView.h"
#import "PHFComposeBarView_Button.h"


CGFloat const PHFComposeBarViewInitialHeight = 44.0f;


NSString *const PHFComposeBarViewDidChangeFrameNotification  = @"PHFComposeBarViewDidChangeFrame";
NSString *const PHFComposeBarViewWillChangeFrameNotification = @"PHFComposeBarViewWillChangeFrame";

NSString *const PHFComposeBarViewFrameBeginUserInfoKey        = @"PHFComposeBarViewFrameBegin";
NSString *const PHFComposeBarViewFrameEndUserInfoKey          = @"PHFComposeBarViewFrameEnd";
NSString *const PHFComposeBarViewAnimationDurationUserInfoKey = @"PHFComposeBarViewAnimationDuration";
NSString *const PHFComposeBarViewAnimationCurveUserInfoKey    = @"PHFComposeBarViewAnimationCurve";


CGFloat const kHorizontalSpacing          =  8.0f;
CGFloat const kFontSize                   = 17.0f;
CGFloat const kTextContainerTopMargin     =  8.0f;
CGFloat const kTextContainerBottomMargin  =  8.0f;
CGFloat const kTextContainerLeftPadding   =  3.0f;
CGFloat const kTextContainerRightPadding  =  2.0f;
CGFloat const kTextContainerTopPadding    =  4.0f;
CGFloat const kTextContainerCornerRadius  = 5.25f;
CGFloat const kTextViewTopMargin          = -8.0f;
CGFloat const kPlaceholderHeight          = 25.0f;
CGFloat const kPlaceholderSideMargin      =  8.0f;
CGFloat const kPlaceholderTopMargin       =  2.0f;
CGFloat const kButtonHeight               = 26.0f;
CGFloat const kButtonTouchableOverlap     =  6.0f;
CGFloat const kButtonRightMargin          = -2.0f;
CGFloat const kButtonBottomMargin         =  8.0f;
CGFloat const kUtilityButtonWidth         = 25.0f;
CGFloat const kUtilityButtonHeight        = 25.0f;
CGFloat const kUtilityButtonBottomMargin  =  9.0f;
CGFloat const kCaretYOffset               =  7.0f;
CGFloat const kCharCountFontSize          = 11.0f;
CGFloat const kCharCountTopMargin         = 15.0f;


UIViewAnimationCurve const kResizeAnimationCurve = UIViewAnimationCurveEaseInOut;
UIViewAnimationOptions const kResizeAnimationOptions = UIViewAnimationOptionCurveEaseInOut;
NSTimeInterval const kResizeAnimationDuration = 0.25;


// Calculated at runtime:
static CGFloat kTextViewLineHeight;
static CGFloat kTextViewFirstLineHeight;
static CGFloat kTextViewToSuperviewHeightDelta;


@interface PHFComposeBarView ()
@property (strong, nonatomic, readonly) UIToolbar *backgroundView;
@property (strong, nonatomic, readonly) UIView *topLineView;
@property (strong, nonatomic, readonly) UILabel *charCountLabel;
@property (strong, nonatomic) PHFDelegateChain *delegateChain;
@property (strong, nonatomic, readonly) UIButton *textContainer;
@property (assign, nonatomic) CGFloat previousTextHeight;
@end


@implementation PHFComposeBarView

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    [self calculateRuntimeConstants];
    [self setup];

    return self;
}

- (void)awakeFromNib
{
  [super awakeFromNib];

  [self calculateRuntimeConstants];
  [self setup];
}

- (BOOL)becomeFirstResponder {
    return [[self textView] becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return [[self textView] canBecomeFirstResponder];
}

- (BOOL)isFirstResponder {
    return [[self textView] isFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [[self textView] resignFirstResponder];
}

- (void)didMoveToSuperview {
    // Disabling the button before insertion into view will cause it to look
    // disabled but it will in fact still be tappable. To work around this
    // issue, update the enabled state once inserted into view.
    [self updateButtonEnabled];
    [self resizeTextViewIfNeededAnimated:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // Correct top line size:
    CGRect topLineViewFrame = [[self topLineView] frame];
    topLineViewFrame.size.height = 0.5f;
    [[self topLineView] setFrame:topLineViewFrame];

    // Correct background view position:
    CGRect backgroundViewFrame = [[self backgroundView] frame];
    backgroundViewFrame.size.height = [self bounds].size.height;
    backgroundViewFrame.origin.y = 0.5f;
    [[self backgroundView] setFrame:backgroundViewFrame];

    [self updateCharCountLabel];
    [self resizeTextViewIfNeededAnimated:NO];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self handleTextViewChangeAnimated:NO];
}

#pragma mark - Public Properties

- (void)setAutoAdjustTopOffset:(BOOL)autoAdjustTopOffset {
    if (_autoAdjustTopOffset != autoAdjustTopOffset) {
        _autoAdjustTopOffset = autoAdjustTopOffset;

        UIViewAutoresizing autoresizingMask = [self autoresizingMask];

        if (autoAdjustTopOffset)
            autoresizingMask |= UIViewAutoresizingFlexibleTopMargin;
        else
            autoresizingMask ^= UIViewAutoresizingFlexibleTopMargin;

        [self setAutoresizingMask:autoresizingMask];
    }
}

- (UIColor *)buttonTintColor {
    return [[self button] titleColorForState:UIControlStateNormal];
}

- (void)setButtonTintColor:(UIColor *)color {
    [[self button] setTitleColor:color forState:UIControlStateNormal];
}

@synthesize buttonTitle = _buttonTitle;
- (NSString *)buttonTitle {
    if (!_buttonTitle)
        _buttonTitle = NSLocalizedStringWithDefaultValue(@"Button Title",
                                                        nil,
                                                        [NSBundle bundleForClass:[self class]],
                                                        @"Send",
                                                        @"The default value for the main button");

    return _buttonTitle;
}

- (void)setButtonTitle:(NSString *)buttonTitle {
    if (_buttonTitle != buttonTitle) {
        _buttonTitle = buttonTitle;
        [[self button] setTitle:buttonTitle forState:UIControlStateNormal];
        [self resizeButton];
    }
}

@synthesize delegate = _delegate;
- (void)setDelegate:(id<PHFComposeBarViewDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
        [self setupDelegateChainForTextView];
    }
}

@synthesize enabled = _enabled;
- (void)setEnabled:(BOOL)enabled {
    if (enabled != _enabled) {
        _enabled = enabled;
        [[self textView] setEditable:enabled];
        [self updateButtonEnabled];
        [[self utilityButton] setEnabled:enabled];
    }
}

@synthesize maxCharCount = _maxCharCount;
- (void)setMaxCharCount:(NSUInteger)count {
    if (_maxCharCount != count) {
        _maxCharCount = count;
        [self updateCharCountLabel];
    }
}

@synthesize maxHeight = _maxHeight;
- (void)setMaxHeight:(CGFloat)maxHeight {
    _maxHeight = maxHeight;
    [self resizeTextViewIfNeededAnimated:YES];
    [self scrollToCaretIfNeeded];
}

- (CGFloat)maxLinesCount {
    CGFloat maxTextHeight = [self maxHeight] - PHFComposeBarViewInitialHeight + kTextViewLineHeight;
    return maxTextHeight / kTextViewLineHeight;
}

- (void)setMaxLinesCount:(CGFloat)maxLinesCount {
    CGFloat maxTextHeight = maxLinesCount * kTextViewLineHeight;
    CGFloat maxHeight     = maxTextHeight - kTextViewLineHeight + PHFComposeBarViewInitialHeight;
    [self setMaxHeight:maxHeight];
}

- (NSString *)placeholder {
    return [[self placeholderLabel] text];
}

- (void)setPlaceholder:(NSString *)placeholder {
    [[self placeholderLabel] setText:placeholder];
}

- (NSString *)text {
    return [[self textView] text];
}

- (void)setText:(NSString *)text {
    [self setText:text animated:YES];
}

- (UIImage *)utilityButtonImage {
    return [[self utilityButton] imageForState:UIControlStateNormal];
}

- (void)setUtilityButtonImage:(UIImage *)image {
    [[self utilityButton] setImage:image forState:UIControlStateNormal];
    [self updateUtilityButtonVisibility];
}

#pragma mark - Public Methods

- (void)setText:(NSString *)text animated:(BOOL)animated {
    [[self textView] setText:text];
    [self handleTextViewChangeAnimated:animated];
}

#pragma mark - Internal Properties

// The top line is placed below the background view in order to brighten the
// background view's border slightly to match the one from Messages.app.
@synthesize topLineView = _topLineView;
- (UIView *)topLineView {
    if (!_topLineView) {
        CGRect frame = [self bounds];
        frame.size.height = 0.5f;
        _topLineView = [[UIView alloc] initWithFrame:frame];
        [_topLineView setBackgroundColor:[UIColor colorWithWhite:0.98f alpha:1.0f]];
        [_topLineView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    }

    return _topLineView;
}

@synthesize backgroundView = _backgroundView;
- (UIToolbar *)backgroundView {
    if (!_backgroundView) {
        CGRect frame = [self bounds];
        frame.origin.y = 0.5f;
        _backgroundView = [[UIToolbar alloc] initWithFrame:frame];
        [_backgroundView setBarStyle:UIBarStyleDefault];
        [_backgroundView setTranslucent:YES];
        [_backgroundView setTintColor:[UIColor whiteColor]];
        [_backgroundView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    }

    return _backgroundView;
}

@synthesize button = _button;
- (UIButton *)button {
    if (!_button) {
        _button = [PHFComposeBarView_Button buttonWithType:UIButtonTypeCustom];
        CGRect frame = CGRectMake([self bounds].size.width - kHorizontalSpacing - kButtonRightMargin - kButtonTouchableOverlap,
                                  [self bounds].size.height - kButtonBottomMargin - kButtonHeight,
                                  2 * kButtonTouchableOverlap,
                                  kButtonHeight);
        [_button setFrame:frame];
        [_button setTitleEdgeInsets:UIEdgeInsetsMake(0.5f, 0, 0, 0)];
        [_button setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin];
        [_button setTitle:[self buttonTitle] forState:UIControlStateNormal];

        UIColor *disabledColor = [UIColor colorWithHue:240.0f/360.0f saturation:0.03f brightness:0.58f alpha:1.0f];
        [_button setTitleColor:disabledColor forState:UIControlStateDisabled];
        UIColor *enabledColor = [UIColor colorWithHue:211.0f/360.0f saturation:1.0f brightness:1.0f alpha:1.0f];
        [_button setTitleColor:enabledColor forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(didPressButton) forControlEvents:UIControlEventTouchUpInside];

        UILabel *label = [_button titleLabel];
        [label setFont:[UIFont boldSystemFontOfSize:kFontSize]];
    }

    return _button;
}

@synthesize charCountLabel = _charCountLabel;
- (UILabel *)charCountLabel {
    if (!_charCountLabel) {
        CGRect frame = CGRectMake(0,
                                  kCharCountTopMargin,
                                  [self bounds].size.width - 8.0f,
                                  20.0f);
        _charCountLabel = [[UILabel alloc] initWithFrame:frame];
        [_charCountLabel setHidden:![self maxCharCount]];
        [_charCountLabel setTextAlignment:NSTextAlignmentRight];
        [_charCountLabel setFont:[UIFont systemFontOfSize:kCharCountFontSize]];
        UIColor *color = [UIColor colorWithHue:240.0f/360.0f saturation:0.02f brightness:0.8f alpha:1.0f];
        [_charCountLabel setTextColor:color];
        [_charCountLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    }

    return _charCountLabel;
}

@synthesize textContainer = _textContainer;
// Returns the text container which contains the actual text view, the
// placeholder and the image view that contains the text field image.
- (UIButton *)textContainer {
    if (!_textContainer) {
        CGRect textContainerFrame = CGRectMake(kHorizontalSpacing,
                                               kTextContainerTopMargin,
                                               [self bounds].size.width - kHorizontalSpacing * 3 - kButtonRightMargin,
                                               [self bounds].size.height - kTextContainerTopMargin - kTextContainerBottomMargin);
        _textContainer = [UIButton buttonWithType:UIButtonTypeCustom];
        [_textContainer setFrame:textContainerFrame];
        [_textContainer setClipsToBounds:YES];
        [_textContainer setBackgroundColor:[UIColor colorWithWhite:0.98f alpha:1.0f]];
        [_textContainer setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];

        CALayer *layer = [_textContainer layer];
        UIColor *borderColor = [UIColor colorWithHue:240.0f/360.0f saturation:0.02f brightness:0.8f alpha:1.0f];
        [layer setBorderColor:[borderColor CGColor]];
        [layer setBorderWidth:0.5f];
        [layer setCornerRadius:kTextContainerCornerRadius];

        CGFloat textHeight = [self textHeight];
        [self setPreviousTextHeight:textHeight];

        CGRect textViewFrame = textContainerFrame;
        textViewFrame.origin.x = kTextContainerLeftPadding;
        textViewFrame.origin.y = kTextContainerTopPadding + kTextViewTopMargin;
        textViewFrame.size.width -= kTextContainerLeftPadding + kTextContainerRightPadding;
        textViewFrame.size.height = textHeight;

        [[self textView] setFrame:textViewFrame];
        [_textContainer addSubview:[self textView]];

        CGRect placeholderFrame = CGRectMake(kPlaceholderSideMargin,
                                             kPlaceholderTopMargin,
                                             textContainerFrame.size.width - 2 * kPlaceholderSideMargin,
                                             kPlaceholderHeight);
        [[self placeholderLabel] setFrame:placeholderFrame];
        [_textContainer addSubview:[self placeholderLabel]];

        [_textContainer addTarget:[self textView] action:@selector(becomeFirstResponder) forControlEvents:UIControlEventTouchUpInside];
    }

    return _textContainer;
}

@synthesize textView = _textView;
- (UITextView *)textView {
    if (!_textView) {
        _textView = [[PHFComposeBarView_TextView alloc] initWithFrame:CGRectZero];
        [_textView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_textView setScrollIndicatorInsets:UIEdgeInsetsMake(8.0f, 0.0f, 8.0f, 0.5f)];
        [_textView setBackgroundColor:[UIColor clearColor]];
        [_textView setFont:[UIFont systemFontOfSize:kFontSize]];
        [self setupDelegateChainForTextView];
    }

    return _textView;
}

@synthesize placeholderLabel = _placeholderLabel;
- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_placeholderLabel setBackgroundColor:[UIColor clearColor]];
        [_placeholderLabel setUserInteractionEnabled:NO];
        [_placeholderLabel setFont:[UIFont systemFontOfSize:kFontSize]];
        [_placeholderLabel setTextColor:[UIColor colorWithHue:240.0f/360.0f saturation:0.02f brightness:0.8f alpha:1.0f]];
        [_placeholderLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_placeholderLabel setAdjustsFontSizeToFitWidth:YES];
        [_placeholderLabel setMinimumScaleFactor:[UIFont smallSystemFontSize]/kFontSize];
    }

    return _placeholderLabel;
}

@synthesize previousTextHeight = _previousTextHeight;
- (CGFloat)previousTextHeight {
    if (!_previousTextHeight)
        _previousTextHeight = [self bounds].size.height;

    return _previousTextHeight;
}

@synthesize utilityButton = _utilityButton;
- (UIButton *)utilityButton {
    if (!_utilityButton) {
        _utilityButton = [PHFComposeBarView_Button buttonWithType:UIButtonTypeCustom];
        [_utilityButton setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin];
        [_utilityButton setFrame:CGRectMake(0.0f,
                                            [self bounds].size.height - kUtilityButtonHeight - kUtilityButtonBottomMargin,
                                            kUtilityButtonWidth,
                                            kUtilityButtonHeight)];
        [_utilityButton addTarget:self action:@selector(didPressUtilityButton) forControlEvents:UIControlEventTouchUpInside];
    }

    return _utilityButton;
}

#pragma mark - Helpers

- (void)calculateRuntimeConstants {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kTextViewFirstLineHeight = [self textHeight];
        [[self textView] setText:@"\n"];
        kTextViewLineHeight = [self textHeight] - kTextViewFirstLineHeight;
        [[self textView] setText:@""];
        kTextViewToSuperviewHeightDelta = ceilf(PHFComposeBarViewInitialHeight - kTextViewFirstLineHeight);
    });
}

- (void)didPressButton {
    if ([[self delegate] respondsToSelector:@selector(composeBarViewDidPressButton:)])
        [[self delegate] composeBarViewDidPressButton:self];
}

- (void)didPressUtilityButton {
    if ([[self delegate] respondsToSelector:@selector(composeBarViewDidPressUtilityButton:)])
        [[self delegate] composeBarViewDidPressUtilityButton:self];
}

- (void)updatePlaceholderVisibility {
    BOOL shouldHide = ![[[self textView] text] isEqualToString:@""];
    [[self placeholderLabel] setHidden:shouldHide];
}

- (void)postNotification:(NSString *)name userInfo:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                        object:self
                                                      userInfo:userInfo];
}

// 1. Several cases need to be distinguished when text is added:
//    a) line count is below max and lines are added such that the max threshold
//       is not exceeded
//    b) same as previous, but max threshold is exceeded
//    c) line count is over or at max and one or several lines are added
// 2. Same goes for the other way around, when text is removed:
//    a) line count is <= max and lines are removed
//    b) line count is above max and lines are removed such that the lines count
//       get below max-1
//    c) same as previous, but line count at the end is >= max
- (void)resizeTextViewIfNeededAnimated:(BOOL)animated {
    // Only resize if we're placed in a view. Resizing will be done once inside
    // a view.
    if (![self superview])
        return;

    CGFloat textHeight         = [self textHeight];
    CGFloat maxViewHeight      = [self maxHeight];
    CGFloat previousTextHeight = [self previousTextHeight];
    CGFloat textHeightDelta    = textHeight - previousTextHeight;

    // NOTE: Continue even if the actual view height won't change because of max
    //       or min height constraints in order to ensure the correct content
    //       offset when a text line is added or removed.
    if (textHeightDelta == 0.0f && [self bounds].size.height == maxViewHeight)
        return;

    [self setPreviousTextHeight:textHeight];
    CGFloat newViewHeight =
        MAX(
            MIN(textHeight + kTextViewToSuperviewHeightDelta, maxViewHeight),
            PHFComposeBarViewInitialHeight
        );
    CGFloat viewHeightDelta = newViewHeight - [self bounds].size.height;

    if (viewHeightDelta) {
        CGFloat animationDurationFactor = animated ? 1.0f : 0.0f;

        CGRect frameBegin     = [self frame];
        CGRect frameEnd       = frameBegin;
        frameEnd.size.height += viewHeightDelta;
        if ([self autoAdjustTopOffset])
            frameEnd.origin.y -= viewHeightDelta;

        void (^animation)(void) = ^{
            [self setFrame:frameEnd];
        };

        NSTimeInterval animationDuration = kResizeAnimationDuration * animationDurationFactor;

        NSDictionary *willChangeUserInfo = @{
            PHFComposeBarViewFrameBeginUserInfoKey        : [NSValue valueWithCGRect:frameBegin],
            PHFComposeBarViewFrameEndUserInfoKey          : [NSValue valueWithCGRect:frameEnd],
            PHFComposeBarViewAnimationDurationUserInfoKey : @(animationDuration),
            PHFComposeBarViewAnimationCurveUserInfoKey    : [NSNumber numberWithInt:kResizeAnimationCurve]
        };

        NSDictionary *didChangeUserInfo = @{
            PHFComposeBarViewFrameBeginUserInfoKey        : [NSValue valueWithCGRect:frameBegin],
            PHFComposeBarViewFrameEndUserInfoKey          : [NSValue valueWithCGRect:frameEnd],
        };

        void (^afterAnimation)(BOOL) = ^(BOOL finished){
            [self postNotification:PHFComposeBarViewDidChangeFrameNotification userInfo:didChangeUserInfo];
            if ([[self delegate] respondsToSelector:@selector(composeBarView:didChangeFromFrame:toFrame:)])
                [[self delegate] composeBarView:self
                             didChangeFromFrame:frameBegin
                                        toFrame:frameEnd];
        };

        [self postNotification:PHFComposeBarViewWillChangeFrameNotification userInfo:willChangeUserInfo];
        if ([[self delegate] respondsToSelector:@selector(composeBarView:willChangeFromFrame:toFrame:duration:animationCurve:)])
            [[self delegate] composeBarView:self
                        willChangeFromFrame:frameBegin
                                    toFrame:frameEnd
                                   duration:animationDuration
                             animationCurve:kResizeAnimationCurve];

        if (animated) {
            [UIView animateWithDuration:kResizeAnimationDuration * animationDurationFactor
                                  delay:0.0
                                options:kResizeAnimationOptions
                             animations:animation
                             completion:afterAnimation];
        } else {
            animation();
            afterAnimation(YES);
        }
    }
}

- (void)resizeButton {
    CGRect previousButtonFrame = [[self button] frame];
    CGRect newButtonFrame = previousButtonFrame;
    CGRect textContainerFrame = [[self textContainer] frame];
    CGRect charCountLabelFrame = [[self charCountLabel] frame];

    [[self button] sizeToFit];
    CGFloat widthDelta = [[self button] bounds].size.width + 2 * kButtonTouchableOverlap - previousButtonFrame.size.width;

    newButtonFrame.size.width += widthDelta;
    newButtonFrame.origin.x -= widthDelta;
    [[self button] setFrame:newButtonFrame];

    textContainerFrame.size.width -= widthDelta;
    [[self textContainer] setFrame:textContainerFrame];

    charCountLabelFrame.origin.x = textContainerFrame.origin.x + textContainerFrame.size.width;
    charCountLabelFrame.size.width = [self bounds].size.width - charCountLabelFrame.origin.x - kHorizontalSpacing;
    [[self charCountLabel] setFrame:charCountLabelFrame];
}

- (void)scrollToCaretIfNeeded {
    if (![self superview])
        return;

    UITextRange *selectedTextRange = [[self textView] selectedTextRange];
    if ([selectedTextRange isEmpty]) {
        UITextPosition *position = [selectedTextRange start];
        CGPoint offset = [[self textView] contentOffset];
        CGFloat relativeCaretY = [[self textView] caretRectForPosition:position].origin.y - offset.y - kCaretYOffset;
        CGFloat offsetYDelta = 0.0f;
        // Caret is above visible part of text view:
        if (relativeCaretY < 0.0f) {
            offsetYDelta = relativeCaretY;
        }
        // Caret is in or below visible part of text view:
        else if (relativeCaretY > 0.0f) {
            CGFloat maxY = [self bounds].size.height - PHFComposeBarViewInitialHeight;
            // Caret is below visible part of text view:
            if (relativeCaretY > maxY)
                offsetYDelta = relativeCaretY - maxY;
        }

        if (offsetYDelta) {
            offset.y += offsetYDelta;
            [(PHFComposeBarView_TextView *)[self textView] PHFComposeBarView_setContentOffset:offset];
        }
    }
}

- (void)setup {
    _autoAdjustTopOffset = YES;
    _enabled = YES;
    _maxHeight = 200.0f;

    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];

    [self addSubview:[self topLineView]];
    [self addSubview:[self backgroundView]];
    [self addSubview:[self charCountLabel]];
    [self addSubview:[self button]];
    [self addSubview:[self textContainer]];

    [self resizeButton];
}

- (void)setupDelegateChainForTextView {
    PHFDelegateChain *delegateChain = [PHFDelegateChain delegateChainWithObjects:self, [self delegate], nil];
    [self setDelegateChain:delegateChain];
    [[self textView] setDelegate:(id<UITextViewDelegate>)delegateChain];
}

- (CGFloat)textHeight {
    UITextView *textView = [self textView];
    CGFloat height = [textView sizeThatFits:CGSizeMake([textView frame].size.width, FLT_MAX)].height;

    return ceilf(height);
}

- (void)updateButtonEnabled {
    BOOL enabled = [self isEnabled] && [[[self textView] text] length] > 0;
    [[self button] setEnabled:enabled];
}

- (void)updateCharCountLabel {
    BOOL isHidden = (_maxCharCount == 0) || [self textHeight] == kTextViewFirstLineHeight;
    [[self charCountLabel] setHidden:isHidden];

    if (!isHidden) {
        NSUInteger count = [[[[self textView] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];
        NSString *text = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)count, (unsigned long)[self maxCharCount]];
        [[self charCountLabel] setText:text];
    }
}

- (void)updateUtilityButtonVisibility {
    if ([self utilityButtonImage] && ![[self utilityButton] superview]) {
        [self shifTextFieldInDirection:+1];
        [self insertUtilityButton];
    } else if (![self utilityButtonImage] && [[self utilityButton] superview]) {
        [self shifTextFieldInDirection:-1];
        [self removeUtilityButton];
    }
}

// +1 shifts to the right, -1 to the left.
- (void)shifTextFieldInDirection:(NSInteger)direction {
    CGRect textContainerFrame = [[self textContainer] frame];
    textContainerFrame.size.width -= direction * (kUtilityButtonWidth + kHorizontalSpacing);
    textContainerFrame.origin.x   += direction * (kUtilityButtonWidth + kHorizontalSpacing);
    [[self textContainer] setFrame:textContainerFrame];
}

- (void)insertUtilityButton {
    UIButton *utilityButton = [self utilityButton];
    CGRect utilityButtonFrame = [utilityButton frame];
    utilityButtonFrame.origin.x = kHorizontalSpacing;
    utilityButtonFrame.origin.y = [self frame].size.height - kUtilityButtonHeight - kUtilityButtonBottomMargin;
    [utilityButton setFrame:utilityButtonFrame];
    [self addSubview:utilityButton];
}

- (void)removeUtilityButton {
    [[self utilityButton] removeFromSuperview];
}

- (void)handleTextViewChangeAnimated:(BOOL)animated {
    [self updatePlaceholderVisibility];
    [self resizeTextViewIfNeededAnimated:animated];
    [self scrollToCaretIfNeeded];
    [self updateCharCountLabel];
    [self updateButtonEnabled];
}

@end
