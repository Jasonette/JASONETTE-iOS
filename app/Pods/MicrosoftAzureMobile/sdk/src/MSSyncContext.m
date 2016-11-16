// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSSyncContext.h"
#import "MSSyncContextInternal.h"
#import "MSClientInternal.h"
#import "MSTable.h"
#import "MSTableOperationInternal.h"
#import "MSJSONSerializer.h"
#import "MSQuery.h"
#import "MSQueryInternal.h"
#import "MSQueuePushOperation.h"
#import "MSQueuePullOperationInternal.h"
#import "MSQueuePurgeOperation.h"
#import "MSNaiveISODateFormatter.h"
#import "MSDateOffset.h"
#import "MSTableConfigValue.h"
#import "MSOperationQueue.h"
#import "MSOperationQueue.h"
#import "MSQueryResult.h"
#import "MSSyncContextReadResult.h"
#import "MSSyncTable.h"

@implementation MSSyncContext

static NSOperationQueue *pushQueue_;

@synthesize delegate = delegate_;
@synthesize dataSource = dataSource_;
@synthesize operationQueue = operationQueue_;
@synthesize client = client_;
@synthesize callbackQueue = callbackQueue_;

-(void) setClient:(MSClient *)client
{
    client_ = client;
    operationQueue_ = [[MSOperationQueue alloc] initWithClient:client_ dataSource:self.dataSource];

    // We don't need to wait for this, and all operation creation goes onto this queue so its
    // guaranteed to happen only after this is populated.
    dispatch_async(self.writeOperationQueue, ^{
        self.operationSequence = [self.operationQueue getNextOperationId];
    });
}

-(id) init
{
    return [self initWithDelegate:nil dataSource:nil callback:nil];
}

-(id) initWithDelegate:(id<MSSyncContextDelegate>) delegate dataSource:(id<MSSyncContextDataSource>) dataSource callback:(NSOperationQueue *)callbackQueue
{
    self = [super init];
    if (self)
    {
        _writeOperationQueue = dispatch_queue_create("WriteOperationQueue", DISPATCH_QUEUE_SERIAL);
        _readOperationQueue = dispatch_queue_create("ReadOperationQueue",  DISPATCH_QUEUE_CONCURRENT);

        callbackQueue_ = callbackQueue;
        if (!callbackQueue_) {
            callbackQueue_ = [[NSOperationQueue alloc] init];
            callbackQueue_.name = @"Sync Context: Operation Callbacks";
            callbackQueue_.maxConcurrentOperationCount = 4;
        }
        
        pushQueue_ = [NSOperationQueue new];
        pushQueue_.maxConcurrentOperationCount = 1;
        pushQueue_.name = @"Sync Context: Push";
        
        dataSource_ = dataSource;
        delegate_ = delegate;
    }
    
    return self;
}

/// Return the number of pending operations (including in progress)
-(NSUInteger) pendingOperationsCount
{
    return [self.operationQueue count];
}

/// Begin sending pending operations to the remote tables. Abort the push attempt whenever any single operation
/// recieves an error due to network or authorization. Otherwise operations will all run and all errors returned
/// to the caller at once.
-(NSOperation *) pushWithCompletion:(MSSyncBlock)completion
{
    MSQueuePushOperation *push = [[MSQueuePushOperation alloc] initWithSyncContext:self
                                                                     dispatchQueue:self.writeOperationQueue
                                                                     callbackQueue:self.callbackQueue
                                                                        completion:completion];
    
    [pushQueue_ addOperation:push];
    
    return push;
}


#pragma mark private interface implementation


