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

#import "AFHTTPRequestSerializer+OAuth2.h"
#import "AFOAuth2Manager.h"
#import "AFOAuthCredential.h"

FOUNDATION_EXPORT double AFOAuth2ManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char AFOAuth2ManagerVersionString[];

