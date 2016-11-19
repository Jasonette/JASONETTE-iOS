// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@class MSQuery;
@class MSSyncContext;
@class MSTableOperation;
@class MSSyncContextReadResult;

/** 
 The MSSyncContextDelegate allows for customizing the handling of errors, conflicts, and other
 conditions that may occur when syncing data between the device and the mobile service.
 */

@protocol MSSyncContextDelegate <NSObject>

@optional

/** @name Handling Conflicts and Errors */

/**
 Allows for custom processing to be done before and after an item is sent to the server during
 the push process.

 *This method is optional*
 
 Called once for each entry on the queue, allowing for any adjustments to the item before it is sent 
 to the server, or custom handling of the server's response (such as conflict handling).
 
 Errors returned from this function will be collected and passed on as a group to the
 syncContext:onPushCompleteWithError:completion: method.
 
 Not passing an error when calling the completion block, will cause the code to consider the operation
 as successful and remove it from the queue. If an item is given that will be stored into the local
 database.
 
 @param operation gives the pending data (like item id, new values) along with the method to apply
                  that state to the server
 @param completion The MSSyncItemBlock block to use to send the results of the operation's execute 
                   to after applying any custom changes to the item or error.
 */
-(void) tableOperation:(nonnull MSTableOperation *)operation onComplete:(nonnull MSSyncItemBlock)completion;

/** 
 This method is called when all operations that were triggered due to a [pushWithCompletion:] call 
 have completed allowing custom processing to be done before results are returned to the caller.
 
 *This method is optional*
 
 If not provided, any errors will be passed along to the original caller of the push method.
 
 If provided, errors can be handled and additional changes may be made to the local or remote 
 database.
 
 @param context the MSSyncContext that triggered the push
 @param error An NSError containing the list of individual errors that occurred during the push
              process
 @param completion MSSyncPushCompletionBlock to trigger after all processing is complete. Any
                   unresolved errors will be passed along to the original push caller
 */
-(void) syncContext:(nonnull MSSyncContext *)context
onPushCompleteWithError:(nullable NSError *)error
         completion:(nonnull MSSyncPushCompletionBlock)completion;

@end

/**
 The MSSyncContextDataSource controls how data is stored and retrieved on the device. Errors returned from here will abort
 any given sync operation and will be surfaced to the mobile service through push or the delegate.
 */
@protocol MSSyncContextDataSource <NSObject>

/** @name Controlling Where Data is Stored */

/** Provides the name of the table to track all table operation meta data */
- (nonnull NSString *) operationTableName;

/** Provides the name of the table to track all table operation errors until they have been resolved. */
- (nonnull NSString *) errorTableName;

/** Provides the name of the table to track configuration data */
- (nonnull NSString *) configTableName;

/** 
 Indicates if the items passed to a sync table call should be saved by the SDK, if disabled, the local store will only
 recieve upserts/deletes for data calls originating from the server (pulls & pushes) plus the state tracking on the operation queue.
 */
@property (nonatomic) BOOL handlesSyncTableOperations;

/** @name Fetching and Retrieving Data */

/** 
 Should returns a result with the array of records matching the constraints specified in the
 provided query.
 
 @param query the MSQuery to evaluate to determine what records should be returned
 @param error should be set if an issue occurs while executing the query
 
 @returns An MSSyncContextReadResult with the records matched by the given query
 */
- (nullable MSSyncContextReadResult *) readWithQuery:(nullable MSQuery *)query
                                             orError:(NSError * __nullable * __nullable)error;

/**
 Should retrieve a single item from the local store or nil if item with the given ID does not
 exist.
 
 @param table the name of the table to get the record from
 @param itemId the id of the record to look up from the store
 @param error an NSError if an error occurs looking up the record. Should not be used to indicate
               the record could not be found.

 @returns item that was found, or nil
 */
-(nullable NSDictionary *) readTable:(nonnull NSString *)table
                          withItemId:(nonnull NSString *)itemId
                             orError:(NSError * __nullable * __nullable)error;

/**
 Should insert or update the given item(s) in the local store as appropriate

 @param items array of item records (represented by an NSDictionary) to add or update in the store
 @param table the name of the table to add or update the records in
 @param error an NSError if the requested records cannot be added or updated
 
 @returns boolean indicating if all records were upserted successfully
 */
-(BOOL) upsertItems:(nullable NSArray<NSDictionary *> *)items
              table:(nonnull NSString *)table
            orError:(NSError * __nullable * __nullable)error;

/**
 Should delete all records with the provided item ids from the local store. Item Ids that are not
 in the store should be considered deleted and not cause an error to occur.
 
 @param items array of item ids to delete from the store
 @param table the name of the table to delete records from
 @param error an NSError if the requests records failed to be deleted
 
 @returns boolean indicating if all records were deleted
 */
-(BOOL) deleteItemsWithIds:(nonnull NSArray<NSString *> *)items
                     table:(nonnull NSString *)table
                   orError:(NSError * __nullable * __nullable)error;

/**
 Should remove all entries returned by the provided query from the specified table in the local
 store

 @param query query that should be used to find records to be removed
 @param error error object to be set in the event an error occurs
 
 @returns Boolean indicating whether the delete was successful
 */
-(BOOL) deleteUsingQuery:(nonnull MSQuery *)query orError:(NSError * __nullable * __nullable)error;

@optional

/** @name Controlling System Properties */

/** 
 Returns the MSSystemProperties that have columns in the local database (example: createdAt, updatedAt)
 If not implemented, a default of version may be assumed
 
 *This property is optional*
 
 @param table name of the table to get system properties for
 
 @returns int representing the system properties on the table
 */
-(NSUInteger) systemPropertiesForTable:(nonnull NSString *)table;

@end

/** 
 The MSSyncContext object controls how offline operations using the MSSyncTable are processed,
 items are stored in local data storage, and how they are sent to the mobile app.
 */
@interface MSSyncContext : NSObject

/** @name Initializing the MSSyncContext Object */

/**
 Creates a new MSSyncContext using the given delegate, datasource, and callback queue

 @param delegate optional delegate to use to control actions during sync processes
 @param dataSource optional datasource to use to store items with
 @param callbackQueue optional queue to use for triggering callbacks related to sync on

 @returns the crreated MSSyncContext
 */
- (nonnull instancetype) initWithDelegate:(nullable id<MSSyncContextDelegate>)delegate
                               dataSource:(nullable id<MSSyncContextDataSource>) dataSource
                                 callback:(nullable NSOperationQueue *)callbackQueue;

/** @name Syncing and Storing Data */

/** Returns the number of pending outbound operations on the queue */
@property (nonatomic, readonly) NSUInteger pendingOperationsCount;

/** 
 Executes all current pending operations on the queue
 @param completion MSSyncBlock that will be triggered after all operations have been ran or a 
 terminal error, like no network connection occurs.
 @returns An NSOperation that wraps all the individual table operations being ran. The operation 
 will be finished after the completion block fires. Cancelling the NSOperation will stop any
 table operation in progress and abort running any additional ones.
 */
- (nonnull NSOperation *) pushWithCompletion:(nullable MSSyncBlock)completion;

/** Specifies the delegate that will be used in the resolution of syncing issues */
@property (nonatomic, strong, nullable) id<MSSyncContextDelegate> delegate;

/** Specifies the dataSource that owns the local data and store of operations */
@property (nonatomic, strong, nullable) id<MSSyncContextDataSource> dataSource;

@end
