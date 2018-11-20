/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An NSOperation that sleeps for a specified number of seconds before completing.
 *
 * This class is useful for scheduling delayed work or retry logic in an NSOperationQueue.
 */
@interface UADelayOperation : NSBlockOperation

/**
 * UADelayOperation class factory method.
 * @param seconds The number of seconds to sleep.
 */
+ (instancetype)operationWithDelayInSeconds:(NSTimeInterval)seconds;

/**
 * The amount of the the delay in seconds.
 */
@property (nonatomic, assign, readonly) NSTimeInterval seconds;

@end

NS_ASSUME_NONNULL_END
