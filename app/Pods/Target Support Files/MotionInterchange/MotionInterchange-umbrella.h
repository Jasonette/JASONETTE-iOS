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

#import "CAMediaTimingFunction+MDMTimingCurve.h"
#import "MDMAnimationTraits.h"
#import "MDMMotionCurve.h"
#import "MDMMotionRepetition.h"
#import "MDMMotionTiming.h"
#import "MDMRepetition.h"
#import "MDMRepetitionOverTime.h"
#import "MDMRepetitionTraits.h"
#import "MDMSpringTimingCurve.h"
#import "MDMSpringTimingCurveGenerator.h"
#import "MDMSubclassingRestricted.h"
#import "MDMTimingCurve.h"
#import "MotionInterchange.h"

FOUNDATION_EXPORT double MotionInterchangeVersionNumber;
FOUNDATION_EXPORT const unsigned char MotionInterchangeVersionString[];

