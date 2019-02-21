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

/**
 The possible kinds of repetition that can be used to describe an animation.
 */
typedef NS_ENUM(NSUInteger, MDMMotionRepetitionType) {
  /**
   The animation will be not be repeated.
   */
  MDMMotionRepetitionTypeNone,

  /**
   The animation will be repeated a given number of times.
   */
  MDMMotionRepetitionTypeCount,

  /**
   The animation will be repeated for a given number of seconds.
   */
  MDMMotionRepetitionTypeDuration,

} NS_SWIFT_NAME(MotionReptitionType);

/**
 A generalized representation of a motion curve.
 */
struct MDMMotionRepetition {
  /**
   The type defines how to interpret the amount.
   */
  MDMMotionRepetitionType type;

  /**
   The amount of repetition.
   */
  double amount;

  /**
   Whether the animation should animate backwards after animating forwards.
   */
  BOOL autoreverses;

} NS_SWIFT_NAME(MotionRepetition);
typedef struct MDMMotionRepetition MDMMotionRepetition;

// Objective-C-specific macros

#define _MDMNoRepetition                 \
  (MDMMotionRepetition) {                \
    .type = MDMMotionRepetitionTypeNone, \
    .amount = 0,                         \
    .autoreverses = false                \
  }
