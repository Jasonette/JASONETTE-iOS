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

@interface CATransaction (MotionAnimator)

/**
 Accessor for the "timeScaleFactor" per-thread transaction property.

 Returns the transaction-specific time scale factor to be applied to animator animations.
 */
+ (nullable NSNumber *)mdm_timeScaleFactor;

/**
 Setter for the "timeScaleFactor" per-thread transaction property.

 Sets a transaction-specific time scale factor to be applied to animator animations.

 @param timeScaleFactor If nil, the animator's `timeScaleFactor` will be used instead. Should be a
                        CGFloat value type.
 */
+ (void)mdm_setTimeScaleFactor:(nullable NSNumber *)timeScaleFactor;

@end
