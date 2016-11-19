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

#import "MicrosoftAzureMobile.h"
#import "MSBlockDefinitions.h"
#import "MSClient.h"
#import "MSCoreDataStore.h"
#import "MSDateOffset.h"
#import "MSError.h"
#import "MSFilter.h"
#import "MSManagedObjectObserver.h"
#import "MSPullSettings.h"
#import "MSConnectionConfiguration.h"
#import "MSPush.h"
#import "MSQuery.h"
#import "MSQueryResult.h"
#import "MSSyncContext.h"
#import "MSSyncContextReadResult.h"
#import "MSSyncTable.h"
#import "MSTable.h"
#import "MSTableOperation.h"
#import "MSTableOperationError.h"
#import "MSUser.h"
#import "MSLoginController.h"

FOUNDATION_EXPORT double MicrosoftAzureMobileVersionNumber;
FOUNDATION_EXPORT const unsigned char MicrosoftAzureMobileVersionString[];

