/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAActionScheduleInfo.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains the schedule info and identifier.
 */
@interface UAActionSchedule : NSObject

///---------------------------------------------------------------------------------------
/// @name Action Schedule Properties
///---------------------------------------------------------------------------------------

/**
 * The schedule's identifier.
 */
@property(nonatomic, readonly) NSString *identifier;

/**
 * The schedule's information.
 */
@property(nonatomic, readonly) UAActionScheduleInfo *info;

///---------------------------------------------------------------------------------------
/// @name Action Schedule Management
///---------------------------------------------------------------------------------------

/**
 * Checks if the schedule is equal to another schedule.
 *
 * @param schedule The other schedule to compare against.
 * @return `YES` if the schedules are equal, otherwise `NO`.
 */
- (BOOL)isEqualToSchedule:(nullable UAActionSchedule *)schedule;

@end

NS_ASSUME_NONNULL_END
