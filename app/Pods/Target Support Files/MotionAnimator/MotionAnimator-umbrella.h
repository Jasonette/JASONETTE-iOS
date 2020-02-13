#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CATransaction+MotionAnimator.h"
#import "MDMAnimatableKeyPaths.h"
#import "MDMCoreAnimationTraceable.h"
#import "MDMMotionAnimator.h"
#import "MotionAnimator.h"

FOUNDATION_EXPORT double MotionAnimatorVersionNumber;
FOUNDATION_EXPORT const unsigned char MotionAnimatorVersionString[];

