/*
 Copyright 2017-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#ifdef IS_BAZEL_BUILD
#import "MotionInterchange.h"
#else
#import <MotionInterchange/MotionInterchange.h>
#endif

#import "MDMAnimatableKeyPaths.h"
#import "MDMCoreAnimationTraceable.h"

/**
 An animator adds Core Animation animations to a layer using animation traits.
 */
NS_SWIFT_NAME(MotionAnimator)
@interface MDMMotionAnimator : NSObject <MDMCoreAnimationTraceable>

#pragma mark - Configuring animation behavior

/**
 The scaling factor to apply to all time-related values.

 For example, a timeScaleFactor of 2 will double the length of all animations.

 1.0 by default.
 */
@property(nonatomic, assign) CGFloat timeScaleFactor;

/**
 If enabled, all animations will start from their current presentation value.

 If disabled, animations will start from the first value in the values array.

 Disabled by default.
 */
@property(nonatomic, assign) BOOL beginFromCurrentState;

/**
 If enabled, animations will calculate their values in relation to their destination value.

 Additive animations can be stacked. This is most commonly used to change the destination of an
 animation mid-way through in such a way that momentum appears to be conserved.

 Enabled by default.
 */
@property(nonatomic, assign) BOOL additive;

#pragma mark - Explicitly animating between values

/**
 Adds a single animation to the layer with the given traits structure.

 If `additive` is disabled, the animation will be added to the layer with the keyPath as its key.
 In this case, multiple invocations of this function on the same key path will remove the
 animations added from prior invocations.

 @param traits  The traits to be used for the animation.

 @param layer   The layer to be animated.

 @param values  The values to be used in the animation. Must contain exactly two values. Supported
                UIKit types will be coerced to their Core Animation equivalent. Supported UIKit
                values include UIColor and UIBezierPath.

 @param keyPath The key path of the property to be animated.
 */
- (void)animateWithTraits:(nonnull MDMAnimationTraits *)traits
                  between:(nonnull NSArray *)values
                    layer:(nonnull CALayer *)layer
                  keyPath:(nonnull MDMAnimatableKeyPath)keyPath;

/**
 Adds a single animation to the layer with the given traits structure.

 If `additive` is disabled, the animation will be added to the layer with the keyPath as its key.
 In this case, multiple invocations of this function on the same key path will remove the
 animations added from prior invocations.

 @param traits      The traits to be used for the animation.

 @param layer       The layer to be animated.

 @param values      The values to be used in the animation. Must contain exactly two values.
                    Supported UIKit types will be coerced to their Core Animation equivalent.

 @param keyPath     The key path of the property to be animated.

 @param completion  A block object to be executed when the animation ends or is removed from the
                    animation hierarchy. If the duration of the animation is 0, this block is
                    executed immediately. The block is escaping and will be released once the
                    animations have completed. The provided `finished` argument is currently always
                    YES.
 */
- (void)animateWithTraits:(nonnull MDMAnimationTraits *)traits
                  between:(nonnull NSArray *)values
                    layer:(nonnull CALayer *)layer
                  keyPath:(nonnull MDMAnimatableKeyPath)keyPath
               completion:(nullable void(^)(BOOL finished))completion;

/**
 If enabled, explicitly-provided values will be reversed before animating.

 This property only affects the animateWithTraits:between:... family of methods.

 Disabled by default.
 */
@property(nonatomic, assign) BOOL shouldReverseValues;

#pragma mark - Implicitly animating

/**
 Performs `animations` using the traits provided.

 @param traits      The traits to be used for the animation.

 @param animations  The block to be executed. Any animatable properties changed within this block
                    will result in animations being added to the view's layer with the provided
                    traits. The block is non-escaping.
 */
- (void)animateWithTraits:(nonnull MDMAnimationTraits *)traits
               animations:(nonnull void(^)(void))animations;

/**
 Performs `animations` using the traits provided and executes the completion handler once all added
 animations have completed.

 @param traits      The traits to be used for the animation.

 @param animations  The block to be executed. Any animatable properties changed within this block
                    will result in animations being added to the view's layer with the provided
                    traits. The block is non-escaping.

 @param completion  A block object to be executed once the animation sequence ends or it has been
                    removed from the animation hierarchy. If the duration of the animation is 0,
                    this block is executed immediately. The block is escaping and will be released
                    once the animation sequence has completed. The provided `finished` argument is
                    currently always YES.
 */
