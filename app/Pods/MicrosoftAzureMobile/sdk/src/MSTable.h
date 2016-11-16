// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@class MSQuery;
@class MSClient;

typedef NS_OPTIONS(NSUInteger, MSSystemProperties) {
    MSSystemPropertyNone        = 0,
    MSSystemPropertyCreatedAt   = 1 << 0,
    MSSystemPropertyUpdatedAt   = 1 << 1,
    MSSystemPropertyVersion     = 1 << 2,
    MSSystemPropertyDeleted     = 1 << 3,
    MSSystemPropertyAll         = 0xFFFF
};

extern NSString * __nonnull const MSSystemColumnId;
extern NSString * __nonnull const MSSystemColumnCreatedAt;
extern NSString * __nonnull const MSSystemColumnUpdatedAt;
extern NSString * __nonnull const MSSystemColumnVersion;
extern NSString * __nonnull const MSSystemColumnDeleted;

#pragma mark * MSTable Public Interface

/**
 The MSTable class represents a table of an Azure Mobile App.
 
 Items can be inserted, updated, deleted and read from the table. The table can also be queried to 
 retrieve an array of items that meet the given query conditions. All table operations result in a 
 request to the Azure Mobile App server to perform the given operation.
 */

@interface MSTable : NSObject

#pragma mark * Public Readonly Properties

/** @name Properties */

/** The name of this table, request will be made to /table/{name} */
@property (nonatomic, copy, readonly, nonnull)           NSString *name;

/** The MSClient instance associated with this table. */
@property (nonatomic, strong, readonly, nonnull)         MSClient *client;

#pragma mark * Public Initializers

/** @name Initializing the MSTable Object */

/**
 Initializes an MSTable instance with the given name and client.
 @param tableName name of the table
 @param client The MSClient that will be used when making calls to the server
 @returns a new instance of the MSTable
 */
-(nonnull instancetype)initWithName:(nonnull NSString *)tableName client:(nonnull MSClient *)client;

#pragma mark * Public Insert, Update and Delete Methods

/** @name Modifying Items */

/**
 Sends a request to the Azure Mobile App  to insert the given item into the table. The item may have 
 an id only when using string ids.
 @param item An NSDictionary representation of the item to send to the server
 @param completion An MSItemBlock that will be fired after the server has processed the request
 */
-(void)insert:(nonnull NSDictionary *)item completion:(nullable MSItemBlock)completion;

/**
 Sends a request to the Azure Mobile App  to insert the given item into the table. The item may have
 an id only when using string ids. Additional user-defined parameters are sent in the request query 
 string.
 @param item A NSDictionary representation of the item to send to the server
 @param parameters A NSDictionary pairing of key values that will be converted to a querystring as
                   key1=value1&key2=value2
 @param completion An MSItemBlock that will be fired after the server has processed the request
 */
-(void)insert:(nonnull NSDictionary *)item
   parameters:(nullable NSDictionary *)parameters
   completion:(nullable MSItemBlock)completion;

/**
 Sends a request to the Azure Mobile App to update the given item in the table. Updates are done as
 a PATCH request to the request table. It is required for the specified item to have an 'id'.
 @param item A NSDictionary containing the fields to be updated on the server
 @param completion An MSItemBlock that will be fired after the server has processed the request
 */
-(void)update:(nonnull NSDictionary *)item completion:(nullable MSItemBlock)completion;

/**
 Sends a request to the Azure Mobile App to update the given item in the table. Updates are done as
 a PATCH request to the request table. It is required for the specified item to have an 'id'. If a
 'version' property is present, it will be sent as part of an if-match header to the server.
 @param item A NSDictionary containing the fields to be updated on the server
 @param parameters A NSDictionary pairing of key values that will be converted to a querystring as
 key1=value1&key2=value2
 @param completion An MSItemBlock that will be fired after the server has processed the request
 */
-(void)update:(nonnull NSDictionary *)item
   parameters:(nullable NSDictionary *)parameters
   completion:(nullable MSItemBlock)completion;

/**
 Sends a request to the Azure Mobile App to delete the given item from the table. The item must have
 an 'id' property.  If a 'version' property is present, an if-match header will also be sent with
 the request.
 @param item A NSDictionary representation of the item to be deleted
 @param completion An MSDeleteBlock that will be fired after the server has processed the request
 */
-(void)delete:(nonnull NSDictionary *)item completion:(nullable MSDeleteBlock)completion;


/**
 Sends a request to the Azure Mobile App to delete the given item from the table. The item must have
 an 'id' property. If a 'version' property is present, an if-match header will also be sent with
 the request. Additional user-defined parameters are sent in the request query string.
 @param item A NSDictionary representation of the item to be deleted
 @param parameters A NSDictionary pairing of key values that will be converted to a querystring as
 key1=value1&key2=value2
 @param completion An MSDeleteBlock that will be fired after the server has processed the request
 */