/// Given an item and an action to perform (insert, update, delete) determines how that should be represented
/// when sent to the server based on pending operations.
-(void) syncTable:(NSString *)table
             item:(NSDictionary *)item
           action:(MSTableOperationTypes)action
       completion:(MSSyncItemBlock)completion
{
    NSError *error;
    NSMutableDictionary *itemToSave = [item mutableCopy];
    NSString *itemId;
    
    // Validate our input and state
    if (!self.dataSource) {
        error = [self errorWithDescription:@"Missing required datasource for MSSyncContext"
                              andErrorCode:MSSyncContextInvalid];
    } else {
        // All sync table operations require a valid string Id
        itemId = [self.client.serializer stringIdFromItem:item orError:&error];
        if (error) {
            if (error.code == MSMissingItemIdWithRequest && action == MSTableOperationInsert) {
                itemId = [MSJSONSerializer generateGUID];
                [itemToSave setValue:itemId forKey:@"id"];
                error = nil;
            }
        }
    }
    
    if (error) {
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                completion(nil, error);
            }];
        }
        return;
    }
    
    // Add the operation to the queue
    dispatch_async(self.writeOperationQueue, ^{
        NSError *error;
        MSCondenseAction condenseAction = MSCondenseAddNew;
        
        // Check if this table-item pair already has a pending operation and if so, how the new action
        // should be combined with the previous one
        NSArray<MSTableOperation *> *pendingActions = [self.operationQueue getOperationsForTable:table item:itemId];
        MSTableOperation *operation = [pendingActions lastObject];
        if (operation) {
            condenseAction = [MSTableOperation condenseAction:action withExistingOperation:operation];
            if (condenseAction == MSCondenseNotSupported) {
                error = [self errorWithDescription:@"The requested operation is not allowed due to an already pending operation"
                                      andErrorCode:MSSyncTableInvalidAction];
            }
        }
        
        if (condenseAction == MSCondenseAddNew) {
            operation = [MSTableOperation pushOperationForTable:table type:action itemId:itemId];
            operation.operationId = self.operationSequence;
            self.operationSequence++;
        }
        
        // Update local store and then the operation queue
        if (error == nil && self.dataSource.handlesSyncTableOperations) {
            switch (action) {
                case MSTableOperationInsert: {
                    // Check to see if this item already exists
                    NSString *itemId = itemToSave[MSSystemColumnId];
                    NSDictionary *result = [self.dataSource readTable:table withItemId:itemId orError:&error];
                    if (error == nil) {
                        if (result == nil) {
                            [self.dataSource upsertItems:@[itemToSave] table:table orError:&error];
                        } else {
                            error = [self errorWithDescription:@"This item already exists."
                                                  andErrorCode:MSSyncTableInvalidAction];
                        }
                    }
                    break;
                }
                case MSTableOperationUpdate:
                    [self.dataSource upsertItems:@[itemToSave] table:table orError:&error];
                    break;
                    
                case MSTableOperationDelete:
                    [self.dataSource deleteItemsWithIds:@[itemId] table:table orError:&error];
                    break;
                    
                default:
                    error = [self errorWithDescription:@"Unknown table action" andErrorCode:MSSyncTableInvalidAction];
                    break;
            }
        }
        
        if (error) {
            if (completion) {
                [self.callbackQueue addOperationWithBlock:^{
                    completion(nil, error);
                }];
            }
            return;
        }

        // Capture the deleted item in case the user wants to cancel it or a conflict occured
        if (action == MSTableOperationDelete) {
            // We want the deleted item, regardless of whether we are handling the actual item changes
            operation.item = item;
        }
        
        // Update the operation queue now
        if (condenseAction == MSCondenseAddNew) {
            [self.operationQueue addOperation:operation orError:&error];
        }
        else if (condenseAction == MSCondenseToDelete) {
            operation.type = MSTableOperationDelete;
            
            // TODO: Look at moving this upsert into the operation queue object
            [self.dataSource upsertItems:@[operation.serialize]
                                   table:self.dataSource.operationTableName
                                 orError:&error];
            
        } else if (condenseAction != MSCondenseKeep) {
            [self.operationQueue removeOperation:operation orError:&error];
        }
        
        // TODO: If an error occurs in updating the operation queue, we really should undo changes
        // to the local store if possible
        
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                if (error) {
                    completion(nil, error);
                } else {
                    completion(itemToSave, nil);
                }
            }];
        }
    });
}

