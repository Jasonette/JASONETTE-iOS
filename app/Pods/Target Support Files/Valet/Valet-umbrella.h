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

#import "Valet.h"
#import "VALSecureEnclaveValet.h"
#import "VALSinglePromptSecureEnclaveValet.h"
#import "VALSynchronizableValet.h"
#import "VALValet.h"

FOUNDATION_EXPORT double ValetVersionNumber;
FOUNDATION_EXPORT const unsigned char ValetVersionString[];

