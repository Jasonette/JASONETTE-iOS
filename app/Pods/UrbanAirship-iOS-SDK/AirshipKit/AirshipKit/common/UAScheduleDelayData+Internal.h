/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UAActionScheduleData;
@class UAScheduleDelayConditionsData;
@class UAScheduleTriggerData;

NS_ASSUME_NONNULL_BEGIN

/**
 * CoreData class representing the backing data for
 * a UAScheduleDelayData.
 *
 * This class should not ordinarily be used directly.
 */
@interface UAScheduleDelayData : NSManagedObject

///---------------------------------------------------------------------------------------
/// @name Schedule Delay Data Internal Properties
///---------------------------------------------------------------------------------------

/**
 * Minimum amount of time to wait in seconds before the schedule actions are able to execute.
 */
@property (nullable, nonatomic, retain) NSNumber *seconds;

/**
 * Specifies the name of an app screen that the user must currently be viewing before the
 * the schedule's actions are able to be executed. Specifying a screen requires the application
 * to make use of UAAnalytic's screen tracking method `trackScreen:`.
 */
@property (nullable, nonatomic, retain) NSString *screen;

/**
 * Specifies the ID of a region that the device must currently be in before the schedule's
 * actions are able to be executed. Specifying regions requires the application to add UARegionEvents
 * to UAAnalytics.
 */
@property (nullable, nonatomic, retain) NSString *regionID;

/**
 * Specifies the app state that is required before the schedule's actions are able to execute.
 * Defaults to `UAScheduleDelayAppStateAny`.
 */
@property (nullable, nonatomic, retain) NSNumber *appState;

/**
 * The action schedule data.
 */
@property (nullable, nonatomic, retain) UAActionScheduleData *schedule;

/**
 * The cancellation triggers.
 */
@property (nullable, nonatomic, retain) NSSet<UAScheduleTriggerData *> *cancellationTriggers;

@end

NS_ASSUME_NONNULL_END
