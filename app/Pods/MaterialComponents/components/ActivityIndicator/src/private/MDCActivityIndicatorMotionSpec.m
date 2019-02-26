// Copyright 2017-present the Material Components for iOS authors. All Rights Reserved.
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

#import "MDCActivityIndicatorMotionSpec.h"

@implementation MDCActivityIndicatorMotionSpec

+ (NSTimeInterval)pointCycleDuration {
  return 4.0 / 3.0;
}

+ (NSTimeInterval)pointCycleMinimumVariableDuration {
  return self.pointCycleDuration / 8;
}

+ (MDCActivityIndicatorMotionSpecIndeterminate)loopIndeterminate {
  NSTimeInterval pointCycleDuration = self.pointCycleDuration;
  MDMMotionCurve linear = MDMMotionCurveMakeBezier(0, 0, 1, 1);
  return (MDCActivityIndicatorMotionSpecIndeterminate){
    .outerRotation = {
      .duration = pointCycleDuration, .curve = linear,
    },
    .innerRotation = {
      .duration = pointCycleDuration, .curve = linear,
    },
    .strokeStart = {
      .delay = pointCycleDuration / 2,
      .duration = pointCycleDuration / 2,
      .curve = MDMMotionCurveMakeBezier(0.4f, 0.0f, 0.2f, 1.0f),
    },
    .strokeEnd = {
      .duration = pointCycleDuration,
      .curve = MDMMotionCurveMakeBezier(0.4f, 0.0f, 0.2f, 1.0f),
    },
  };
}

+ (MDCActivityIndicatorMotionSpecTransitionToDeterminate)willChangeToDeterminate {
  MDMMotionCurve linear = MDMMotionCurveMakeBezier(0, 0, 1, 1);
  return (MDCActivityIndicatorMotionSpecTransitionToDeterminate) {
    // Transition timing is calculated at runtime - any duration/delay values provided here will
    // by scaled by the calculated duration.
    .innerRotation = {
      .duration = 1, .curve = linear,
    },
    .strokeEnd = {
      .duration = 1, .curve = MDMMotionCurveMakeBezier(0.4f, 0.0f, 0.2f, 1.0f),
    },
  };
}

+ (MDCActivityIndicatorMotionSpecTransitionToIndeterminate)willChangeToIndeterminate {
  return (MDCActivityIndicatorMotionSpecTransitionToIndeterminate){
    // Transition timing is calculated at runtime.
    .strokeStart = {
      .curve = MDMMotionCurveMakeBezier(0.4f, 0.0f, 0.2f, 1.0f),
    },
    .strokeEnd = {
      .curve = MDMMotionCurveMakeBezier(0.4f, 0.0f, 0.2f, 1.0f),
    },
  };
}

+ (MDCActivityIndicatorMotionSpecProgress)willChangeProgress {
  return (MDCActivityIndicatorMotionSpecProgress){
    .strokeEnd = {
      .duration = self.pointCycleDuration / 2,
      .curve = MDMMotionCurveMakeBezier(0.4f, 0.0f, 0.2f, 1.0f),
    }
  };
}

@end
