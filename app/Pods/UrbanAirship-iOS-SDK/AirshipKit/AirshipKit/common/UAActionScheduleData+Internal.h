/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN


@class UAScheduleDelayData;
@class UAScheduleTriggerData;

/**
 * CoreData class representing the backing data for
 * a UAActionSchedule.
 *
 * This class should not ordinarily be used directly.
 */
@interface UAActionScheduleData : NSManagedObject

///---------------------------------------------------------------------------------------
/// @name Action Schedule Data Properties
///---------------------------------------------------------------------------------------

/**
 * The schedule's identifier.
 */
@property (nullable, nonatomic, retain) NSString *identifier;

/**
 * The schedule's group.
 */
@property (nullable, nonatomic, retain) NSString *group;

/**
 * Number of times the actions will be triggered until the schedule is
 * canceled.
 */
@property (nullable, nonatomic, retain) NSNumber *limit;

/**
 * The number of times the action has been triggered.
 */
@property (nullable, nonatomic, retain) NSNumber *triggeredCount;

/**
 * Actions payload to run when the schedule is triggered represented
 * as a JSON string.
 */
@property (nullable, nonatomic, retain) NSString *actions;

/**
 * Set of triggers. Triggers define conditions on when to run
 * the actions.
 */
@property (nullable, nonatomic, retain) NSSet<UAScheduleTriggerData *> *triggers;

/**
 * The schedule's start time.
 */
@property (nullable, nonatomic, retain) NSDate *start;

/**
 * The schedule's end time. After the end time the schedule will be canceled.
 */
@property (nullable, nonatomic, retain) NSDate *end;

/**
 * The schedule's delay in seconds.
 */
@property (nullable, nonatomic, retain) UAScheduleDelayData *delay;

/**
 * Checks if the schedule's actions are pending execution.
 */
@property (nullable, nonatomic, retain) NSNumber *isPendingExecution;

/**
 * The delayed execution date. This delay date takes precedent over the delay in seconds.
 */
@property (nullable, nonatomic, retain) NSDate *delayedExecutionDate;

@end

NS_ASSUME_NONNULL_END
