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
 Represents repetition that repeats a specific number of times.
 */
MDM_SUBCLASSING_RESTRICTED
@interface MDMRepetition: NSObject <NSCopying, MDMRepetitionTraits>

/**
 Initializes the instance with the given number of repetitions.

 Autoreversing is disabled.

 @param numberOfRepetitions May be fractional. Initializing with greatestFiniteMagnitude will cause
 the animation to repeat forever.
 */
- (nonnull instancetype)initWithNumberOfRepetitions:(double)numberOfRepetitions;

/**
 Initializes the instance with the given number of repetitions and autoreversal behavior.

 @param numberOfRepetitions May be fractional. Initializing with greatestFiniteMagnitude will cause
 the animation to repeat forever.
 @param autoreverses Whether the animation should animate backwards after animating forwards.
 */
- (nonnull instancetype)initWithNumberOfRepetitions:(double)numberOfRepetitions
                                       autoreverses:(BOOL)autoreverses
    NS_DESIGNATED_INITIALIZER;

#pragma mark - Traits

/**
 The number of repetitions that will occur before this animation stops repeating.
 */
@property(nonatomic, assign) double numberOfRepetitions;

/**
 Unavailable.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

@end

