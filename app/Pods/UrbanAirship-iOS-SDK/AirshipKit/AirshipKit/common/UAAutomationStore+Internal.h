/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

@class UAActionSchedule;
@class UAActionScheduleData;
@class UAScheduleTriggerData;
@class UAConfig;

/**
 * Manager class for the Automation CoreData store.
 */
@interface UAAutomationStore : NSObject

///---------------------------------------------------------------------------------------
/// @name Automation Store Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method for automation store.
 *
 * @param config The Urban Airship config.
 * @return Automation store.
 */
+ (instancetype)automationStoreWithConfig:(UAConfig *)config;

/**
 * Saves the UAActionSchedule to the data store.
 *
 * @param schedule The schedule to save.
 * @param limit The max number of schedules to allow.
 * @param completionHandler Completion handler when the operation is finished. `YES` if the
 * schedule was saved, `NO` if the schedule failed to save or the data store contains
 * more schedules then the specified limit.
 */
- (void)saveSchedule:(UAActionSchedule *)schedule limit:(NSUInteger)limit completionHandler:(void (^)(BOOL))completionHandler;

/**
 * Deletes schedules from the data store.
 *
 * @param predicate The predicate matcher.
 */
- (void)deleteSchedulesWithPredicate:(NSPredicate *)predicate;


/**
 * Fetches schedule data from the data store. The schedule data can only be modified
 * in the completion handler.
 *
 * @param predicate The predicate matcher.
 * @param limit The request's limit
 * @param completionHandler Completion handler with an array of the matching schedule data.
 */
- (void)fetchSchedulesWithPredicate:(NSPredicate *)predicate limit:(NSUInteger)limit completionHandler:(void (^)(NSArray<UAActionScheduleData *> *))completionHandler;

/**
 * Fetches trigger data from the data store. The trigger data can only be modified
 * in the completion handler.
 *
 * @param predicate The predicate matcher.
 * @param completionHandler Completion handler with an array of the matching trigger data.
 */
- (void)fetchTriggersWithPredicate:(NSPredicate *)predicate completionHandler:(void (^)(NSArray<UAScheduleTriggerData *> *))completionHandler;



@end
