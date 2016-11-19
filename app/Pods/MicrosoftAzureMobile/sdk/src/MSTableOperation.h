// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSTableOperation.h"

/**
 The MSTableOperation object represents a pending operation that was created by an earlier
 call using the MSSyncTable object. This is a wrapper to facilitate sending the operation
 to the server, handling any errors, and getting the appropriate local versions updated on
 completion
 */
@interface MSTableOperation : NSObject

/** The types of operations possible to perform. */
typedef NS_OPTIONS(NSUInteger, MSTableOperationTypes) {
    /** POST */
    MSTableOperationInsert = 0,
    /** PATCH */
    MSTableOperationUpdate,
    /** DELETE */
    MSTableOperationDelete
};

#pragma mark * Public Readonly Properties

/** @name Properties */

/** The action that should be taken for this table item, for example insert or update. */
@property (nonatomic, readonly) MSTableOperationTypes type;

/** The name of the table associated with the item */
@property (nonatomic, copy, readonly, nonnull) NSString *tableName;

/** The Id of the item the operation should run on. */
@property (nonatomic, copy, readonly, nonnull) NSString *itemId;

/** The item that will be sent to the server when execute is called. */
@property (nonatomic, strong, nullable) NSDictionary *item;

/** @name Sending an operation to the Mobile Service */

/**
 Perform's the associated PushOperationType (insert, etc) for the table item. The callback will be
 passed the result (an item on insert/update, the original deleted item on delete) or the error from 
 the mobile service.
 
 @param completion The completion block to execute when the table operation is done
 */
-(void) executeWithCompletion:(nullable void(^)(NSDictionary *__nonnull item, NSError *__nullable error))completion;

/** @name Canceling a Push operation */

/**
 Will cancel the operation's parent Push NSOperation and abort the push where it currently is. 
 
 Cancelling a running push operation, can cancel an operation while it has been sent to the server 
 and before a response is received. Such a case will cause a future conflict to occur the next time
 the client attempts to send that operation.
 */
- (void) cancelPush;

@end
