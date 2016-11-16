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

#import "CYRLayoutManager.h"
#import "CYRTextStorage.h"
#import "CYRTextView.h"
#import "CYRToken.h"

FOUNDATION_EXPORT double CYRTextViewVersionNumber;
FOUNDATION_EXPORT const unsigned char CYRTextViewVersionString[];

