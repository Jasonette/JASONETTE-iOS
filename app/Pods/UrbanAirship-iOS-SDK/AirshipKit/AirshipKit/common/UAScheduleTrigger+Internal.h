/* Copyright 2017 Urban Airship and Contributors */

#import "UAScheduleTrigger.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UAScheduleTrigger
 */
@interface UAScheduleTrigger ()

///---------------------------------------------------------------------------------------
/// @name Schedule Trigger Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The trigger type.
 */
@property(nonatomic, assign) UAScheduleTriggerType type;

/**
 * The trigger's goal. Once the goal is reached it will cause the schedule
 * to execute its actions.
 */
@property(nonatomic, strong) NSNumber *goal;


/**
 * Custom event predicate to filter out events that are applied
 * to the trigger's count.
 */
@property(nonatomic, strong, nullable) UAJSONPredicate *predicate;

///---------------------------------------------------------------------------------------
/// @name Schedule Trigger Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create an app init trigger.
 */
+ (instancetype)triggerWithType:(UAScheduleTriggerType)type
                          goal:(NSNumber *)goal
                     predicate:(nullable UAJSONPredicate *)predicate;

@end

NS_ASSUME_NONNULL_END
