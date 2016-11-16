// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSQueuePushOperation.h"
#import "MSTableOperationError.h"
#import "MSSyncContextInternal.h"
#import "MSClientInternal.h"
#import "MSTableOperationInternal.h"
#import "MSQuery.h"
#import "MSOperationQueue.h"
#import "MSSyncTable.h"
#import "MSSyncContextReadResult.h"

@interface MSQueuePushOperation()

@property (nonatomic, strong) NSError *error;
@property (nonatomic, weak) dispatch_queue_t dispatchQueue;
@property (nonatomic, weak) MSSyncContext *syncContext;
@property (nonatomic, copy) MSSyncBlock completion;
@property (nonatomic, weak) NSOperationQueue *callbackQueue;
@property (nonatomic, strong) MSTableOperation* currentOp;

@end

@implementation MSQueuePushOperation

- (id) initWithSyncContext:(MSSyncContext *)syncContext
             dispatchQueue:(dispatch_queue_t)dispatchQueue
             callbackQueue:(NSOperationQueue *)callbackQueue
                completion:(MSSyncBlock)completion
{
    self = [super init];
    if (self) {
        _syncContext = syncContext;
        _dispatchQueue = dispatchQueue;
        _callbackQueue = callbackQueue;
        _completion = [completion copy];
        
    }
    return self;
}

- (void) completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    executing_ = NO;
    finished_ = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

// Check if the operation was cancelled and if so, begin winding down
-(BOOL) checkIsCanceled
{
    if (self.isCancelled) {
        self.error = [self errorWithDescription:@"Push cancelled" code:MSPushAbortedUnknown internalError:nil];
        [self pushComplete];
    }
    
    return self.isCancelled;
}

