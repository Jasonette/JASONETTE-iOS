// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MSTableOperation.h"

typedef void (^MSManagedObjectObserverCompletionBlock)(MSTableOperationTypes operationType,
                                                       NSDictionary *item,
                                                       NSError *error);

@class MSClient;

@interface MSManagedObjectObserver : NSObject

/// The MSCoreDataStore class is for use when using the offline capabilities
/// of mobile services. This class is a local store which manages records and sync
/// logic using CoreData.

- (instancetype) initWithClient:(MSClient *)client context:(NSManagedObjectContext *)context;

/// Block to be called on each operation that will is inserted into MS_TableOperations
///
/// If not implemented or not dealing with errors and errors occur during these operations
/// the local store and associated messages to the mobile services API will be left
/// in a bad state.
@property (nonatomic, copy) MSManagedObjectObserverCompletionBlock observerActionCompleted;

@end
