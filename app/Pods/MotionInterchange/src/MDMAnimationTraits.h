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

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MDMMotionTiming.h"
#import "MDMRepetitionTraits.h"
#import "MDMSubclassingRestricted.h"
#import "MDMTimingCurve.h"

/**
 A generic representation of animation traits.
 */
MDM_SUBCLASSING_RESTRICTED
@interface MDMAnimationTraits: NSObject <NSCopying>

/**
 Initializes the instance with the provided duration and kCAMediaTimingFunctionEaseInEaseOut timing
 curve.

 @param duration The animation will occur over this length of time, in seconds.
 */
- (nonnull instancetype)initWithDuration:(NSTimeInterval)duration;

/**
 Initializes the instance with the provided duration and named bezier timing curve.

 @param duration The animation will occur over this length of time, in seconds.
 @param animationCurve A UIKit bezier animation curve type.
 */
- (nonnull instancetype)initWithDuration:(NSTimeInterval)duration
                          animationCurve:(UIViewAnimationCurve)animationCurve;

/**
 Initializes the instance with the provided duration, delay, and
 kCAMediaTimingFunctionEaseInEaseOut timing curve.

 @param delay The amount of time, in seconds, to wait before starting the animation.
 @param duration The animation will occur over this length of time, in seconds, after the delay time
 has passed.
 */
- (nonnull instancetype)initWithDelay:(NSTimeInterval)delay duration:(NSTimeInterval)duration;

/**
 Initializes the instance with the provided duration, delay, and named bezier timing curve.

 This is a convenience API for defining a timing curve using the Core Animation timing function
 names. See the documentation for CAMediaTimingFunction for more details.

 @param delay The amount of time, in seconds, to wait before starting the animation.
 @param duration The animation will occur over this length of time, in seconds, after the delay time
 has passed.
 @param animationCurve A UIKit bezier animation curve type.
 */
- (nonnull instancetype)initWithDelay:(NSTimeInterval)delay
                             duration:(NSTimeInterval)duration
                       animationCurve:(UIViewAnimationCurve)animationCurve;

/**
 Initializes the instance with the provided duration, delay, and timing curve.

 @param delay The amount of time, in seconds, to wait before starting the animation.
 @param duration The animation will occur over this length of time, in seconds, after the delay time
 has passed.
 @param timingCurve If provided, defines the acceleration timing for the animation. If nil, the
 animation will be treated as instant and the duration/delay will be ignored.
 */
- (nonnull instancetype)initWithDelay:(NSTimeInterval)delay
                             duration:(NSTimeInterval)duration
                          timingCurve:(nullable id<MDMTimingCurve>)timingCurve;

/**
 Initializes an animation trait with the provided timing curve, duration, delay, and repetition.

 @param duration The animation will occur over this length of time, in seconds, after the delay time
 has passed.
 @param delay The amount of time, in seconds, to wait before starting the animation.
 @param timingCurve If provided, defines the acceleration timing for the animation. If nil, the
 animation will be treated as instant and the duration/delay will be ignored.
 @param repetition The repetition traits of the animation. Most often an instance of MDMRepetition
 or MDMRepetitionOverTime. If nil, the animation will not repeat.
 */
- (nonnull instancetype)initWithDelay:(NSTimeInterval)delay
                             duration:(NSTimeInterval)duration
                          timingCurve:(nullable id<MDMTimingCurve>)timingCurve
                           repetition:(nullable id<MDMRepetitionTraits>)repetition
    NS_DESIGNATED_INITIALIZER;

#pragma mark - Traits

/**
 The amount of time, in seconds, before this animation's value interpolation should begin.
 */
@property(nonatomic, assign) NSTimeInterval delay;

/**
 The amount of time, in seconds, over which this animation should interpolate between its values.
 */
@property(nonatomic, assign) NSTimeInterval duration;

/**
 The velocity and acceleration of the animation over time.

 If the timing curve is nil then the timing is assumed to be "instant", regardless of duration and
 delay.
 */
@property(nonatomic, strong, nullable) id<MDMTimingCurve> timingCurve;

/**
 The repetition characteristics of the animation.

 If the repetition is nil then no repetition should occur.
 */
@property(nonatomic, strong, nullable) id<MDMRepetitionTraits> repetition;

#pragma mark - Unavailable

/**
 Unavailable.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

@end

@interface MDMAnimationTraits (SystemTraits)

/**
 Animation traits for an iOS modal presentation slide animation.
 */
@property(nonatomic, class, strong, nonnull, readonly) MDMAnimationTraits *systemModalMovement;

@end

@interface MDMAnimationTraits (Legacy)

/**
 Initializes the instance with the provided legacy C-style animation trait structure.

 @param timing A legacy C-style representation of animation traits.
 */
- (nonnull instancetype)initWithMotionTiming:(MDMMotionTiming)timing;

@end