/// Simple passthrough to the local storage data source to retrive a single item using its Id
- (void) syncTable:(NSString *)table readWithId:(NSString *)itemId completion:(MSItemBlock)completion {
    NSError *error;
    if (!self.dataSource) {
        error = [self errorWithDescription:@"Missing required datasource for MSSyncContext"
                              andErrorCode:MSSyncContextInvalid];
    }
    
    if (error) {
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                completion(nil, error);
            }];
        }
        return;
    }
    
    dispatch_async(self.readOperationQueue, ^{
        NSError *error;
        NSDictionary *item = [self.dataSource readTable:table withItemId:itemId orError:&error];
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                completion(item, error);
            }];
        }
    });
}

/// Assumes running with access to the operation queue
- (NSError *) removeOperation:(MSTableOperation *)operation
{
    NSError *error;
    [self.operationQueue removeOperation:operation orError:&error];
    return error;
}


/// Simple passthrough to the local storage data source to retrive a list of items
-(void)readWithQuery:(MSQuery *)query completion:(MSReadQueryBlock)completion {
    dispatch_async(self.readOperationQueue, ^{
        NSError *error;
        MSSyncContextReadResult *result = [self.dataSource readWithQuery:query orError:&error];
        
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                if (error) {
                    completion(nil, error);
                } else {
                    MSQueryResult *queryResult = [[MSQueryResult alloc] initWithItems:result.items
                                                                           totalCount:result.totalCount
                                                                             nextLink:nil];
                    completion(queryResult, nil);
                }
            }];
        }
    });
}

/// Given a pending operation in the queue, removes it from the queue and updates the local store
/// with the given item
- (void) cancelOperation:(MSTableOperation *)operation updateItem:(NSDictionary *)item completion:(MSSyncBlock)completion;
{
    // Removing an operation requires write access to the queue
    dispatch_async(self.writeOperationQueue, ^{
        NSError *error;
        
        // FUTURE: Verify operation hasn't been modified by others
        
        // Remove system properties but keep __version
        NSMutableDictionary *itemToSave = [item mutableCopy];
        
        NSString *version = [itemToSave objectForKey:MSSystemColumnVersion];
        [self.client.serializer removeSystemProperties:itemToSave];
        if (version != nil) {
            [itemToSave setValue:version forKey:MSSystemColumnVersion];
        }
        
        [self.dataSource upsertItems:@[itemToSave] table:operation.tableName orError:&error];
        if (!error) {
            [self.operationQueue removeOperation:operation orError:&error];
        }
        
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                completion(error);
            }];
        }
    });
}

/// Given a pending operation in the queue, removes it from the queue and removes the item from the local
/// store.
- (void) cancelOperation:(MSTableOperation *)operation discardItemWithCompletion:(MSSyncBlock)completion
{
    // Removing an operation requires write access to the queue
    dispatch_async(self.writeOperationQueue, ^{
        NSError *error;
        
        // FUTURE: Verify operation hasn't been modified by others
        
        [self.dataSource deleteItemsWithIds:@[operation.itemId]
                                      table:operation.tableName
                                    orError:&error];
        if (!error) {
            [self.operationQueue removeOperation:operation orError:&error];
        }
        
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                completion(error);
            }];
        }
    });
}

-(void) updateOperation:(MSTableOperation *)operation updateItem:(NSDictionary *)item completion:(MSSyncBlock)completion
{
    // updating an operation requires write access to the queue
    dispatch_async(self.writeOperationQueue, ^{
        NSError *error;
        
        if (operation.type == MSTableOperationDelete) {
            [self.dataSource deleteItemsWithIds:@[operation.itemId]
                                          table:operation.tableName
                                        orError:&error];
            operation.item = item;
        } else {
            [self.dataSource upsertItems:@[item] table:operation.tableName orError:&error];
            operation.item = nil;
        }
        
        if (!error) {
            [self.operationQueue updateOperation:operation orError:&error];
        }
        
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                completion(error);
            }];
        }
    });
}

