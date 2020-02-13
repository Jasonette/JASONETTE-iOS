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
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

#ifdef IS_BAZEL_BUILD
#import "MotionInterchange.h"
#else
#import <MotionInterchange/MotionInterchange.h>
#endif

// Returns a basic animation configured with the provided traits and scale factor.
FOUNDATION_EXPORT
CABasicAnimation *MDMAnimationFromTraits(MDMAnimationTraits *traits, CGFloat timeScaleFactor);

// Returns a Boolean indicating whether or not an animation with the given key path and toValue
// can be animated additively.
FOUNDATION_EXPORT BOOL MDMCanAnimationBeAdditive(NSString *keyPath, id toValue);

// If the animation's additive property is enabled, then its from/to values will be transformed into
// additive equivalents.
//
// Not all animation value types support being additive. If an animation's value type was not
// supported, the animation's values will not be modified.
FOUNDATION_EXPORT void MDMConfigureAnimation(CABasicAnimation *animation, MDMAnimationTraits *traits);
