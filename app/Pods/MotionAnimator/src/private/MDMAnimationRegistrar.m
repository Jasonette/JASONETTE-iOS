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

#import "MDMAnimationRegistrar.h"

#import "MDMRegisteredAnimation.h"

@implementation MDMAnimationRegistrar {
  NSMapTable<CALayer *, NSMutableSet<MDMRegisteredAnimation *> *> *_layersToRegisteredAnimation;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _layersToRegisteredAnimation = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                                                      valueOptions:NSPointerFunctionsStrongMemory];
  }
  return self;
}

#pragma mark - Private

- (void)forEachAnimation:(void (^)(CALayer *, CABasicAnimation *, NSString *))work {
  // Copy the registered animations before iteration in case further modifications happen to the
  // registered animations. Consider if we remove an animation, its associated completion block
  // might invoke logic that adds a new animation, potentially modifying our collections.
  for (CALayer *layer in [_layersToRegisteredAnimation copy]) {
    NSSet *keyPathAnimations = [_layersToRegisteredAnimation objectForKey:layer];
    for (MDMRegisteredAnimation *keyPathAnimation in [keyPathAnimations copy]) {
      if (![keyPathAnimation.animation isKindOfClass:[CABasicAnimation class]]) {
        continue;
      }

      work(layer, [keyPathAnimation.animation copy], keyPathAnimation.key);
    }
  }
}

#pragma mark - Public

- (void)addAnimation:(CABasicAnimation *)animation
                toLayer:(CALayer *)layer
                 forKey:(NSString *)key
             completion:(void(^)(BOOL))completion {
  if (key == nil) {
    key = [NSUUID UUID].UUIDString;
  }

  NSMutableSet *animatedKeyPaths = [_layersToRegisteredAnimation objectForKey:layer];
  if (!animatedKeyPaths) {
    animatedKeyPaths = [[NSMutableSet alloc] init];
    [_layersToRegisteredAnimation setObject:animatedKeyPaths forKey:layer];
  }
  MDMRegisteredAnimation *keyPathAnimation =
      [[MDMRegisteredAnimation alloc] initWithKey:key animation:animation];
  [animatedKeyPaths addObject:keyPathAnimation];

  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    [animatedKeyPaths removeObject:keyPathAnimation];

    if (completion) {
      completion(YES);
    }
  }];

  [layer addAnimation:animation forKey:key];

  [CATransaction commit];
}

- (void)commitCurrentAnimationValuesToAllLayers {
  [self forEachAnimation:^(CALayer *layer, CABasicAnimation *animation, NSString *key) {
    id presentationLayer = [layer presentationLayer];
    if (presentationLayer != nil) {
      id presentationValue = [presentationLayer valueForKeyPath:animation.keyPath];
      [layer setValue:presentationValue forKeyPath:animation.keyPath];
    }
  }];
}

- (void)removeAllAnimations {
  [self forEachAnimation:^(CALayer *layer, CABasicAnimation *animation, NSString *key) {
    [layer removeAnimationForKey:key];
  }];
  [_layersToRegisteredAnimation removeAllObjects];
}

@end
