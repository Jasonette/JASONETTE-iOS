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

/**
 A timing curve that represents the motion of a single-dimensional attached spring.
 */
MDM_SUBCLASSING_RESTRICTED
@interface MDMSpringTimingCurve: NSObject <NSCopying, MDMTimingCurve>

/**
 Initializes the timing curve with the given parameters and an initial velocity of zero.

 @param mass The mass of the spring simulation. Affects the animation's momentum.
 @param tension The tension of the spring simulation. Affects how quickly the animation moves
 toward its destination.
 @param friction The friction of the spring simulation. Affects how quickly the animation starts
 and stops.
 */
- (nonnull instancetype)initWithMass:(CGFloat)mass
                             tension:(CGFloat)tension
                            friction:(CGFloat)friction;

/**
 Initializes the timing curve with the given parameters.

 @param mass The mass of the spring simulation. Affects the animation's momentum.
 @param tension The tension of the spring simulation. Affects how quickly the animation moves
 toward its destination.
 @param friction The friction of the spring simulation. Affects how quickly the animation starts
 and stops.
 @param initialVelocity The initial velocity of the spring simulation. Measured in units of
 translation per second. For example, if the property being animated is positional, then this value
 is in screen units per second.
 */
- (nonnull instancetype)initWithMass:(CGFloat)mass
                             tension:(CGFloat)tension
                            friction:(CGFloat)friction
                     initialVelocity:(CGFloat)initialVelocity
    NS_DESIGNATED_INITIALIZER;

#pragma mark - Traits

/**
 The mass of the spring simulation.

 Affects the animation's momentum. This is usually 1.
 */
@property(nonatomic, assign) CGFloat mass;

/**
 The tension of the spring simulation.

 Affects how quickly the animation moves toward its destination.
 */
@property(nonatomic, assign) CGFloat tension;

/**
 The friction of the spring simulation.

 Affects how quickly the animation starts and stops.
 */
@property(nonatomic, assign) CGFloat friction;

/**
 The initial velocity of the spring simulation.

 Measured in units of translation per second.

 If this timing curve was initialized using a damping ratio then setting a new initial velocity
 will also change the the mass/tension/friction values according to the new UIKit damping
 coefficient calculation.
 */
@property(nonatomic, assign) CGFloat initialVelocity;

/** Unavailable. */
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
