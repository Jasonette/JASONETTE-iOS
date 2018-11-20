/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>


@interface NSOperationQueue(UAAdditions)

///---------------------------------------------------------------------------------------
/// @name Operation Queue Additions Methods
///---------------------------------------------------------------------------------------

/**
 * Adds an operation to the queue with a background task and a delay
 * operation dependency.
 * @param operation The operation to add.
 * @param delay The delay in seconds.
 */
- (BOOL)addBackgroundOperation:(NSOperation *)operation
                         delay:(NSTimeInterval)delay;

@end
