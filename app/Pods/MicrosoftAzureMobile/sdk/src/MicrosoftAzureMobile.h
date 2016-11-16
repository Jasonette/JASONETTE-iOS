// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#ifndef MicrosoftAzureMobile_MicrosoftAzureMobile_h
#define MicrosoftAzureMobile_MicrosoftAzureMobile_h

#import "MSBlockDefinitions.h"
#import "MSClient.h"
#import "MSCoreDataStore.h"
#import "MSDateOffset.h"
#import "MSError.h"
#import "MSFilter.h"
#if TARGET_OS_IPHONE
#import "MSLoginController.h"
#endif
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

#define MicrosoftAzureMobileSdkMajorVersion 3
#define MicrosoftAzureMobileSdkMinorVersion 2
#define MicrosoftAzureMobileSdkBuildVersion 0

#endif