-(void) start
{
    if (finished_) {
        return;
    }
    else if (self.isCancelled) {
        [self pushComplete];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    executing_ = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    // For now, we process one operation at a time
    [self processQueueEntry];
}

/// Pick an operation up out of the queue until we run out of operations or find push
/// For each operation, attempt to send to the server and record the results until we
/// recieve a fatal error or we finish all pending operations
- (void) processQueueEntry
{
    dispatch_async(self.dispatchQueue, ^{
         if (self.currentOp) {
            NSInteger currentId = self.currentOp.operationId;
            self.currentOp = [self.syncContext.operationQueue getOperationAfter:currentId];
        } else {
            self.currentOp = [self.syncContext.operationQueue peek];
        }

        if (self.currentOp) {
            [self processTableOperation:self.currentOp];
            return;
        }
        
        [self pushComplete];
        return;
    });
}

/// For a given pending table operation, create the request to send it to the remote table
- (void) processTableOperation:(MSTableOperation *)operation
{
    // Lock table-item pair
    [self.syncContext.operationQueue lockOperation:operation];
    
    NSError *error;
    
    // Read the item from local store
    if (operation.type != MSTableOperationDelete) {
        operation.item = [self.syncContext.dataSource readTable:operation.tableName withItemId:operation.itemId orError:&error];
    }
    
    if (error) {
        NSString *errorMessage = [NSString stringWithFormat:@"Unable to read item '%@' from table '%@'", operation.itemId, operation.tableName];
        self.error = [self errorWithDescription:errorMessage code:MSPushAbortedDataSource internalError:error];
        [self.syncContext.operationQueue unlockOperation:operation];
        
        [self pushComplete];
        return;
    }
    
    if ([self checkIsCanceled]) {
        [self.syncContext.operationQueue unlockOperation:operation];
        return;
    }
    
    // Inserts need system properties removed
    if (operation.type == MSTableOperationInsert && operation.item) {
        NSMutableDictionary *item = [operation.item mutableCopy];
        [self.syncContext.client.serializer removeSystemProperties:item];
        operation.item = [item copy];
    }

    // Block to process the results of the table request and populate the appropriate data store
    id postTableOperation = ^(NSDictionary *item, NSError *error) {
        [self finishTableOperation:operation item:item error:error];
    };
    
    // Begin sending the table operation to the remote table
    operation.client = self.syncContext.client;
    operation.pushOperation = self;
    
    id<MSSyncContextDelegate> syncDelegate = self.syncContext.delegate;
    
    // Let go of the operation queue
    [self.callbackQueue addOperationWithBlock:^{
        if (syncDelegate && [syncDelegate respondsToSelector:@selector(tableOperation:onComplete:)]) {
            [syncDelegate tableOperation:operation onComplete:postTableOperation];
        } else {
            [operation executeWithCompletion:postTableOperation];
        }
    }];
}

/// Process the returned item/error from a call to a remote table. Update the local store state or cancel
/// the remaining operations as necessary
- (void) finishTableOperation:(MSTableOperation *)operation item:(NSDictionary *)item error:(NSError *)error
{
    // Check if we were cancelled while we awaited our results
    if ([self checkIsCanceled]) {
        [self.syncContext.operationQueue unlockOperation:operation];
        return;
    }

    // Remove the operation
    dispatch_async(self.dispatchQueue, ^{
        if (error) {
            NSHTTPURLResponse *response = [error.userInfo objectForKey:MSErrorResponseKey];
            BOOL didCondense = NO;
            
            // Determine if table-item operation is dirty (if so, ignore this operations response)
            // and condense any table-item logic since new actions can come in while this one is outgoing
            NSError *condenseError;
            didCondense = [self.syncContext.operationQueue condenseOperation:operation orError:&condenseError];
            if (condenseError) {
                self.error = [self errorWithDescription:@"Push aborted due to failure to condense operations in the store"
                                                   code:MSPushAbortedDataSource
                                          internalError:error];
            }
            
            if (response && response.statusCode == 401) {
                self.error = [self errorWithDescription:@"Push aborted due to authentication error"
                                                   code:MSPushAbortedAuthentication
                                          internalError:error];
            }
            else if ([error.domain isEqualToString:NSURLErrorDomain]) {
                self.error = [self errorWithDescription:@"Push aborted due to network error"
                                                   code:MSPushAbortedNetwork
                                          internalError:error];
            }
            else if (!didCondense) {
                MSTableOperationError *tableError = [[MSTableOperationError alloc] initWithOperation:operation
                                                                                                item:operation.item
                                                                                             context:self.syncContext
                                                                                               error:error];
                
                NSError *storeError;
                [self.syncContext.dataSource upsertItems:[NSArray arrayWithObject:[tableError serialize]]
                                                  table:[self.syncContext.dataSource errorTableName]
                                                orError:&storeError];
                if (storeError) {
                    self.error = [self errorWithDescription:@"Push aborted due to failure to save operation errors to store"
                                                       code:MSPushAbortedDataSource
                                              internalError:storeError];
                }
            }
        }
        else if (operation.type != MSTableOperationDelete && item != nil) {
            // The operation executed successfully, so save the item (if we have one)
            // and no additional changes have happened on this table-item pair
            NSError *storeError;
            if ([self.syncContext.operationQueue getOperationsForTable:operation.tableName
                                                                  item:operation.itemId].count <= 1) {
                [self.syncContext.dataSource upsertItems:[NSArray arrayWithObject:item]
                                                   table:operation.tableName
                                                 orError:&storeError];
                
                if (storeError) {
                    NSString *errorMessage = [NSString stringWithFormat:@"Unable to upsert item '%@' into table '%@'",
                                              operation.itemId, operation.tableName];
                    
                    self.error = [self errorWithDescription:errorMessage
                                                       code:MSPushAbortedDataSource
                                              internalError:storeError];
                }
            }
        }
        
        // our processing on the server response is complete, we can let others use it
        [self.syncContext.operationQueue unlockOperation:operation];
        
        // Check if any error we received requires aborting the push (Self.error will be set)
        if (self.error) {
            [self pushComplete];
            return;
        }
            
        // Remove our operation if it completed successfully
        if (!error) {
            NSError *storeError = [self.syncContext removeOperation:operation];
            if (storeError) {
                self.error = [self errorWithDescription:@"error removing successful operation from queue"
                                                   code:MSSyncTableInternalError
                                          internalError:error];
                [self pushComplete];
                return;
            }
        }
        
        [self processQueueEntry];
    });
}

/// When all operations are complete (with errors) or any one operation encountered a fatal error
/// this can be called to begin finalizing a push operation
-(void) pushComplete
{
    MSSyncTable *table = [[MSSyncTable alloc] initWithName:[self.syncContext.dataSource errorTableName]
                                                    client:self.syncContext.client];
    MSQuery *query = [[MSQuery alloc] initWithSyncTable:table];
    NSError *error;
    
    MSSyncContextReadResult *result = [self.syncContext.dataSource readWithQuery:query orError:&error];
    
    // remove all the errors now
    [self.syncContext.dataSource deleteUsingQuery:query orError:nil];
    
    // Create the containing error as needed
    if (result.items && result.items.count > 0) {
        NSMutableArray *tableErrors = [NSMutableArray new];
        for (NSDictionary *item in result.items) {
            [tableErrors addObject:[[MSTableOperationError alloc] initWithSerializedItem:item context:self.syncContext]];
        }
        
        if (self.error == nil) {
            self.error = [self errorWithDescription:@"Not all operations completed successfully"
                                               code:MSPushCompleteWithErrors
                                         pushErrors:tableErrors
                                      internalError:nil];
        } else {
            self.error = [self errorWithDescription:[self.error localizedDescription]
                                               code:self.error.code
                                         pushErrors:tableErrors
                                      internalError:[self.error.userInfo objectForKey:NSUnderlyingErrorKey]];
        }
    }
    
    // Send the final table operation results to the delegate
    id<MSSyncContextDelegate> syncDelegate = self.syncContext.delegate;
    [self.callbackQueue addOperationWithBlock:^{
        if (syncDelegate && [syncDelegate respondsToSelector:@selector(syncContext:onPushCompleteWithError:completion:)]) {
            [syncDelegate syncContext:self.syncContext onPushCompleteWithError:self.error completion:^{
                [self processErrors];
            }];
        } else {
            [self processErrors];
        }
    }];
}

/// Analyze the final errors from all the operations, updating the state as appropriate
- (void) processErrors
{
    if (self.error) {
        // Update core error to reflect any changes in push errors
        NSMutableDictionary *userInfo = [self.error.userInfo mutableCopy];
        
        NSArray *pushErrors = [userInfo objectForKey:MSErrorPushResultKey];
        NSMutableArray *remainingErrors = [[NSMutableArray alloc] init];
        for (MSTableOperationError *error in pushErrors) {
            // Remove any operations the delegate handled
            if (!error.handled) {
                [remainingErrors addObject:error];
            }
        }
        
        // Ajdust the error
        if (self.error.code == MSPushCompleteWithErrors && remainingErrors.count == 0) {
            self.error = nil;
        } else {
            self.error = [self errorWithDescription:[self.error localizedDescription]
                                               code:self.error.code
                                         pushErrors:remainingErrors
                                      internalError:[self.error.userInfo objectForKey:NSUnderlyingErrorKey]];
        }
    }
    
    if (self.completion) {
        [self.callbackQueue addOperationWithBlock:^{
            self.completion(self.error);
        }];
    }
    
    [self completeOperation];
}

/// Builds a NSError containing the errors related to a push operation
- (NSError *) errorWithDescription:(NSString *)description code:(NSInteger)code internalError:(NSError *)error
{
    NSMutableDictionary *userInfo = [@{ NSLocalizedDescriptionKey: description } mutableCopy];
    
    if (error) {
        [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    }
    
    return [NSError errorWithDomain:MSErrorDomain code:code userInfo:userInfo];
}

/// Builds a NSError containing the errors related to a push operation
-(NSError *) errorWithDescription:(NSString *)description code:(NSInteger)code pushErrors:(NSArray *)pushErrors internalError:(NSError *)error
{
    NSMutableDictionary *userInfo = [@{ NSLocalizedDescriptionKey: description } mutableCopy];
    
    if (error) {
        [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    }
    
    if (pushErrors && pushErrors.count > 0) {
        [userInfo setObject:pushErrors forKey:MSErrorPushResultKey];
    }
    
    return [NSError errorWithDomain:MSErrorDomain code:code userInfo:userInfo];
}

- (BOOL) isConcurrent {
    return YES;
}

- (BOOL) isExecuting {
    return executing_;
}

- (BOOL) isFinished {
    return finished_;
}

@end