/// Verify our input is valid and try to pull our data down from the server
- (NSOperation *) pullWithQuery:(MSQuery *)query queryId:(NSString *)queryId settings:(MSPullSettings *)pullSettings completion:(MSSyncBlock)completion;
{
    // make a copy since we'll be modifying it internally
    MSQuery *queryCopy = [query copy];
    
    if (!pullSettings) {
        pullSettings = [MSPullSettings new];
    }
    
    // We want to throw on unsupported fields so we can change this decision later
    NSError *error;
    NSDictionary *isDeletedParams = [MSSyncContext dictionary:queryCopy.parameters entriesForCaseInsensitiveKey:@"__includedeleted"];
    if (queryCopy.selectFields) {
        // Note: when this restriction is enabled, we may want to check that the select includes
        // system properties like __version for OC enabled tables, etc
        error = [self errorWithDescription:@"Use of selectFields in not supported in pullWithQuery:"
                              andErrorCode:MSInvalidParameter];
    }
    else if (queryCopy.includeTotalCount) {
        error = [self errorWithDescription:@"Use of includeTotalCount is not supported in pullWithQuery:"
                              andErrorCode:MSInvalidParameter];
    }
    else if (queryId && queryCopy.orderBy.count > 0) {
        error = [self errorWithDescription: @"Use of orderBy is not supported when a queryId is specified"
                              andErrorCode:MSInvalidParameter];
    }
    else if (queryId && (queryCopy.fetchOffset >= 0 || queryCopy.fetchLimit >= 0)) {
        error = [self errorWithDescription: @"Properties fetchOffset and fetchLimit are not supported when queryId is specified"
                              andErrorCode:MSInvalidParameter];
    }
    else if (queryCopy.syncTable) {
        // Otherwise we convert the sync table to a normal table
        queryCopy.table = [[MSTable alloc] initWithName:queryCopy.syncTable.name client:queryCopy.syncTable.client];
        queryCopy.syncTable = nil;
    }
    else if (!queryCopy.table) {
        // MSQuery itself should disallow this, but for safety verify we have a table object
        error = [self errorWithDescription:@"Missing required syncTable object in query"
                              andErrorCode:MSInvalidParameter];
    }
    
    if (!error && isDeletedParams.count > 0) {
        error = [self errorWithDescription:@"The '__includeDeleted' parameter is always true in pullWithQuery: and its value may not be overridden."
                              andErrorCode:MSInvalidParameter];
    }
    
    // Return error if possible, return on calling
    if (error) {
        if (completion) {
            [self.callbackQueue addOperationWithBlock:^{
                completion(error);
            }];
        }
        return nil;
    }
    
    // add __includeDeleted
    if (!queryCopy.parameters) {
        queryCopy.parameters = @{@"__includeDeleted" : @"true"};
    } else {
        NSMutableDictionary *mutableParameters = [queryCopy.parameters mutableCopy];
        [mutableParameters setObject:@"true" forKey:@"__includeDeleted"];
        queryCopy.parameters = mutableParameters;
    }
    
    if (queryId) {
        NSSortDescriptor *orderByUpdatedAt = [NSSortDescriptor sortDescriptorWithKey:MSSystemColumnUpdatedAt ascending:YES];
        queryCopy.orderBy = @[orderByUpdatedAt];
    }
    
    // For a Pull we treat fetchLimit as the total records we should pull by paging. If there is no fetchLimit, we pull everything.
    // We enforce a page size of |pullSettings.pageSize|
    NSInteger maxRecords = query.fetchLimit >= 0 ? query.fetchLimit : NSIntegerMax;
    queryCopy.fetchLimit = MIN(maxRecords, pullSettings.pageSize);
    
    // Begin the actual pull request
    return [self pullWithQueryInternal:queryCopy queryId:queryId maxRecords:maxRecords completion:completion];
}

