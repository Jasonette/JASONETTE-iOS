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

#import "MDMAnimationTraits.h"

#import "CAMediaTimingFunction+MDMTimingCurve.h"
#import "MDMRepetition.h"
#import "MDMRepetitionOverTime.h"
#import "MDMSpringTimingCurve.h"

@implementation MDMAnimationTraits

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (nonnull instancetype)initWithDuration:(NSTimeInterval)duration {
  return [self initWithDelay:0 duration:duration];
}

- (instancetype)initWithDuration:(NSTimeInterval)duration
                  animationCurve:(UIViewAnimationCurve)animationCurve {
  return [self initWithDelay:0 duration:duration animationCurve:animationCurve];
}

- (instancetype)initWithDelay:(NSTimeInterval)delay duration:(NSTimeInterval)duration {
  return [self initWithDelay:delay duration:duration animationCurve:UIViewAnimationCurveEaseInOut];
}

- (instancetype)initWithDelay:(NSTimeInterval)delay
                     duration:(NSTimeInterval)duration
               animationCurve:(UIViewAnimationCurve)animationCurve {
  CAMediaTimingFunction *timingCurve;
  switch (animationCurve) {
    case UIViewAnimationCurveEaseInOut:
      timingCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
      break;
    case UIViewAnimationCurveEaseIn:
      timingCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
      break;
    case UIViewAnimationCurveEaseOut:
      timingCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
      break;
    case UIViewAnimationCurveLinear:
      timingCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
      break;
  }
  return [self initWithDelay:delay duration:duration timingCurve:timingCurve];
}

- (instancetype)initWithDelay:(NSTimeInterval)delay
                     duration:(NSTimeInterval)duration
                  timingCurve:(id<MDMTimingCurve>)timingCurve {
  return [self initWithDelay:delay duration:duration timingCurve:timingCurve repetition:nil];
}

- (instancetype)initWithDelay:(NSTimeInterval)delay
                     duration:(NSTimeInterval)duration
                  timingCurve:(id<MDMTimingCurve>)timingCurve
                   repetition:(id<MDMRepetitionTraits>)repetition {
  self = [super init];
  if (self) {
    _duration = duration;
    _delay = delay;
    _timingCurve = timingCurve;
    _repetition = repetition;
  }
  return self;
}

- (nonnull instancetype)initWithMotionTiming:(MDMMotionTiming)timing {
  id<MDMTimingCurve> timingCurve;
  switch (timing.curve.type) {
    case MDMMotionCurveTypeInstant:
      timingCurve = nil;
      break;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    case MDMMotionCurveTypeDefault:
#pragma clang diagnostic pop
    case MDMMotionCurveTypeBezier:
      timingCurve = [CAMediaTimingFunction functionWithControlPoints:(float)timing.curve.data[0]
                                                                    :(float)timing.curve.data[1]
                                                                    :(float)timing.curve.data[2]
                                                                    :(float)timing.curve.data[3]];
      break;
    case MDMMotionCurveTypeSpring: {
      CGFloat *data = timing.curve.data;
      timingCurve =
          [[MDMSpringTimingCurve alloc] initWithMass:data[MDMSpringMotionCurveDataIndexMass]
                                             tension:data[MDMSpringMotionCurveDataIndexTension]
                                            friction:data[MDMSpringMotionCurveDataIndexFriction]
                                     initialVelocity:data[MDMSpringMotionCurveDataIndexInitialVelocity]];
      break;
    }
  }
  id<MDMRepetitionTraits> repetition;
  switch (timing.repetition.type) {
    case MDMMotionRepetitionTypeNone:
      repetition = nil;
      break;

    case MDMMotionRepetitionTypeCount:
      repetition = [[MDMRepetition alloc] initWithNumberOfRepetitions:timing.repetition.amount
                                                         autoreverses:timing.repetition.autoreverses];
      break;
    case MDMMotionRepetitionTypeDuration:
      repetition = [[MDMRepetitionOverTime alloc] initWithDuration:timing.repetition.amount
                                                      autoreverses:timing.repetition.autoreverses];
      break;
  }
  return [self initWithDelay:timing.delay
                    duration:timing.duration
                 timingCurve:timingCurve
                  repetition:repetition];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] alloc] initWithDelay:self.delay
                                    duration:self.duration
                                 timingCurve:[self.timingCurve copyWithZone:zone]
                                  repetition:[self.repetition copyWithZone:zone]];
}

@end

@implementation MDMAnimationTraits (SystemTraits)

+ (MDMAnimationTraits *)systemModalMovement {
  MDMSpringTimingCurve *timingCurve = [[MDMSpringTimingCurve alloc] initWithMass:3
                                                                         tension:1000
                                                                        friction:500];
  return [[MDMAnimationTraits alloc] initWithDelay:0 duration:0.500 timingCurve:timingCurve];
}

@end

