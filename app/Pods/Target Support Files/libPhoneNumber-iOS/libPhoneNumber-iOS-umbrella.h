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

#import "NBPhoneNumberDefines.h"
#import "NBPhoneNumber.h"
#import "NBNumberFormat.h"
#import "NBPhoneNumberDesc.h"
#import "NBPhoneMetaData.h"
#import "NBPhoneNumberUtil.h"
#import "NBMetadataHelper.h"
#import "NBAsYouTypeFormatter.h"
#import "NSArray+NBAdditions.h"
#import "NBRegExMatcher.h"
#import "NBRegularExpressionCache.h"

FOUNDATION_EXPORT double libPhoneNumber_iOSVersionNumber;
FOUNDATION_EXPORT const unsigned char libPhoneNumber_iOSVersionString[];

