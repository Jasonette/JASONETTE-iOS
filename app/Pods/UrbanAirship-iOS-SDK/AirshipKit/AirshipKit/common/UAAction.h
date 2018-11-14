/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAActionResult.h"
#import "UAActionArguments.h"

@class UAAction;

NS_ASSUME_NONNULL_BEGIN

/**
 * A custom block that can be used to limit the scope of an action.
 */
typedef BOOL (^UAActionPredicate)(UAActionArguments *);

/**
 * A completion handler that signals that an action has finished executing.
 */
typedef void (^UAActionCompletionHandler)(UAActionResult *);

/**
 * A block that defines the primary work performed by an action.
 */
typedef void (^UAActionBlock)(UAActionArguments *, UAActionCompletionHandler completionHandler);

/**
 * Base class for actions, which defines a modular unit of work.
 */
@interface UAAction : NSObject

///---------------------------------------------------------------------------------------
/// @name Action Core Methods
///---------------------------------------------------------------------------------------

/**
 * Called before an action is performed to determine if the
 * the action can accept the arguments.
 *
 * This method can be used both to verify that an argument's value is an appropriate type,
 * as well as to limit the scope of execution of a desired range of values. Rejecting
 * arguments will result in the action not being performed when it is run.
 *
 * @param arguments A UAActionArguments value representing the arguments passed to the action.
 * @return YES if the action can perform with the arguments, otherwise NO
 */
- (BOOL)acceptsArguments:(UAActionArguments *)arguments;

/**
 * Called before the action's performWithArguments:withCompletionHandler:
 *
 * This method can be used to define optional setup or pre-execution logic.
 *
 * @param arguments A UAActionArguments value representing the arguments passed to the action.
 */
- (void)willPerformWithArguments:(UAActionArguments *)arguments;

/**
 * Called after the action has performed, before its final completion handler is called.
 *
 * This method can be used to define optional teardown or post-execution logic.
 *
 * @param arguments A UAActionArguments value representing the arguments passed to the action.
 * @param result A UAActionResult from performing the action.
 */
- (void)didPerformWithArguments:(UAActionArguments *)arguments
                     withResult:(UAActionResult *)result;

/**
 * Performs the action.
 *
 * Subclasses of UAAction should override this method to define custom behavior.
 *
 * @note You should not ordinarily call this method directly. Instead, use the `UAActionRunner`.
 * @param arguments A UAActionArguments value representing the arguments passed to the action.
 * @param completionHandler A UAActionCompletionHandler that will be called when the action has finished executing.
 */
- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler;

///---------------------------------------------------------------------------------------
/// @name Action Factories
///---------------------------------------------------------------------------------------

/**
 * Factory method for creating anonymous actions
 *
 * @param actionBlock A UAActionBlock representing the primary work performed by the action.
 */
+ (instancetype)actionWithBlock:(UAActionBlock)actionBlock;

/**
 * Factory method for creating anonymous actions
 *
 * @param actionBlock A UAActionBlock representing the primary work performed by the action.
 * @param predicateBlock A UAActionPredicate limiting the scope of the arguments.
 */
+ (instancetype)actionWithBlock:(UAActionBlock)actionBlock
             acceptingArguments:(nullable UAActionPredicate)predicateBlock;

@end

NS_ASSUME_NONNULL_END
