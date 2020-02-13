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

#import "RMActionController.h"
#import "RMAction.h"
#import "RMImageAction.h"
#import "RMGroupedAction.h"
#import "RMScrollableGroupedAction.h"

FOUNDATION_EXPORT double RMActionControllerVersionNumber;
FOUNDATION_EXPORT const unsigned char RMActionControllerVersionString[];

