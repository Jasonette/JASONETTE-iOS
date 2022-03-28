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

// Tracks and manipulates animations that have been added to a layer.
@interface MDMAnimationRegistrar : NSObject

// Invokes the layer's addAnimation:forKey: method with the provided animation and key and tracks
// its association. Upon completion of the animation, the provided optional completion block will be
// executed.
- (void)addAnimation:(nonnull CABasicAnimation *)animation
             toLayer:(nonnull CALayer *)layer
              forKey:(nullable NSString *)key
          completion:(void(^ __nullable)(BOOL))completion;

// For every active animation, reads the associated layer's presentation layer key path and writes
// it to the layer.
- (void)commitCurrentAnimationValuesToAllLayers;

// Removes all active animations from their associated layer.
- (void)removeAllAnimations;

@end
