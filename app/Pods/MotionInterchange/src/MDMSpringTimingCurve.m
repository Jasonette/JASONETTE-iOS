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

#import "MDMSpringTimingCurve.h"

@implementation MDMSpringTimingCurve

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithMass:(CGFloat)mass tension:(CGFloat)tension friction:(CGFloat)friction {
  return [self initWithMass:mass tension:tension friction:friction initialVelocity:0];
}

- (instancetype)initWithMass:(CGFloat)mass
                     tension:(CGFloat)tension
                    friction:(CGFloat)friction
             initialVelocity:(CGFloat)initialVelocity {
  self = [super init];
  if (self) {
    _mass = mass;
    _tension = tension;
    _friction = friction;
    _initialVelocity = initialVelocity;
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithMass:self.mass
                                                 tension:self.tension
                                                friction:self.friction
                                         initialVelocity:self.initialVelocity];;
}

#pragma mark - Private

@end

