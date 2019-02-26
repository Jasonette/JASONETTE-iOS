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

#import "MDMBlockAnimations.h"

#import "MDMMotionAnimator.h"
#import "MDMAnimatableKeyPaths.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Returns the set of animatable key paths supported by MDMMotionAnimator's implicit animations.
static NSSet<MDMAnimatableKeyPath> *AllAnimatableKeyPaths(void) {
  static NSSet *animatableKeyPaths = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    animatableKeyPaths = [NSSet setWithArray:@[MDMKeyPathAnchorPoint,
                                               MDMKeyPathBackgroundColor,
                                               MDMKeyPathBorderWidth,
                                               MDMKeyPathBorderColor,
                                               MDMKeyPathBounds,
                                               MDMKeyPathCornerRadius,
                                               MDMKeyPathHeight,
                                               MDMKeyPathOpacity,
                                               MDMKeyPathPosition,
                                               MDMKeyPathRotation,
                                               MDMKeyPathScale,
                                               MDMKeyPathShadowColor,
                                               MDMKeyPathShadowOffset,
                                               MDMKeyPathShadowOpacity,
                                               MDMKeyPathShadowRadius,
                                               MDMKeyPathStrokeStart,
                                               MDMKeyPathStrokeEnd,
                                               MDMKeyPathTransform,
                                               MDMKeyPathWidth,
                                               MDMKeyPathX,
                                               MDMKeyPathY,
                                               MDMKeyPathZ]];
  });
  return animatableKeyPaths;
}

@interface MDMActionContext: NSObject
@property(nonatomic, readonly) NSArray<MDMImplicitAction *> *interceptedActions;
@end

// The original CALayer method implementation of -actionForKey:
static IMP sOriginalActionForKeyLayerImp = NULL;

static NSMutableArray<MDMActionContext *> *sActionContext = nil;

@implementation MDMImplicitAction

- (instancetype)initWithLayer:(CALayer *)layer
                      keyPath:(NSString *)keyPath {
  self = [super init];
  if (self) {
    _layer = layer;
    _keyPath = [keyPath copy];
    _initialModelValue = [_layer valueForKeyPath:_keyPath];
    _hadPresentationLayer = [_layer presentationLayer] != nil;
    _initialPresentationValue = [[_layer presentationLayer] valueForKeyPath:_keyPath];
  }
  return self;
}

@end

@implementation MDMActionContext {
  NSMutableArray<MDMImplicitAction *> *_interceptedActions;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _interceptedActions = [NSMutableArray array];
  }
  return self;
}

- (void)addActionForLayer:(CALayer *)layer keyPath:(NSString *)keyPath {
  [_interceptedActions addObject:[[MDMImplicitAction alloc] initWithLayer:layer keyPath:keyPath]];
}

- (NSArray<MDMImplicitAction *> *)interceptedActions {
  return [_interceptedActions copy];
}

@end

@interface MDMLayerDelegate: NSObject <CALayerDelegate>
@end

static id<CAAction> ActionForKey(CALayer *layer, SEL _cmd, NSString *event) {
  NSCAssert([NSStringFromSelector(_cmd) isEqualToString:
                NSStringFromSelector(@selector(actionForKey:))],
            @"Invalid method signature.");

  MDMActionContext *context = [sActionContext lastObject];
  NSCAssert(context != nil, @"MotionAnimator action method invoked out of implicit scope.");

  BOOL shouldAnimateWithAnimator = [AllAnimatableKeyPaths() containsObject:event];
  if (context == nil || !shouldAnimateWithAnimator) {
    // Fall through to the original CALayer implementation.
    return ((id<CAAction>(*)(id, SEL, NSString *))sOriginalActionForKeyLayerImp)
              (layer, _cmd, event);
  }

  // We don't have access to the "to" value of our animation here, so we unfortunately can't
  // calculate additive values if the animator is configured as such. So, to support additive
  // animations, we queue up the modified actions and then add them all at the end of our
  // MDMAnimateImplicitly invocation.
  [context addActionForLayer:layer keyPath:event];
  return nil;
}

NSArray<MDMImplicitAction *> *MDMAnimateImplicitly(void (^work)(void)) {
  if (!work) {
    return nil;
  }

  SEL actionForKeySelector = @selector(actionForKey:);
  Method actionForKeyMethod = class_getInstanceMethod([CALayer class], actionForKeySelector);

  // This method can be called recursively, so we maintain a context stack in the scope of this
  // method. Note that this is absolutely not thread safe, but neither is Core Animation.
  if (!sActionContext) {
    sActionContext = [NSMutableArray array];

    // Swap the original CALayer implementation with our own so that we can intercept all
    // actionForKey: events.
    sOriginalActionForKeyLayerImp = method_setImplementation(actionForKeyMethod,
                                                             (IMP)ActionForKey);
  }

  [sActionContext addObject:[[MDMActionContext alloc] init]];

  work();

  // Return any intercepted actions we received during the invocation of work.
  MDMActionContext *context = [sActionContext lastObject];
  [sActionContext removeLastObject];

  if ([sActionContext count] == 0) {
    // Restore our original method if we've emptied the stack.
    method_setImplementation(actionForKeyMethod, sOriginalActionForKeyLayerImp);
    sOriginalActionForKeyLayerImp = nil;

    sActionContext = nil;
  }

  return context.interceptedActions;
}

@implementation MDMLayerDelegate

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
  // Check whether we're inside of an MDMAnimateImplicitly block or not.
  if (sOriginalActionForKeyLayerImp == nil) {
    return nil; // Tell Core Animation to Keep searching for an action provider.
  }
  return ActionForKey(layer, _cmd, event);
}

@end

@implementation MDMMotionAnimator (ImplicitLayerAnimations)

+ (id<CALayerDelegate>)sharedLayerDelegate {
  static MDMLayerDelegate *sharedInstance;
  @synchronized(self) {
    if (sharedInstance == nil) {
      sharedInstance = [[MDMLayerDelegate alloc] init];
    }
  }
  return sharedInstance;
}

@end
