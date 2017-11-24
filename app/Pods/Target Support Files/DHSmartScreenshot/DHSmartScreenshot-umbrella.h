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

#import "DHSmartScreenshot.h"
#import "UIImage+DHImageAdditions.h"
#import "UIScrollView+DHSmartScreenshot.h"
#import "UITableView+DHSmartScreenshot.h"
#import "UIView+DHSmartScreenshot.h"

FOUNDATION_EXPORT double DHSmartScreenshotVersionNumber;
FOUNDATION_EXPORT const unsigned char DHSmartScreenshotVersionString[];

