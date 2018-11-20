/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAInAppMessageControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Default instance of UAInAppMessageControllerDelegate, used internally by UAInAppMessageController
 * to implement default UI and behavior.
 */
@interface UAInAppMessageControllerDefaultDelegate : NSObject<UAInAppMessageControllerDelegate>

///---------------------------------------------------------------------------------------
/// @name In App Message Controller Default Delegate Core Methods
///---------------------------------------------------------------------------------------

/**
 * Initializer for UAInAppMessageControllerDefaultDelegate.
 *
 * @param message The associated in-app message.
 * @return An instance of UAInAppMessageControllerDefaultDelegate.
 */
- (instancetype)initWithMessage:(UAInAppMessage *)message;

/**
 * Builds, lays out, and configures an instance of UAInAppMessageView.
 *
 * @param message The associated in-app message.
 * @param parentView The parent view the UAInAppMessageView will be embedded in.
 * @return The fully configured and laid out instance of UAInAppMessageView.
 */
- (UIView *)viewForMessage:(UAInAppMessage *)message parentView:(UIView *)parentView;

/**
 * Returns the button matching an associated action's index.
 * e.g. for a two-button layout, the first would be index 0, and the second would be index 1.
 *
 * @param messageView The messageView, in this case a UAInAppMessageView.
 * @param index The button's index.
 * @return The UIControl instance corresponding to the action index, in this case "button1" or "button2".
 */
- (UIControl *)messageView:(UIView *)messageView buttonAtIndex:(NSUInteger)index;

/**
 * Handles changes to highlight state by inverting the primary and secondary colors in the message view
 *
 * @param messageView The messageView, in this case a UAInAppMessageView.
 * @param touchDown The touch state. A `YES` will result in inverted primary/secondary colors, whereas
 * a `NO` will result in non-inverted colors.
 */
- (void)messageView:(UIView *)messageView didChangeTouchState:(BOOL)touchDown;

/**
 * Animates the message view onto the screen by temporarliy moving it offscreen, and easing in-out to fit within the top or bottom position
 * over 0.2 seconds. This method does not assume the passed message view is of the UAInAppMessageView class, and so can function as a
 * default for custom views as well.
 *
 * @param messageView The message view to be animated.
 * @param parentView The parent view the message view is embedded in.
 * @param completionHandler A completion handler called when the animation is complete.
 */
- (void)messageView:(UIView *)messageView animateInWithParentView:(UIView *)parentView completionHandler:(void (^)(void))completionHandler;

/**
 * Animates the message view off the screen in the direction it was displayed from, easing in-out over 0.2 seconds.
 *
 * @param messageView The message view to be animated.
 * @param parentView The parent view the message view is embedded in.
 * @param completionHandler A completion handler called when the animation is complete.
 */
- (void)messageView:(UIView *)messageView animateOutWithParentView:(UIView *)parentView completionHandler:(void (^)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
