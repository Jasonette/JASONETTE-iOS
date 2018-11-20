/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAActionResult.h"
#import "UAAction.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Convenience class for aggregating and merging multiple UAActionResults.
 */
@interface UAAggregateActionResult : UAActionResult

///---------------------------------------------------------------------------------------
/// @name Aggregate Action Result Core Methods
///---------------------------------------------------------------------------------------

/**
 * Adds a new result, merging with the existing result.
 *
 * @param result The result to add.
 * @param actionName The name of the action that produced the result.
 */
- (void)addResult:(UAActionResult *)result forAction:(NSString *)actionName;


/**
 * Gets the results for an action
 *
 * @param actionName Name of the action
 * @return UAActionResult for the action
 */
- (UAActionResult *)resultForAction:(NSString*)actionName;

@end

NS_ASSUME_NONNULL_END
