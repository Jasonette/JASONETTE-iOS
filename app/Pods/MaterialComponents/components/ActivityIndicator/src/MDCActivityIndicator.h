// Copyright 2016-present the Material Components for iOS authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <UIKit/UIKit.h>

@class MDCActivityIndicatorTransition;
@protocol MDCActivityIndicatorDelegate;

/**
 Different operating modes for the activity indicator.

 This component can be used as a determinate progress indicator or an indeterminate activity
 indicator.

 Default value is MDCActivityIndicatorModeIndeterminate.
 */
typedef NS_ENUM(NSInteger, MDCActivityIndicatorMode) {
  /** Indeterminate indicators visualize an unspecified wait time. */
  MDCActivityIndicatorModeIndeterminate,
  /** Determinate indicators display how long an operation will take. */
  MDCActivityIndicatorModeDeterminate,
};

/**
 A Material Design activity indicator.

 The activity indicator is a circular spinner that shows progress of an operation. By default the
 activity indicator assumes indeterminate progress of an unspecified length of time. In contrast to
 a standard UIActivityIndicator, MDCActivityIndicator supports showing determinate progress and uses
 custom Material Design animation for indeterminate progress.

 See https://material.io/go/design-progress-indicators
 */
IB_DESIGNABLE
@interface MDCActivityIndicator : UIView

/**
 The callback delegate. See @c MDCActivityIndicatorDelegate.
 */
@property(nonatomic, weak, nullable) id<MDCActivityIndicatorDelegate> delegate;

/**
 Whether or not the activity indicator is currently animating.
 */
@property(nonatomic, assign, getter=isAnimating) BOOL animating;

/**
 Spinner radius width. Defaults to 12dp (24x24dp circle), with a minimum of 5dp. The spinner is
 centered in the view's bounds. If the bounds are smaller than the diameter of the spinner, the
 spinner may be clipped when clipToBounds is true.
 */
@property(nonatomic, assign) CGFloat radius UI_APPEARANCE_SELECTOR;

/**
 Spinner stroke width. Defaults to 2dp.
 */
@property(nonatomic, assign) CGFloat strokeWidth UI_APPEARANCE_SELECTOR;

/**
 Show a faint ink track along the path of the indicator. Should be enabled when the activity
 indicator wraps around another circular element, such as an avatar or a FAB. Defaults to NO.
 */
@property(nonatomic, assign) IBInspectable BOOL trackEnabled;

/**
 The mode of the activity indicator. Default is MDCActivityIndicatorModeIndeterminate. If
 currently animating, it will animate the transition between the current mode to the new mode.
 */
@property(nonatomic, assign) IBInspectable MDCActivityIndicatorMode indicatorMode;

/**
 Set the mode of the activity indicator. If currently animating, it will animate the transition
 between the current mode to the new mode. Default is MDCActivityIndicatorModeIndeterminate with no
 animation.
 */
- (void)setIndicatorMode:(MDCActivityIndicatorMode)mode animated:(BOOL)animated;

/**
 Progress is the extent to which the activity indicator circle is drawn to completion when
 indicatorMode is MDCActivityIndicatorModeDeterminate. Progress is drawn clockwise to complete a
 circle. Valid range is between [0-1]. Default is zero. 0.5 progress is half the circle. The
 transitions between progress levels are animated.
 */
@property(nonatomic, assign) IBInspectable float progress;

/**
 Set the determinate progress of the activity indicator when indicatorMode is
 MDCActivityIndicatorModeDeterminate.
 */
- (void)setProgress:(float)progress animated:(BOOL)animated;

/**
 The array of colors that are cycled through when animating the spinner. Populated with a set of
 default colors.

 @note If an empty array is provided to this property's setter, then the provided array will be
 discarded and an array consisting of the default color values will be assigned instead.
 */
@property(nonatomic, copy, nonnull) NSArray<UIColor *> *cycleColors UI_APPEARANCE_SELECTOR;

/**
 Starts the animated activity indicator. Does nothing if the spinner is already animating.
 */
- (void)startAnimating;

/**
 Starts the animated activity indicator after performing the provided transition. The animation
 cycle will begin on the cycleStartIndex provided. The startTransition will be applied with the
 starting and ending positions of the indicator stroke at the moment when the animation will begin
 taking into account the provided cycleStartIndex in the range [0,1]. The indicatorMode must be
 MDCActivityIndicatorModeIndeterminate before calling.
 */
- (void)startAnimatingWithTransition:(nonnull MDCActivityIndicatorTransition *)startTransition
                     cycleStartIndex:(NSInteger)cycleStartIndex;

/**
 Stops the animated activity indicator with a short opacity and stroke width animation. Does nothing
 if the spinner is not animating.
 */
- (void)stopAnimating;

/**
 Stops the animated activity indicator and then performs the provided transition. The provided
 stopTransition will be called with the starting and ending positions of the indicator stroke at the
 moment when the animation will begin in the range [0,1]. The indicatorMode must be
 MDCActivityIndicatorModeIndeterminate before calling.
 */
- (void)stopAnimatingWithTransition:(nonnull MDCActivityIndicatorTransition *)stopTransition;

/**
 A block that is invoked when the @c MDCActivityIndicator receives a call to @c
 traitCollectionDidChange:. The block is called after the call to the superclass.
 */
@property(nonatomic, copy, nullable) void (^traitCollectionDidChangeBlock)
    (MDCActivityIndicator *_Nonnull activityIndicator,
     UITraitCollection *_Nullable previousTraitCollection);

@end
typedef void (^MDCActivityIndicatorAnimation)(CGFloat strokeStart, CGFloat strokeEnd);

/**
 Describes an animation that can be provided to an MDCActivityIndicator instance to perform before
 or after its standard cycle animation.
 */
@interface MDCActivityIndicatorTransition : NSObject

/**
 The animations to be performed by MDCActivityIndicator. In this block add CAAnimations to be
 animated before or after MDCActivityIndicator's cycle animation. MDCActivityIndicator will trigger
 these animations and call completion after they complete.
 */
@property(nonatomic, copy, nonnull) MDCActivityIndicatorAnimation animation;

/**
 The completion block to call after animation's completion. This should be used to clean up any
 layers placed and animating on the MDCActivityIndicator.
 */
@property(nonatomic, copy, nullable) void (^completion)(void);

/**
 The duration of the animation.
 */
@property(nonatomic, assign) NSTimeInterval duration;

- (nonnull instancetype)init NS_UNAVAILABLE;

- (nonnull instancetype)initWithCoder:(nonnull NSCoder *)aDecoder NS_UNAVAILABLE;

- (nonnull instancetype)initWithAnimation:(_Nonnull MDCActivityIndicatorAnimation)animation
    NS_DESIGNATED_INITIALIZER;

@end
