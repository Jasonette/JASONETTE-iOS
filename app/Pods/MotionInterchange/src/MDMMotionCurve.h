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
#import <QuartzCore/QuartzCore.h>

/**
 The possible kinds of motion curves that can be used to describe an animation.
 */
typedef NS_ENUM(NSUInteger, MDMMotionCurveType) {
  /**
   The value will be instantly set with no animation.
   */
  MDMMotionCurveTypeInstant,

  /**
   The value will be animated using a cubic bezier curve to model its velocity.
   */
  MDMMotionCurveTypeBezier,

  /**
   The value will be animated using a spring simulation.

   A spring will treat the duration property of the motion timing as a suggestion and may choose to
   ignore it altogether.
   */
  MDMMotionCurveTypeSpring,

  /**
   The default curve will be used.
   */
  MDMMotionCurveTypeDefault __deprecated_enum_msg("Use MDMMotionCurveTypeBezier instead."),

} NS_SWIFT_NAME(MotionCurveType);

/**
 A generalized representation of a motion curve.
 */
struct MDMMotionCurve {
  /**
   The type defines how to interpret the data values.
   */
  MDMMotionCurveType type;

  /**
   The data values corresponding with this curve.
   */
  CGFloat data[4];
} NS_SWIFT_NAME(MotionCurve);
typedef struct MDMMotionCurve MDMMotionCurve;

/**
 Creates a bezier motion curve with the provided control points.

 A cubic bezier has four control points in total. We assume that the first control point is 0, 0 and
 the last control point is 1, 1. This method requires that you provide the second and third control
 points.

 See the documentation for CAMediaTimingFunction for more information.
 */
// clang-format off
FOUNDATION_EXTERN
MDMMotionCurve MDMMotionCurveMakeBezier(CGFloat p1x, CGFloat p1y, CGFloat p2x, CGFloat p2y)
    NS_SWIFT_NAME(MotionCurveMakeBezier(p1x:p1y:p2x:p2y:));
// clang-format on

// clang-format off
FOUNDATION_EXTERN
MDMMotionCurve MDMMotionCurveFromTimingFunction(CAMediaTimingFunction * _Nonnull timingFunction)
    NS_SWIFT_NAME(MotionCurve(fromTimingFunction:));
// clang-format on

/**
 Creates a spring curve with the provided configuration.

 Tension and friction map to Core Animation's stiffness and damping, respectively.

 See the documentation for CASpringAnimation for more information.
 */
// clang-format off
FOUNDATION_EXTERN MDMMotionCurve MDMMotionCurveMakeSpring(CGFloat mass,
                                                          CGFloat tension,
                                                          CGFloat friction)
    NS_SWIFT_NAME(MotionCurveMakeSpring(mass:tension:friction:));
// clang-format on

/**
 Creates a spring curve with the provided configuration.

 Tension and friction map to Core Animation's stiffness and damping, respectively.

 See the documentation for CASpringAnimation for more information.
 */
// clang-format off
FOUNDATION_EXTERN
MDMMotionCurve MDMMotionCurveMakeSpringWithInitialVelocity(CGFloat mass,
                                                           CGFloat tension,
                                                           CGFloat friction,
                                                           CGFloat initialVelocity)
    NS_SWIFT_NAME(MotionCurveMakeSpring(mass:tension:friction:initialVelocity:));
// clang-format on

/**
 For cubic bezier curves, returns a reversed cubic bezier curve. For all other curve types, a copy
 of the original curve is returned.
 */
// clang-format off
FOUNDATION_EXTERN MDMMotionCurve MDMMotionCurveReversedBezier(MDMMotionCurve motionCurve)
    NS_SWIFT_NAME(MotionCurveReversedBezier(fromMotionCurve:));
// clang-format on

/**
 Named indices for the bezier motion curve's data array.
 */
typedef NS_ENUM(NSUInteger, MDMBezierMotionCurveDataIndex) {
  MDMBezierMotionCurveDataIndexP1X,
  MDMBezierMotionCurveDataIndexP1Y,
  MDMBezierMotionCurveDataIndexP2X,
  MDMBezierMotionCurveDataIndexP2Y
} NS_SWIFT_NAME(BezierMotionCurveDataIndex);

/**
 Named indices for the spring motion curve's data array.
 */
typedef NS_ENUM(NSUInteger, MDMSpringMotionCurveDataIndex) {
  MDMSpringMotionCurveDataIndexMass,
  MDMSpringMotionCurveDataIndexTension,
  MDMSpringMotionCurveDataIndexFriction,

  /**
   The initial velocity of the animation.

   A value of zero indicates no initial velocity.
   A positive value indicates movement toward the destination.
   A negative value indicates movement away from the destination.

   The value's units are dependent on the context and the value being animated.
   */
  MDMSpringMotionCurveDataIndexInitialVelocity
} NS_SWIFT_NAME(SpringMotionCurveDataIndex);

// Objective-C-specific macros

#define _MDMBezier(p1x, p1y, p2x, p2y) \
  ((MDMMotionCurve) {                   \
    .type = MDMMotionCurveTypeBezier,  \
    .data = { p1x,                     \
              p1y,                     \
              p2x,                     \
              p2y }                    \
  })

#define _MDMSpring(mass, tension, friction) \
  ((MDMMotionCurve) {                        \
    .type = MDMMotionCurveTypeSpring,       \
    .data = { mass,                         \
              tension,                      \
              friction }                    \
  })

#define _MDMSpringWithInitialVelocity(mass, tension, friction, initialVelocity) \
  ((MDMMotionCurve) {                        \
    .type = MDMMotionCurveTypeSpring,       \
    .data = { mass,                         \
              tension,                      \
              friction,                     \
              initialVelocity }             \
  })

/**
 A linear bezier motion curve.
 */
#define MDMLinearMotionCurve _MDMBezier(0, 0, 1, 1)

/**
 Timing information for an iOS modal presentation slide animation.
 */
#define MDMModalMovementTiming { \
  .delay = 0.000, .duration = 0.500, .curve = _MDMSpring(3, 1000, 500) \
}
