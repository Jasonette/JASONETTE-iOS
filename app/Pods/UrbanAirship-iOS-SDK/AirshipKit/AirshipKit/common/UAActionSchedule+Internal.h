/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAActionSchedule.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UAActionSchedule
 */
@interface UAActionSchedule()

///---------------------------------------------------------------------------------------
/// @name Action Schedule Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The schedule's identifier.
 */
@property(nonatomic, copy) NSString *identifier;

/**
 * The schedule's information.
 */
@property(nonatomic, strong) UAActionScheduleInfo *info;

///---------------------------------------------------------------------------------------
/// @name Action Schedule Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create an action schedule.
 * @param identifier The schedule's identifier.
 * @param info The schedule's info.
 */
+ (instancetype)actionScheduleWithIdentifier:(NSString *)identifier info:(UAActionScheduleInfo *)info;

@end

NS_ASSUME_NONNULL_END
