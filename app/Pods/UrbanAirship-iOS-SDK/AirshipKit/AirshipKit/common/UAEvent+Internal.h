/* Copyright 2017 Urban Airship and Contributors */

#import "UAEvent.h"

/**
 * Represents the possible priorities for an event.
 */
typedef NS_ENUM(NSInteger, UAEventPriority) {
    /**
     * Low priority event. When added in the background, it will not schedule a send
     * if the last send was within 15 mins. Adding in the foreground will schedule
     * sends normally.
     */
    UAEventPriorityLow,

    /**
     * Normal priority event. Sends will be scheduled based on the batching time.
     */
    UAEventPriorityNormal,

    /**
     * High priority event. A send will be scheduled immediately.
     */
    UAEventPriorityHigh
};

NS_ASSUME_NONNULL_BEGIN

@interface UAEvent ()

///---------------------------------------------------------------------------------------
/// @name Event Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The time the event was created.
 */
@property (nonatomic, copy) NSString *time;

/**
 * The unique event ID.
 */
@property (nonatomic, copy) NSString *eventID;

/**
 * The event's data.
 */
@property (nonatomic, strong) NSDictionary *data;

/**
 * The event's priority.
 */
@property (nonatomic, readonly) UAEventPriority priority;

/**
 * The JSON event size in bytes.
 */
@property (nonatomic, readonly) NSUInteger jsonEventSize;

///---------------------------------------------------------------------------------------
/// @name Event Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Gets the carrier's name.
 * @returns The carrier's name.
 */
- (NSString *)carrierName;

/**
 * Gets the current enabled notification types as a string array.
 *
 * @return The current notification types as a string array.
 */
- (NSArray *)notificationTypes;


@end

NS_ASSUME_NONNULL_END
