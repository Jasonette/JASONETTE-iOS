// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSQueuePurgeOperation.h"
#import "MSTableOperationError.h"
#import "MSSyncContextInternal.h"
#import "MSClientInternal.h"
#import "MSTableOperationInternal.h"
#import "MSQuery.h"
#import "MSSyncContext.h"
#import "MSSyncContextInternal.h"
#import "MSClientInternal.h"
#import "MSQueryInternal.h"
#import "MSTableConfigValue.h"
#import "MSSyncTable.h"
#import "MSOperationQueue.h"

@interface MSQueuePurgeOperation()

@property (nonatomic, weak)     dispatch_queue_t dispatchQueue;
@property (nonatomic, weak)     NSOperationQueue *callbackQueue;
@property (nonatomic, weak)     MSSyncContext *syncContext;
@property (nonatomic, copy)     MSSyncBlock completion;
@property (nonatomic, strong)   MSQuery* query;
@property (nonatomic)           BOOL force;

@end

@implementation MSQueuePurgeOperation

- (id) initPurgeWithSyncContext:(MSSyncContext *)syncContext
                          query:(MSQuery *)query
                          force:(BOOL)force
                  dispatchQueue:(dispatch_queue_t)dispatchQueue
                  callbackQueue:(NSOperationQueue *)callbackQueue
                     completion:(MSSyncBlock)completion
{
    self = [super init];
    if (self) {
        _syncContext = syncContext;
        _query = query;
        _force = force;
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
        NSError *error = [self errorWithDescription:@"Purge cancelled" code:MSPullAbortedUnknown];
        [self callCompletionIfError:error];
    }
    
    return self.isCancelled;
}

-(void) start
{
    if (finished_) {
        return;
    }
    else if (self.isCancelled) {
        [self completeOperation];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    executing_ = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self processPurgeWithQueryOperation];
}

- (void) processPurgeWithQueryOperation
{
    if ([self checkIsCanceled]) {
        return;
    }
    
    // purge needs exclusive access to the storage layer
    dispatch_async(self.dispatchQueue, ^{
        NSError *error;
        
        if (self.force) {
            [self purgeOperationsOrError:&error];
            if ([self callCompletionIfError:error]) {
                return;
            }
            [self purgeDeltaTokensOrError:&error];
            if ([self callCompletionIfError:error]) {
                return;
            }
        }
        
        // Check if our table is dirty, if so, cancel the purge action
        // If 'force' is true, all operation were removed by the earlier call to purgeOperationsOrError
        NSArray *tableOps = [self.syncContext.operationQueue getOperationsForTable:self.query.syncTable.name item:nil];
        
        if (tableOps.count > 0) {
            error = [self errorWithDescription:@"The table cannot be purged because it has pending operations"
                                          code:MSPurgeAbortedPendingChanges];
        } else {
            // We can safely delete all items on this table (no pending operations)
            [self.syncContext.dataSource deleteUsingQuery:self.query orError:&error];
        }
        
        if (self.completion) {
            [self.callbackQueue addOperationWithBlock:^{
                self.completion(error);
            }];
        }
        [self completeOperation];
    });
}

/// Purges all pending operations in the operationQueue of the syncContext. This method must be called from the dispatchQueue.
- (void) purgeOperationsOrError:(NSError **)error
{
    // Check if our table is dirty
    NSArray *tableOps = [self.syncContext.operationQueue getOperationsForTable:self.query.syncTable.name item:nil];
    
    // delete operations one-by-one, which will cascade delete any errors
    for (int i = 0; i < tableOps.count; i++) {
        if ([self.syncContext.operationQueue isLocked:tableOps[i]]) {
            *error = [self errorWithDescription:@"The table cannot be purged because it has pending operations that have been sent to the server and not yet received a response"
                                           code:MSPurgeAbortedPendingChanges];
            break;
        }
        [self.syncContext.operationQueue removeOperation:tableOps[i] orError:error];
        
        if (error && *error) {
            break;
        }
    }
}

/// Purges all deltaTokens for the syncTable. This method must be called from the dispatchQueue.
- (void) purgeDeltaTokensOrError:(NSError **)error
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"table == %@ && keyType == %ld", self.query.syncTable.name, MSConfigKeyDeltaToken];
    MSSyncTable *configTable = [[MSSyncTable alloc] initWithName:self.syncContext.dataSource.configTableName client:self.query.syncTable.client];
    MSQuery *query = [[MSQuery alloc] initWithSyncTable:configTable predicate:predicate];
    [self.syncContext.dataSource deleteUsingQuery:query orError:error];
}

-(BOOL) callCompletionIfError:(NSError *)error
{
    BOOL isError = NO;
    if (error) {
        isError = YES;
        if (self.completion) {
            [self.callbackQueue addOperationWithBlock:^{
                self.completion(error);
            }];
        }
        [self completeOperation];
    }
    return isError;
}

- (NSError *) errorWithDescription:(NSString *)description code:(NSInteger)code
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description };
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
