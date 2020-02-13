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

#import "MDMRepetitionTraits.h"
#import "MDMSubclassingRestricted.h"

/**
 Represents repetition that repeats until a specific duration has passed.
 */
MDM_SUBCLASSING_RESTRICTED
@interface MDMRepetitionOverTime: NSObject <NSCopying, MDMRepetitionTraits>

/**
 Initializes the instance with the given duration.

 @param duration The amount of time, in seconds, over which the animation will repeat.
 */
- (nonnull instancetype)initWithDuration:(double)duration;

/**
 Initializes the instance with the given duration and autoreversal behavior.

 @param duration The amount of time, in seconds, over which the animation will repeat.
 @param autoreverses Whether the animation should animate backwards after animating forwards.
 */
- (nonnull instancetype)initWithDuration:(double)duration autoreverses:(BOOL)autoreverses
    NS_DESIGNATED_INITIALIZER;

#pragma mark - Traits

/**
 The amount of time, in seconds, that will pass before this animation stops repeating.
 */
@property(nonatomic, assign) double duration;

/**
 Unavailable.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

@end

