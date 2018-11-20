/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAAction.h"
#import "UAActionRegistry.h"
#import "UAAggregateActionResult.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A helper class for running actions by name or by reference.
 */
@interface UAActionRunner : NSObject

///---------------------------------------------------------------------------------------
/// @name Action Runner Core Methods
///---------------------------------------------------------------------------------------

/**
 * Runs a registered action with the given name.
 *
 * If the action is not registered the completion handler
 * will be called immediately with [UAActionResult emptyResult]
 *
 * @param actionName The name of the action to run
 * @param value The action's argument value.
 * @param situation The action's situation.
 */
+ (void)runActionWithName:(NSString *)actionName
                    value:(nullable id)value
                situation:(UASituation)situation;

/**
 * Runs a registered action with the given name.
 *
 * If the action is not registered the completion handler
 * will be called immediately with [UAActionResult emptyResult]
 *
 * @param actionName The name of the action to run
 * @param value The action's argument value.
 * @param situation The action's situation.
 * @param metadata The action's metadata.
 */
+ (void)runActionWithName:(NSString *)actionName
                    value:(nullable id)value
                situation:(UASituation)situation
                 metadata:(NSDictionary *)metadata;

/**
 * Runs a registered action with the given name.
 *
 * If the action is not registered the completion handler
 * will be called immediately with [UAActionResult emptyResult]
 *
 * @param actionName The name of the action to run
 * @param value The action's argument value.
 * @param situation The action's situation.
 * @param completionHandler Optional completion handler to run when the action completes.
 */
+ (void)runActionWithName:(NSString *)actionName
                    value:(nullable id)value
                situation:(UASituation)situation
        completionHandler:(UAActionCompletionHandler)completionHandler;

/**
 * Runs a registered action with the given name.
 *
 * If the action is not registered the completion handler 
 * will be called immediately with [UAActionResult emptyResult]
 *
 * @param actionName The name of the action to run
 * @param value The action's argument value.
 * @param situation The action's situation.
 * @param metadata The action's metadata.
 * @param completionHandler Optional completion handler to run when the action completes.
 */
+ (void)runActionWithName:(NSString *)actionName
                value:(nullable id)value
            situation:(UASituation)situation
             metadata:(nullable NSDictionary *)metadata
    completionHandler:(nullable UAActionCompletionHandler)completionHandler;



/**
 * Runs an action.
 *
 * @param action The action to run
 * @param value The action's argument value.
 * @param situation The action's situation.
 */
+ (void)runAction:(UAAction *)action
            value:(nullable id)value
        situation:(UASituation)situation;

/**
 * Runs an action.
 *
 * @param action The action to run
 * @param value The action's argument value.
 * @param situation The action's situation.
 * @param metadata The action's metadata.
 */
+ (void)runAction:(UAAction *)action
            value:(nullable id)value
        situation:(UASituation)situation
         metadata:(nullable NSDictionary *)metadata;

/**
 * Runs an action.
 *
 * @param action The action to run
 * @param value The action's argument value.
 * @param situation The action's situation.
 * @param completionHandler Optional completion handler to run when the action completes.
 */
+ (void)runAction:(UAAction *)action
            value:(nullable id)value
        situation:(UASituation)situation
completionHandler:(UAActionCompletionHandler)completionHandler;


/**
 * Runs an action.
 *
 * @param action The action to run
 * @param value The action's argument value.
 * @param situation The action's situation.
 * @param metadata The action's metadata.
 * @param completionHandler Optional completion handler to run when the action completes.
 */
+ (void)runAction:(UAAction *)action
            value:(nullable id)value
        situation:(UASituation)situation
         metadata:(nullable NSDictionary *)metadata
completionHandler:(nullable UAActionCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
