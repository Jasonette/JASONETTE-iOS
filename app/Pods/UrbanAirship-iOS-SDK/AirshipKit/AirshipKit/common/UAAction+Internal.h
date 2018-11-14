/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface UAAction ()

///---------------------------------------------------------------------------------------
/// @name Action Internal Properties
///---------------------------------------------------------------------------------------

/**
 * A block defining the primary work performed by an action.
 * In the base class, this block is executed by the default implementation of
 * [UAAction performWithArguments:withCompletionHandler:]
 */
@property (nonatomic, copy, nullable) UAActionBlock actionBlock;

/**
 * A block that indicates whether the action is willing to accept the provided arguments.
 * In the base class, this block is executed by the default implementation of
 * [UAAction acceptsArguments:]
 */
@property (nonatomic, copy, nullable) UAActionPredicate acceptsArgumentsBlock;

///---------------------------------------------------------------------------------------
/// @name Action Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Performs the action, with pre/post execution calls, if it accepts the provided arguments.
 *
 * If the arguments are accepted, this method will also call
 * [UAAction willPerformWithArguments:] and
 * [UAAction didPerformWithArguments:withResult:]
 * before and after the perform method, respectively.
 *
 * @param arguments The action's arguments.
 * @param completionHandler CompletionHandler when the action is finished.
 */
- (void)runWithArguments:(UAActionArguments *)arguments
       completionHandler:(UAActionCompletionHandler)completionHandler;


@end

NS_ASSUME_NONNULL_END
