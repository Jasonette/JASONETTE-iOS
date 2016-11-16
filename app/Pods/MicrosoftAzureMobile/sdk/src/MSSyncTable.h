// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@class MSClient;
@class MSQuery;
#import "MSPullSettings.h"
#import "MSSyncContext.h"

@class MSQueuePullOperation;
@class MSQueuePurgeOperation;

/**
 The MSSyncTable class represents a table of a Microsoft Azure Mobile App. Items can be inserted, 
 updated, deleted and read from the table. The table can also be queried to retrieve an array of 
 items that meet the given query conditions. All table operations result in a request to the local 
 store and an eventual request to the server (see the MSSyncContext for more details).
 */
@interface MSSyncTable : NSObject

/** @name Properties */

/** The name of this table. */
@property (nonatomic, copy, readonly, nonnull)           NSString *name;

/** The client associated with this table. */
@property (nonatomic, strong, readonly, nonnull)         MSClient *client;

/** @name Initializing the MSTable Object */

/**
 Initializes an MSTable instance with the given name and client.
 @param tableName The name of the table to perform actions on
 @param client The MSClient to use
 */
-(nonnull instancetype)initWithName:(nonnull NSString *)tableName client:(nonnull MSClient *)client;

/** @name Modifying Items */

/** 
 Sends a request to the MSSyncContext's data source to upsert the given item into the local store. 
 In addition queues a request to send the insert to the server.
 @param item NSDictionary representation of the item
 @param completion The MSSyncItemBlock to invoke after the operation has been sent to the store
 */
-(void)insert:(nonnull NSDictionary *)item completion:(nullable MSSyncItemBlock)completion;

/**
 Sends a request to the MSSyncContext's data source to upsert the given item into the local store. 
 In addition queues a request to send the update  to the server.
 @param item NSDictionary representation of the item
 @param completion The MSSyncItemBlock to invoke after the operation has been sent to the store
 */
-(void)update:(nonnull NSDictionary *)item completion:(nullable MSSyncBlock)completion;

/**
 Sends a request to the MSSyncContext's data source to delete the given item in the local store. In 
 addition queues a request to send the delete to the server.
 @param item NSDictionary representation of the item
 @param completion The MSSyncBlock to invoke after the operation has been sent to the store
 */
-(void)delete:(nonnull NSDictionary *)item completion:(nullable MSSyncBlock)completion;

#pragma mark * Public Read Methods

/** @name Retreiving Local Items */

/**
 Gets a record with the given id from the local store's table.
 @param itemId NSString representation of the record's Id
 @param completion The MSItemBlock to invoke after the record is fetched
 */
-(void)readWithId:(nonnull NSString *)itemId completion:(nullable MSItemBlock)completion;

/**
 Performs a read against the local store to get all items from the table
 @param completion The MSReadQueryBlock that will be invoked with the results
 */
-(void)readWithCompletion:(nullable MSReadQueryBlock)completion;

/**
 Performs a search against the local store for all items from the table that meet the conditions of
 the given predicate.
 @param predicate NSPredicate specifying the filter to apply
 @param completion The MSReadQueryBlock that will be invoked with the results
 */
-(void)readWithPredicate:(nullable NSPredicate *)predicate
              completion:(nullable MSReadQueryBlock)completion;

#pragma mark * Public Query Constructor Methods

/**
 Returns a MSQuery instance associated with the table that can be configured and then executed to 
 retrieve items from the table. A MSQuery instance provides more flexibilty when querying a table 
 than the table read methods.
 */
-(nonnull MSQuery *)query;

/**
 Returns a MSQuery instance associated with the table that can be configured and then executed to
 retrieve items from the table. The MSQuery will be configured to use the provided NSPredicate for
 filtering the results.
 @param predicate NSPredicate specifying the filter to apply
 */
-(nonnull MSQuery *)queryWithPredicate:(nullable NSPredicate *)predicate;

/** @name Managing local storage */

/**
 Initiates a request to go to the server and get a set of records matching the specified MSQuery 
 object. Before a pull is allowed to run, one operation to send all pending requests on the
 specified table will be sent to the server. If a pending request for this table fails, the pull 
 will be cancelled
 @param query The MSQuery used to filter the results on the server
 @param queryId If passed, will be used to allow the pull to continue from where it left off. When
 nil, all records matching the query will be returned from the server.
 @param completion A MSSyncBlock that will be invoked when the pull process finishes
 @returns A NSOperation that will finish once all records are fetched or the pull is cancelled
 */
-(nullable NSOperation *)pullWithQuery:(nullable MSQuery *)query
                               queryId:(nullable NSString *)queryId
                            completion:(nullable MSSyncBlock)completion;

/**
 Initiates a request to go to the server and get a set of records matching the specified MSQuery 
 object. Before a pull is allowed to run, one operation to send all pending requests on the
 specified table will be sent to the server. If a pending request for this table fails,
 the pull will be cancelled
 @param query The MSQuery used to filter the results on the server
 @param queryId If passed, will be used to allow the pull to continue from where it left off. When
 nil, all records matching the query will be returned from the server.
 @param pullSettings Additional settings that control the behavior of the pull, like the page size
 @param completion A MSSyncBlock that will be invoked when the pull process finishes
 @returns A NSOperation that will finish once all records are fetched or the pull is cancelled
 */
-(nullable NSOperation *)pullWithQuery:(nullable MSQuery *)query
                               queryId:(nullable NSString *)queryId
                              settings:(nullable MSPullSettings *)pullSettings
                            completion:(nullable MSSyncBlock)completion;

/**
 Removes all records in the local cache that match the results of the specified query. If query is 
 nil, all records in the local table will be removed. Before local data is removed, a check will be 
 made for pending operations on this table. If any are found the purge will be cancelled and an 
 error returned instead.
 @param query When passed only records matching the query will be removed
 @param completion A MSSyncBlock that will be invoked when the pull process finishes
 @returns A NSOperation that will finish once all records are purged or the purge is cancelled
 */
-(nonnull NSOperation *)purgeWithQuery:(nullable MSQuery *)query completion:(nullable MSSyncBlock)completion;

/**
 Purges all data, pending operations, operation errors, and metadata for the MSSyncTable from the 
 local cache.
 @param completion A MSSyncBlock that will be invoked when the pull process finishes
 @returns A NSOperation that will finish once all records are purged or the purge is cancelled
 */
-(nonnull NSOperation *)forcePurgeWithCompletion:(nullable MSSyncBlock)completion;

/// @}

@end