- (void)animateWithTraits:(nonnull MDMAnimationTraits *)traits
               animations:(nonnull void (^)(void))animations
               completion:(nullable void(^)(BOOL finished))completion;

#pragma mark - Managing active animations

/**
 Removes every animation added by this animator.

 Removing animations in this manner will give the appearance of each animated layer property
 instantaneously jumping to its animated destination.
 */
- (void)removeAllAnimations;

/**
 Commits the presentation layer value to the model layer value for every active animation's key path
 and then removes every animation.

 This method is most commonly called in reaction to the initiation of a gesture so that any
 in-flight animations are stopped at their current on-screen position.
 */
- (void)stopAllAnimations;

@end

@interface MDMMotionAnimator (UIKitEquivalency)

/**
 Similar to the UIKit method of the same name with some intentional differences in behavior.

 This API does not disable user interaction during animations, unlike the default behavior of
 UIView's similar API.

 Like the UIKit API, this method performs the specified animations immediately using the
 UIViewAnimationOptionCurveEaseInOut animation option.
 
 @param duration   From UIKit's documentation: "The total duration of the animations, measured in
                   seconds. If you specify a negative value or 0, the changes are made without
                   animating them."

 @param animations From UIKit's documentation: "A block object containing the changes to commit to
                   the views. This is where you programmatically change any animatable properties of
                   the views in your view hierarchy. This block takes no parameters and has no
                   return value. This parameter must not be NULL."
                   Supports animating additional CALayer properties beyond what UIView's similar API
                   supports. See MDMAnimatableKeyPaths for a full list of implicilty animatable
                   CALayer properties.
 */
