// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"
#import "MSTableOperation.h"

@class MSSyncContext;

/**
 The MSTableOperationError class represents an error that occurred while sending a a table 
 operation (insert, etc) to the Windows Azure Mobile Service during a sync event (for example a 
 Push.) The most common causes of a table operation error are non success codes from the
 server such as a precondition failed response.
 */
@interface MSTableOperationError : NSObject

/** @name Properties */

/** Unique error id in table store */
@property (nonatomic, readonly, nonnull) NSString *guid;

/** The name of the table the operation was being performed for */
@property (nonatomic, readonly, copy, nonnull) NSString *table;

/** The type of operation being performed on the table (insert, update, delete) */
@property (nonatomic, readonly) MSTableOperationTypes operation;

/** The id of the item to the operation ran for */
@property (nonatomic, readonly, copy, nonnull) NSString *itemId;

/** The item being sent to the server, this item may not always be present for all operations */
@property (nonatomic, readonly, copy, nullable) NSDictionary *item;

/** 
 Represents the error code received while executing the table operation, see MSError for a list of 
 Mobile App's error codes.
 */
@property (nonatomic, readonly) NSInteger code;

/**
 Represents the domain of the error recieved while executing the table operation, this will 
 typically be the MSErrorDomain, but may differ if the delegate chooses to return other error types.
 */
@property (nonatomic, readonly, nullable) NSString *domain;

/** A description of what caused the operation to fail */
@property (nonatomic, readonly, nonnull) NSString *description;

/**
 The HTTP status code recieved while executing the operation from the mobile service. Note:
 this item may not be set if the operation failed before going to the server.
 */
@property (nonatomic, readonly) NSInteger statusCode;

/**
 When the status code is a precondition failure, this item will contain the current version of the 
 item from the server.
 */
@property (nonatomic, readonly, nullable) NSDictionary *serverItem;

/** @name Handling Errors */

/** 
 Set the handled flag to indicate that all appropriate actions for this error have been taken and 
 the error will be removed from the list passed to the caller
 */
@property (nonatomic) BOOL handled;

/**
 Removes the pending operation so it will not be tried again the next time push is called. 
 In addition, updates the local store state with the specified item.
 
 Intended to be used to resolve conflicts in favor of the server. Do not call if changes for this
 item should still be sent up to the server.
 @param item NSDictionary representation of the item
 @param completion MSSyncBlock that will be fired after the operation has been removed and the local 
 table item has been modified.
 */
- (void) cancelOperationAndUpdateItem:(nonnull NSDictionary *)item
                           completion:(nullable MSSyncBlock)completion;

/**
 Removes the pending operation so it will not be tried again the next time push is called. In 
 addition, removes the item associated with the operation from the local store.

 @param completion MSSyncBlock to trigger after the item and operation have been removed.
 */
- (void) cancelOperationAndDiscardItemWithCompletion:(nullable MSSyncBlock)completion;

/**
 Updates the item that will be used the next time this operation is executed, typically due to
 another call to the Push method.
 @param item The NSDictionary representation of the item
 @param completion The MSSyncBlock to trigger after the table item have been updated in the store.
 */
- (void) keepOperationAndUpdateItem:(nonnull NSDictionary *)item completion:(nullable MSSyncBlock)completion;

/**
 Updates the operation's type so that the action taken next time push is called will be different.
 The most common usage is to convert an insert to an update when a conflict occurs. If the new type 
 is a delete, than the item will be removed from the local store as well.

 @param type The new operation type to take
 @param completion The MSSyncBlock to trigger after the operation has been updated in the store.
 */
- (void) modifyOperationType:(MSTableOperationTypes)type completion:(nullable MSSyncBlock)completion;

/**
 Updates both the operation type and the associated item in the local store. The next push will
 execute the new action type with the new updated item. If the new type is a delete, than the item
 will be removed from the local store as well.
 
 @param type The new operation type to take
 @param item The NSDictionary representation of the item
 @param completion The MSSyncBlock to trigger after the table item and operation type have been 
 updated in the store
 */
- (void) modifyOperationType:(MSTableOperationTypes)type
               AndUpdateItem:(nonnull NSDictionary *)item
                  completion:(nullable MSSyncBlock)completion;

/** @name Initializing the MSTableOperationError Object */

/**
 Initializes the table operation error from the provided operation, item, error, and context 
 objects.
 
 @param operation The MSTableOperation that was ran
 @param item NSDictionary representation of the item that was sent to the server
 @param context The MSSyncContext in use
 @param error An NSError detailing the error that occurred when running the operation.
 */
- (nonnull instancetype) initWithOperation:(nonnull MSTableOperation *)operation
                                      item:(nonnull NSDictionary *)item
                                   context:(nullable MSSyncContext *)context
                                     error:(nonnull NSError *) error;

/**
 DEPRECATED
 Initializes the table operation error from the provided operation, item, and error objects.
 Intended only for unit testing purposes.
 
 @param operation The MSTableOperation that was ran
 @param item NSDictionary representation of the item that was sent to the server
 @param error An NSError detailing the error that occurred when running the operation.
 */
- (nonnull instancetype) initWithOperation:(nonnull MSTableOperation *)operation
                                      item:(nonnull NSDictionary *)item
                                     error:(nonnull NSError *) error __deprecated;

/**
 Initializes the table operation error from a serialized representation of a MSTableOperationError.
 @param item The json representation of a MSTableOperationError object
 @param context The associated MSSyncContext to run actions on
 */
- (nonnull instancetype) initWithSerializedItem:(nonnull NSDictionary *)item context:(nullable MSSyncContext *)context;

/**
 DEPRECATED
 Initializes the table operation error from a serialized representation of a MSTableOperationError.
 Intended only for unit testing purposes.
 
 @param item The json representation of a MSTableOperationError object
 */
- (nonnull instancetype) initWithSerializedItem:(nonnull NSDictionary *)item __deprecated;

/** @name Serializing the MSTableOperationError Object */

/**
 Returns an NSDictionary with two keys, id and properties, where properties contains a serialized 
 version of the error.
 */
- (nonnull NSDictionary *) serialize;

@end
