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

#import <Foundation/Foundation.h>
#import <MotionInterchange/MotionInterchange.h>

typedef struct MDCActivityIndicatorMotionSpecIndeterminate {
  MDMMotionTiming outerRotation;
  MDMMotionTiming innerRotation;
  MDMMotionTiming strokeStart;
  MDMMotionTiming strokeEnd;
} MDCActivityIndicatorMotionSpecIndeterminate;

typedef struct MDCActivityIndicatorMotionSpecTransitionToDeterminate {
  MDMMotionTiming innerRotation;
  MDMMotionTiming strokeEnd;
} MDCActivityIndicatorMotionSpecTransitionToDeterminate;

typedef struct MDCActivityIndicatorMotionSpecTransitionToIndeterminate {
  MDMMotionTiming strokeStart;
  MDMMotionTiming strokeEnd;
} MDCActivityIndicatorMotionSpecTransitionToIndeterminate;

typedef struct MDCActivityIndicatorMotionSpecProgress {
  MDMMotionTiming strokeEnd;
} MDCActivityIndicatorMotionSpecProgress;

__attribute__((objc_subclassing_restricted)) @interface MDCActivityIndicatorMotionSpec : NSObject

@property(nonatomic, class, readonly) NSTimeInterval pointCycleDuration;
@property(nonatomic, class, readonly) NSTimeInterval pointCycleMinimumVariableDuration;

@property(nonatomic, class, readonly) MDCActivityIndicatorMotionSpecIndeterminate loopIndeterminate;
@property(nonatomic, class, readonly)
    MDCActivityIndicatorMotionSpecTransitionToDeterminate willChangeToDeterminate;
@property(nonatomic, class, readonly)
    MDCActivityIndicatorMotionSpecTransitionToIndeterminate willChangeToIndeterminate;
@property(nonatomic, class, readonly) MDCActivityIndicatorMotionSpecProgress willChangeProgress;

// This object is not meant to be instantiated.
- (instancetype)init NS_UNAVAILABLE;

@end
