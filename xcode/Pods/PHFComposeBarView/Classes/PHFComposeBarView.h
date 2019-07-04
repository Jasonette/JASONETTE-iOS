#import <UIKit/UIKit.h>


// Height of the view when text view is empty. Ideally, you should use this in
// -initWithFrame:.
extern CGFloat const PHFComposeBarViewInitialHeight;


// Each notification includes the view as object and a userInfo dictionary
// containing the beginning and ending view frame. Animation key/value pairs are
// only available for the PHFComposeBarViewWillChangeFrameNotification
// notification.
extern NSString *const PHFComposeBarViewDidChangeFrameNotification;
extern NSString *const PHFComposeBarViewWillChangeFrameNotification;

extern NSString *const PHFComposeBarViewAnimationDurationUserInfoKey; // NSNumber of double
extern NSString *const PHFComposeBarViewAnimationCurveUserInfoKey;    // NSNumber of NSUInteger (UIViewAnimationCurve)
extern NSString *const PHFComposeBarViewFrameBeginUserInfoKey;        // NSValue of CGRect
extern NSString *const PHFComposeBarViewFrameEndUserInfoKey;          // NSValue of CGRect


@protocol PHFComposeBarViewDelegate;


@interface PHFComposeBarView : UIView <UITextViewDelegate>

// Default is YES. When YES, the auto resizing top margin will be flexible.
// Whenever the height changes due to text length, the top offset will
// automatically be adjusted such that the view grows upwards while the bottom
// stays fixed. When NO, the top margin is not flexible. This causes the view to
// grow downwards when the height changes due to the text length. Turning this
// off can be useful in some complicated view setups.
@property (assign, nonatomic) BOOL autoAdjustTopOffset;

@property (strong, nonatomic, readonly) UIButton *button;

// Default is a blue matching that from iMessage (RGB: 0, 122, 255).
@property (strong, nonatomic) UIColor *buttonTintColor UI_APPEARANCE_SELECTOR;

// Default is "Send".
@property (strong, nonatomic) NSString *buttonTitle UI_APPEARANCE_SELECTOR;

@property (weak, nonatomic) id <PHFComposeBarViewDelegate> delegate;

// When set to NO, the text view, the utility button, and the main button are
// disabled.
@property (assign, nonatomic, getter=isEnabled) BOOL enabled;

// Default is 0. When not 0, a counter is shown in the format
// count/maxCharCount. It is placed behind the main button but with a fixed top
// margin, thus only visible if there are at least two lines of text.
@property (assign, nonatomic) NSUInteger maxCharCount;

// Default is 200.0.
@property (assign, nonatomic) CGFloat maxHeight;

// Default is 9. Merely a conversion from maxHeight property.
@property (assign, nonatomic) CGFloat maxLinesCount;

// Default is nil. This is a shortcut for the text property of placeholderLabel.
@property (strong, nonatomic) NSString *placeholder UI_APPEARANCE_SELECTOR;

@property (nonatomic, readonly) UILabel *placeholderLabel;

// Default is nil. This is a shortcut for the text property of textView. Setting
// the text can be animated by using the -setText:animated: method.
@property (strong, nonatomic) NSString *text;

@property (strong, nonatomic, readonly) UITextView *textView;

@property (strong, nonatomic, readonly) UIButton *utilityButton;

// Default is nil. Images should be white on transparent background. The side
// length should not exceed 16 points. The button is only visible when an image
// is set. Thus, to hide the button, set this property to nil.
@property (strong, nonatomic) UIImage *utilityButtonImage UI_APPEARANCE_SELECTOR;

- (void)setText:(NSString *)text animated:(BOOL)animated;

@end


@protocol PHFComposeBarViewDelegate <NSObject, UITextViewDelegate>

@optional
- (void)composeBarViewDidPressButton:(PHFComposeBarView *)composeBarView;
- (void)composeBarViewDidPressUtilityButton:(PHFComposeBarView *)composeBarView;
- (void)composeBarView:(PHFComposeBarView *)composeBarView
   willChangeFromFrame:(CGRect)startFrame
               toFrame:(CGRect)endFrame
              duration:(NSTimeInterval)duration
        animationCurve:(UIViewAnimationCurve)animationCurve;
- (void)composeBarView:(PHFComposeBarView *)composeBarView
    didChangeFromFrame:(CGRect)startFrame
               toFrame:(CGRect)endFrame;

@end