/// Basic pull logic is:
///  Check if our table has pending operations, if so, push
///    If push fails, return error, else repeat while we have pending operations
///  Read from server using an MSQueuePullOperation
- (NSOperation *) pullWithQueryInternal:(MSQuery *)query queryId:(NSString *)queryId maxRecords:(NSInteger)maxRecords completion:(MSSyncBlock)completion
{
    MSQueuePullOperation *pull = [[MSQueuePullOperation alloc] initWithSyncContext:self
                                                                             query:query
                                                                           queryId:queryId
                                                                        maxRecords:maxRecords
                                                                     dispatchQueue:self.writeOperationQueue
                                                                     callbackQueue:self.callbackQueue
                                                                        completion:completion];
    
    dispatch_async(self.writeOperationQueue, ^{
        // Before we can pull from the remote, we need to make sure out table doesn't having pending operations
        NSArray<MSTableOperation *> *tableOps = [self.operationQueue getOperationsForTable:query.table.name item:nil];
        if (tableOps.count > 0) {
            NSOperation *push = [self pushWithCompletion:^(NSError *error) {
                // For now we just abort the pull if the push failed to complete successfully
                // Long term we can be smarter and check if our table succeeded
                if (error) {
                    [pull cancel];
					[pull completeOperation];
                    
                    if (completion) {
                        [self.callbackQueue addOperationWithBlock:^{
                            completion(error);
                        }];
                    }
                } else {
                    [pushQueue_ addOperation:pull];
                }
            }];
            
            [pull addDependency:push];
        } else {
            [pushQueue_ addOperation:pull];
        }
    });
    
    return pull;
}

/// In order to purge data from the local store, purge first checks if there are any pending operations for
/// the specific table on the query. If there are, no purge is performed and an error returned to the user.
/// Otherwise clear the local table of all macthing records
- (NSOperation *) purgeWithQuery:(MSQuery *)query completion:(MSSyncBlock)completion
{
    MSQueuePurgeOperation *purge = [[MSQueuePurgeOperation alloc] initPurgeWithSyncContext:self
                                                                                     query:query
                                                                                     force:NO
                                                                             dispatchQueue:self.writeOperationQueue
                                                                             callbackQueue:self.callbackQueue
                                                                                completion:completion];
    [pushQueue_ addOperation:purge];
    
    return purge;
}

/// Purges all data, pending operations, operation errors, and metadata for the
/// MSSyncTable from the local store.
-(NSOperation *) forcePurgeWithTable:(MSSyncTable *)syncTable completion:(MSSyncBlock)completion
{
    MSQuery *query = [[MSQuery alloc] initWithSyncTable:syncTable];
    MSQueuePurgeOperation *purge = [[MSQueuePurgeOperation alloc] initPurgeWithSyncContext:self
                                                                                     query:query
                                                                                     force:YES
                                                                             dispatchQueue:self.writeOperationQueue
                                                                             callbackQueue:self.callbackQueue
                                                                                completion:completion];
    [pushQueue_ addOperation:purge];
    
    return purge;
}

+ (BOOL) dictionary:(NSDictionary *)dictionary containsCaseInsensitiveKey:(NSString *)key
{
    for (NSString *object in dictionary.allKeys) {
        if ([object caseInsensitiveCompare:key] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

+ (NSDictionary *) dictionary:(NSDictionary *)dictionary entriesForCaseInsensitiveKey:(NSString *)key
{
    NSMutableDictionary *matches = [NSMutableDictionary dictionary];
    for (NSString *object in dictionary.allKeys) {
        if ([object caseInsensitiveCompare:key] == NSOrderedSame) {
            [matches setValue:dictionary[object] forKey:object];
        }
    }
    return matches;
}


# pragma mark * NSError helpers


-(NSError *) errorWithDescription:(NSString *)description
                     andErrorCode:(NSInteger)errorCode
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description };
    
    return [NSError errorWithDomain:MSErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}


@end
