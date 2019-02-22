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

#import "MDMSubclassingRestricted.h"
#import "MDMTimingCurve.h"

@class MDMSpringTimingCurve;

/**
 A spring timing curve generator based on UIKit duration/dampingRatio-based coefficients.
 */
MDM_SUBCLASSING_RESTRICTED
@interface MDMSpringTimingCurveGenerator : NSObject <NSCopying, MDMTimingCurve>

/**
 Initializes the timing curve with the given UIKit spring damping ratio.

 @param duration The desired duration of the spring animation.
 @param dampingRatio From the UIKit documentation: "When `dampingRatio` is 1, the animation will
 smoothly decelerate to its final model values without oscillating. Damping ratios less than 1 will
 oscillate more and more before coming to a complete stop."
 */
- (nonnull instancetype)initWithDuration:(NSTimeInterval)duration
                            dampingRatio:(CGFloat)dampingRatio;

/**
 Initializes the timing curve with the given UIKit spring damping ratio and initial velocity.

 @param duration The desired duration of the spring animation.
 @param dampingRatio From the UIKit documentation: "When `dampingRatio` is 1, the animation will
 smoothly decelerate to its final model values without oscillating. Damping ratios less than 1 will
 oscillate more and more before coming to a complete stop."
 @param initialVelocity From the UIKit documentation: "You can use the initial spring velocity to
 specify how fast the object at the end of the simulated spring was moving before it was attached.
 It's a unit coordinate system, where 1 is defined as travelling the total animation distance in a
 second. So if you're changing an object's position by 200pt in this animation, and you want the
 animation to behave as if the object was moving at 100pt/s before the animation started, you'd
 pass 0.5. You'll typically want to pass 0 for the velocity."
 */
- (nonnull instancetype)initWithDuration:(NSTimeInterval)duration
                            dampingRatio:(CGFloat)dampingRatio
                         initialVelocity:(CGFloat)initialVelocity
    NS_DESIGNATED_INITIALIZER;

#pragma mark - Traits

/**
 The desired duration of the spring animation.
 */
@property(nonatomic, assign) NSTimeInterval duration;

/**
 From the UIKit documentation: "When `dampingRatio` is 1, the animation will
 smoothly decelerate to its final model values without oscillating. Damping ratios less than 1 will
 oscillate more and more before coming to a complete stop."
 */
@property(nonatomic, assign) CGFloat dampingRatio;

/**
 From the UIKit documentation: "You can use the initial spring velocity to
 specify how fast the object at the end of the simulated spring was moving before it was attached.
 It's a unit coordinate system, where 1 is defined as travelling the total animation distance in a
 second. So if you're changing an object's position by 200pt in this animation, and you want the
 animation to behave as if the object was moving at 100pt/s before the animation started, you'd
 pass 0.5. You'll typically want to pass 0 for the velocity."
 */
@property(nonatomic, assign) CGFloat initialVelocity;

/**
 Creates and returns a new spring timing curve instance with the current configuration.
 */
- (nonnull MDMSpringTimingCurve *)springTimingCurve;

/** Unavailable. */
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
