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

#import "MDMRepetition.h"

@implementation MDMRepetition

@synthesize autoreverses = _autoreverses;

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithNumberOfRepetitions:(double)numberOfRepetitions {
  return [self initWithNumberOfRepetitions:numberOfRepetitions autoreverses:NO];
}

- (instancetype)initWithNumberOfRepetitions:(double)numberOfRepetitions
                               autoreverses:(BOOL)autoreverses {
  self = [super init];
  if (self) {
    _numberOfRepetitions = numberOfRepetitions;
    _autoreverses = autoreverses;
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone {
  return [[[self class] alloc] initWithNumberOfRepetitions:self.numberOfRepetitions
                                              autoreverses:self.autoreverses];
}

@end

