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

#import "MDMSpringTimingCurveGenerator.h"

#import "MDMSpringTimingCurve.h"

#import <UIKit/UIKit.h>

@implementation MDMSpringTimingCurveGenerator

- (instancetype)initWithDuration:(NSTimeInterval)duration dampingRatio:(CGFloat)dampingRatio {
  return [self initWithDuration:duration dampingRatio:dampingRatio initialVelocity:0];
}

- (nonnull instancetype)initWithDuration:(NSTimeInterval)duration
                            dampingRatio:(CGFloat)dampingRatio
                         initialVelocity:(CGFloat)initialVelocity {
  self = [super init];
  if (self) {
    _duration = duration;
    _dampingRatio = dampingRatio;
    _initialVelocity = initialVelocity;
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithDuration:self.duration
                                                dampingRatio:self.dampingRatio
                                             initialVelocity:self.initialVelocity];
}

- (MDMSpringTimingCurve *)springTimingCurve {
  UIView *view = [[UIView alloc] init];
  [UIView animateWithDuration:self.duration
                        delay:0
       usingSpringWithDamping:self.dampingRatio
        initialSpringVelocity:self.initialVelocity
                      options:0
                   animations:^{
                     view.center = CGPointMake(100, 100);
                   } completion:nil];

  NSString *animationKey = [view.layer.animationKeys firstObject];
  NSAssert(animationKey != nil, @"Unable to extract animation timing curve: no animation found.");
#pragma clang diagnostic push
  // CASpringAnimation is a private API on iOS 8 - we're able to make use of it because we're
  // linking against the public API on iOS 9+.
#pragma clang diagnostic ignored "-Wpartial-availability"
  CASpringAnimation *springAnimation =
      (CASpringAnimation *)[view.layer animationForKey:animationKey];
  NSAssert([springAnimation isKindOfClass:[CASpringAnimation class]],
           @"Unable to extract animation timing curve: unexpected animation type.");
#pragma clang diagnostic pop

  return [[MDMSpringTimingCurve alloc] initWithMass:springAnimation.mass
                                            tension:springAnimation.stiffness
                                           friction:springAnimation.damping
                                    initialVelocity:self.initialVelocity];
}

@end