-(void)delete:(nonnull NSDictionary *)item
   parameters:(nullable NSDictionary *)parameters
   completion:(nullable MSDeleteBlock)completion;

/**
 Sends a request to the Azure Mobile App to delete the item with the given id from the table.
 @param itemId A NSString of NSNumber for the item to be deleted
 @param completion An MSDeleteBlock that will be fired after the server has processed the request
 */
-(void)deleteWithId:(nonnull id)itemId completion:(nullable MSDeleteBlock)completion;

/**
 Sends a request to the Azure Mobile App to delete the item with the given id from the table. 
 Additional user-defined parameters are sent in the request query string.
 @param itemId A NSString of NSNumber for the item to be deleted
 @param parameters A NSDictionary pairing of key values that will be converted to a querystring as
 key1=value1&key2=value2
 @param completion An MSDeleteBlock that will be fired after the server has processed the request
 */
-(void)deleteWithId:(nonnull id)itemId
         parameters:(nullable NSDictionary *)parameters
         completion:(nullable MSDeleteBlock)completion;

/**
 Sends a request to the Azure Mobile Service to undelete the item from the table. This requires the
 table to support soft delete. The item must have an 'id' property.  If a 'version' property is 
 present in the item, an if-match header will also be sent out on the request.
 @param item A NSDictionary representation of the item to be deleted
 @param completion An MSDeleteBlock that will be fired after the server has processed the request
 */
-(void)undelete:(nonnull NSDictionary *)item completion:(nullable MSItemBlock)completion;

/**
 Sends a request to the Azure Mobile Service to undelete the item from the table. This requires the
 table to support soft delete. The item must have an 'id' property.  If a 'version' property is
 present in the item, an if-match header will also be sent out on the request. Additional 
 user-defined parameters are sent in the request query string.
 @param item A NSDictionary representation of the item to be deleted
 @param parameters A NSDictionary pairing of key values that will be converted to a querystring as
 key1=value1&key2=value2
 @param completion An MSDeleteBlock that will be fired after the server has processed the request
 */
-(void)undelete:(nonnull NSDictionary *)item
     parameters:(nullable NSDictionary *)parameters
     completion:(nullable MSItemBlock)completion;

#pragma mark * Public Read Methods

/** @name Retreiving Items */

/**
 Sends a request to the Azure Mobile App to get the item with the specified id from the table.
 @param itemId An NSString or NSNumber that is the item id to lookup on the server
 @param completion A MSItemBlock that will be fired after the server has processed the request
 */
-(void)readWithId:(nonnull id)itemId completion:(nullable MSItemBlock)completion;

/**
 Sends a request to the Azure Mobile App to get the item with the specified id from the table.
 Additional user-defined parameters are sent in the request query string.
 @param itemId An NSString or NSNumber that is the item id to lookup on the server
 @param parameters A NSDictionary pairing of key values that will be converted to a querystring as
 key1=value1&key2=value2
 @param completion A MSItemBlock that will be fired after the server has processed the request
 */
-(void)readWithId:(nonnull id)itemId
       parameters:(nullable NSDictionary *)parameters
       completion:(nullable MSItemBlock)completion;

/**
 Sends a request to the Microsoft Azure Mobile Service to return all items from the table that meet 
 the conditions of the given query. You can also use a URI in place of queryString to fetch results 
 from a URI e.g. result.nextLink gives you URI to next page of results for a query that you can pass 
 here.
 @param queryString A querystring that will be appended to the GET request
 @param completion A MSReadQueryBlock that will be fired after the server has processed the request
 */
-(void)readWithQueryString:(nonnull NSString *)queryString
                completion:(nullable MSReadQueryBlock)completion;

/**
 Sends a request to the Azure Mobile App  to return all items from the table. The serevr will apply 
 a default limit to the number of items returned.
 @param completion A MSReadQueryBlock that will be fired after the server has processed the request
 */
-(void)readWithCompletion:(nullable MSReadQueryBlock)completion;

/**
 Sends a request to the Microsoft Azure Mobile Service to return all items from the table that meet 
 the conditions of the given predicate.
 @param predicate An NSPredicate that will be translated to an oData querystring and sent on the GET
 request.
 @param completion A MSReadQueryBlock that will be fired after the server has processed the request
 */
-(void)readWithPredicate:(nonnull NSPredicate *)predicate
              completion:(nullable MSReadQueryBlock)completion;

#pragma mark * Public Query Constructor Methods


/**
 Returns a MSQuery instance associated with the table that can be configured and then executed to 
 retrieve items from the table. An MSQuery instance provides more flexibilty when querying a tableA
 than the table read methods.
 */
-(nonnull MSQuery *)query;

/**
 Returns a MSQuery instance associated with the table that can be configured and then executed to
 retrieve items from the table. An MSQuery instance provides more flexibilty when querying a table
 than the table read methods.
 @param predicate A NSPredicate to use when creating the MSQuery instance.
 */
-(nonnull MSQuery *)queryWithPredicate:(nonnull NSPredicate *)predicate;

@end
