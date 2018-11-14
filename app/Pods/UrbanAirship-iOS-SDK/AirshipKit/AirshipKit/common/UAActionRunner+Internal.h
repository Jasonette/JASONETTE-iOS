/* Copyright 2017 Urban Airship and Contributors */

#import "UAActionRunner.h"

NS_ASSUME_NONNULL_BEGIN

@interface UAActionRunner ()

/**
 * Runs all actions in a given dictionary. The dictionary's keys will be treated
 * as action names, while the values will be treated as each action's argument value.
 *
 * The results of all the actions will be aggregated into a
 * single UAAggregateActionResult.
 *
 * @param actionValues The map of action names to action values.
 * @param situation The action's situation.
 * @param metadata The action's metadata.
 * @param completionHandler CompletionHandler to call after all the
 * actions have completed. The result will be the aggregated result
 * of all the actions run.
 */
+ (void)runActionsWithActionValues:(NSDictionary *)actionValues
                         situation:(UASituation)situation
                          metadata:(nullable NSDictionary *)metadata
                 completionHandler:(nullable UAActionCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END