+ (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(void (^ __nonnull)(void))animations;

/**
 Similar to the UIKit method of the same name with some intentional differences in behavior.

 This API does not disable user interaction during animations, unlike the default behavior of
 UIView's similar API.

 Like the UIKit API, this method performs the specified animations immediately using the
 UIViewAnimationOptionCurveEaseInOut animation option.

 @param duration   From UIKit's documentation: "The total duration of the animations, measured in
                   seconds. If you specify a negative value or 0, the changes are made without
                   animating them."

 @param animations From UIKit's documentation: "A block object containing the changes to commit to
                   the views. This is where you programmatically change any animatable properties of
                   the views in your view hierarchy. This block takes no parameters and has no
                   return value. This parameter must not be NULL."
                   Supports animating additional CALayer properties beyond what UIView's similar API
                   supports. See MDMAnimatableKeyPaths for a full list of implicilty animatable
                   CALayer properties.

 @param completion From UIKit's documentation: "A block object to be executed when the animation
                   sequence ends. This block has no return value and takes a single Boolean argument
                   that indicates whether or not the animations actually finished before the
                   completion handler was called."
                   Unlike UIKit's API, if the duration of the animation is 0, this block is
                   performed immediately. This parameter may be NULL.
 */
+ (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(void (^ __nonnull)(void))animations
                 completion:(void (^ __nullable)(BOOL finished))completion;

/**
 Similar to the UIKit method of the same name with some intentional differences in behavior.

 This API does not disable user interaction during animations, unlike the default behavior of
 UIView's similar API.

 Like the UIKit API, this method performs the specified animations immediately.

 The only options that are presently supported are the UIViewAnimationOptionCurve flags.

 @param duration   From UIKit's documentation: "The total duration of the animations, measured in
                   seconds. If you specify a negative value or 0, the changes are made without
                   animating them."

 @param delay      From UIKit's documentation: "The amount of time (measured in seconds) to wait
                   before beginning the animations. Specify a value of 0 to begin the animations
                   immediately."

 @param options    From UIKit's documentation: "A mask of options indicating how you want to perform
                   the animations. For a list of valid constants, see UIViewAnimationOptions." Only
                   the UIViewAnimationOptionCurve flags are supported presently.

 @param animations From UIKit's documentation: "A block object containing the changes to commit to
                   the views. This is where you programmatically change any animatable properties of
                   the views in your view hierarchy. This block takes no parameters and has no
                   return value. This parameter must not be NULL."
                   Supports animating additional CALayer properties beyond what UIView's similar API
                   supports. See MDMAnimatableKeyPaths for a full list of implicilty animatable
                   CALayer properties.

 @param completion From UIKit's documentation: "A block object to be executed when the animation
                   sequence ends. This block has no return value and takes a single Boolean argument
                   that indicates whether or not the animations actually finished before the
                   completion handler was called."
                   Unlike UIKit's API, if the duration of the animation is 0, this block is
                   performed immediately. This parameter may be NULL.
 */
+ (void)animateWithDuration:(NSTimeInterval)duration
                      delay:(NSTimeInterval)delay
                    options:(UIViewAnimationOptions)options
                 animations:(void (^ __nonnull)(void))animations
                 completion:(void (^ __nullable)(BOOL finished))completion;

/**
 Similar to the UIKit method of the same name with some intentional differences in behavior.

 This API does not disable user interaction during animations, unlike the default behavior of
 UIView's similar API.

 Like the UIKit API, this method performs the specified animations immediately.

 @param duration     From UIKit's documentation: "The total duration of the animations, measured in
                     seconds. If you specify a negative value or 0, the changes are made without
                     animating them."

 @param delay        From UIKit's documentation: "The amount of time (measured in seconds) to wait
                     before beginning the animations. Specify a value of 0 to begin the animations
                     immediately."

 @param options      Ignored.

 @param dampingRatio From UIKit's documentation: "The damping ratio for the spring animation as it
                     approaches its quiescent state. To smoothly decelerate the animation without
                     oscillation, use a value of 1. Employ a damping ratio closer to zero to
                     increase oscillation."

 @param velocity     From UIKit's documentation: "The initial spring velocity. For smooth start to
                     the animation, match this value to the view’s velocity as it was prior to
                     attachment."
                     Unlike UIKit's API, the initial velocity value is measured in terms of absolute
                     units of motion. For example, if animating a position from 0 to 10 with an
                     initial velocity of 100 points/second, the provided initial velocity value
                     should be 100.

 @param animations   From UIKit's documentation: "A block object containing the changes to commit to
                     the views. This is where you programmatically change any animatable properties
                     of the views in your view hierarchy. This block takes no parameters and has no
                     return value. This parameter must not be NULL."
                     Supports animating additional CALayer properties beyond what UIView's similar
                     API supports. See MDMAnimatableKeyPaths for a full list of implicilty
                     animatable CALayer properties.

 @param completion   From UIKit's documentation: "A block object to be executed when the animation
                     sequence ends. This block has no return value and takes a single Boolean
                     argument that indicates whether or not the animations actually finished before
                     the completion handler was called."
                     Unlike UIKit's API, if the duration of the animation is 0, this block is
                     performed immediately. This parameter may be NULL.
 */
+ (void)animateWithDuration:(NSTimeInterval)duration
                      delay:(NSTimeInterval)delay
     usingSpringWithDamping:(CGFloat)dampingRatio
      initialSpringVelocity:(CGFloat)velocity
                    options:(UIViewAnimationOptions)options
                 animations:(void (^ __nonnull)(void))animations
                 completion:(void (^ __nullable)(BOOL finished))completion;

@end

@interface MDMMotionAnimator (Legacy)

/**
 To be deprecated. Use animateWithTraits:between:layer:keyPath instead.
 */
- (void)animateWithTiming:(MDMMotionTiming)timing
                  toLayer:(nonnull CALayer *)layer
               withValues:(nonnull NSArray *)values
                  keyPath:(nonnull MDMAnimatableKeyPath)keyPath;

/**
 To be deprecated. Use animateWithTraits:between:layer:keyPath:completion: instead.
 */
- (void)animateWithTiming:(MDMMotionTiming)timing
                  toLayer:(nonnull CALayer *)layer
               withValues:(nonnull NSArray *)values
                  keyPath:(nonnull MDMAnimatableKeyPath)keyPath
               completion:(nullable void(^)(void))completion;

/**
 To be deprecated. Use animateWithTraits:animations: instead.
 */
- (void)animateWithTiming:(MDMMotionTiming)timing
               animations:(nonnull void(^)(void))animations;

/**
 To be deprecated. Use animateWithTraits:animations:completion: instead.
 */
- (void)animateWithTiming:(MDMMotionTiming)timing
               animations:(nonnull void (^)(void))animations
               completion:(nullable void(^)(void))completion;

@end

@interface MDMMotionAnimator (ImplicitLayerAnimations)

/**
 Returns a layer delegate that solely implements actionForLayer:forKey:.

 Assign this delegate to a standalone CALayer (one created using [[CALayer alloc] init]) in order to
 be able to implicitly animate its properties with MDMMotionAnimator. This is not necessary for
 layers that are backing a UIView.
 */
+ (nonnull id<CALayerDelegate>)sharedLayerDelegate
    __deprecated_msg("No longer needed for implicit animations of headless layers.");

@end
