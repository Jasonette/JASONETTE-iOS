/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

/**
 * NSOperation that executes an asynchronous block.
 */
@interface UAAsyncOperation : NSOperation

///---------------------------------------------------------------------------------------
/// @name Async Operation Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAAsyncOperation operation. Once the
 * operation is finished, the block must call ``finish`` on the passed
 * in operation.
 *
 * @param block The async block to execute.
 * @return A UAAsyncOperation instance.
 */
+ (instancetype)operationWithBlock:(void (^)(UAAsyncOperation *))block;

///---------------------------------------------------------------------------------------
/// @name Async Operation Management
///---------------------------------------------------------------------------------------

/**
 * Called to start the async operation.
 */
- (void)startAsyncOperation;

/**
 * Call to finish the operation.
 */
- (void)finish;

@end
