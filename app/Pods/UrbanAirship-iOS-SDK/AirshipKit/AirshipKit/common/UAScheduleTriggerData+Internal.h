/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UAActionScheduleData;
@class UAScheduleDelayData;

NS_ASSUME_NONNULL_BEGIN

/**
 * CoreData class representing the backing data for
 * a UAScheduleTrigger.
 *
 * This class should not ordinarily be used directly.
 */
@interface UAScheduleTriggerData : NSManagedObject

///---------------------------------------------------------------------------------------
/// @name Schedule Trigger Properties
///---------------------------------------------------------------------------------------

/**
 * The trigger's goal. Once the goal is reached it will cause the schedule
 * to execute its actions.
 */
@property (nullable, nonatomic, retain) NSNumber *goal;

/**
 * The number of times the trigger has been executed. Is reset to 0 
 * when goal is reached.
 */
@property (nullable, nonatomic, retain) NSNumber *goalProgress;

/**
 * Custom event predicate to filter out events that are applied
 * to the trigger's count represented as JSON data.
 */
@property (nullable, nonatomic, retain) NSData *predicateData;

/**
 * The trigger type.
 */
@property (nullable, nonatomic, retain) NSNumber *type;

/**
 * The action schedule data.
 */
@property (nullable, nonatomic, retain) UAActionScheduleData *schedule;

/**
 * The schedule delay data.
 */
@property (nullable, nonatomic, retain) UAScheduleDelayData *delay;

/**
 * The schedule's start time.
 */
@property (nullable, nonatomic, retain) NSDate *start;

@end

NS_ASSUME_NONNULL_END
