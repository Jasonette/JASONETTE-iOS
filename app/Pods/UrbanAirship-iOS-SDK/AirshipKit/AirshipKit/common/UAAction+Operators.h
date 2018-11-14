/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

/**
 * Represents the possible error conditions when running an action.
 */
typedef NS_ENUM(NSInteger, UAActionOperatorErrorCode) {
    /**
     * Indicates the action rejected the arguments.
     */
    UAActionOperatorErrorCodeChildActionRejectedArgs
};

NS_ASSUME_NONNULL_BEGIN

/**
 * The domain for errors encountered during an action operator.
 */
extern NSString * const UAActionOperatorErrorDomain;

/**
 * A block that defines work that can be done before the action is performed.
 */
typedef void (^UAActionPreExecutionBlock)(UAActionArguments *);

/**
 * A block that defines work that can be done after the action is performed, before the final completion handler is called.
 */
typedef void (^UAActionPostExecutionBlock)(UAActionArguments *, UAActionResult *);

/**
 * A block that defines a means of merging two UAActionResult instances into one value.
 */
typedef UAActionResult * __nonnull (^UAActionFoldResultsBlock)(UAActionResult *, UAActionResult *);

/**
 * A block that defines a means of tranforming one UAActionArguments to another
 */
typedef UAActionArguments * __nonnull (^UAActionMapArgumentsBlock)(UAActionArguments *);

/**
 * A block defining a monadic bind operation.
 */
typedef UAAction * __nonnull (^UAActionBindBlock)(UAActionBlock, UAActionPredicate);

/**
 * A block defining a monadic lift operation on the action block
 */
typedef __nonnull UAActionBlock (^UAActionLiftBlock)(UAActionBlock);

/**
 * A block defining a monadic lift operation on the predicate block
 */
typedef __nonnull UAActionPredicate (^UAActionPredicateLiftBlock)(UAActionPredicate);


@interface UAAction (Operators)

///---------------------------------------------------------------------------------------
/// @name Action Operators Extension Methods
///---------------------------------------------------------------------------------------

/**
 * Operator for creating a monadic binding.
 *
 * @param bindBlock A UAActionBindBlock
 * @return A new UAAction wrapping the receiver and binding the passed block.
 */
- (UAAction *)bind:(UAActionBindBlock)bindBlock;

/**
 * Operator for lifting a block transforming an action block and predicate, into a monadic binding.
 *
 * @param actionLiftBlock A UAActionLiftBlock
 * @param predicateLiftBlock A UAActionPredicteLiftBlock
 * @return A new UAAction wrapping the receiver, which lifts the passed blocks into a bind operation.
 */
- (UAAction *)lift:(UAActionLiftBlock)actionLiftBlock transformingPredicate:(UAActionPredicateLiftBlock)predicateLiftBlock;

/**
 * Operator for lifting a block transforming an action block, into a monadic binding.
 *
 * @param liftBlock A UAActionLiftBlock
 * @return A new UAAction wrapping the receiver, which lifts the passed block into a bind operation.
 */
- (UAAction *)lift:(UAActionLiftBlock)liftBlock;

/**
 * Operator for chaining two actions together in sequence.
 *
 * When run, if the receiver executes normally, the result will be passed in the
 * arguments to the supplied continuation action, whose result will be passed in the
 * completion handler as the final result.
 *
 * Otherwise if the receiver action rejects its arguments or
 * encounters an error, the continuation will finish early and the receiver's result
 * will be passed in the completion handler.
 *
 * The result of the aggregate action is the result of the second action.
 *
 * @param continuationAction A UAAction to be executed as the continuation of
 * the receiver.
 * @return A new UAAction wrapping the receiver and the continuationAction, which chains
 * the two together when run.
 */
- (UAAction *)continueWith:(UAAction *)continuationAction;

/**
 * Operator for limiting the scope of an action with a predicate block.
 *
 * This operator serves the same purpose as the [UAAction acceptsArguments:] method, but
 * can be used to customize an action ad-hoc without deriving a subclass.
 *
 * @param filterBlock A UAActionPredicate block.
 * @return A new UAAction wrapping the receiver and applying the supplied filterBlock to its argument validation logic.
 */
- (UAAction *)filter:(UAActionPredicate)filterBlock;

/**
 * Operator for transforming the arguments passed into an action.
 *
 * @param mapArgumentsBlock A UAActionMapArgumentsBlock
 * @return A new UAAction wrapping the receiver and applying the supplied mapArgumentsBlock as a transformation on the arguments.
 */
- (UAAction *)map:(UAActionMapArgumentsBlock)mapArgumentsBlock;

/**
 * Operator for adding additional pre-execution logic to an action.
 *
 * This operator serves the same purpose as [UAAction willPerformWithArguments:] but
 * can be used to customize an action ad-hoc without deriving a subclass.
 *
 * @param preExecutionBlock A UAActionPreExecutionBlock.
 * @return A new UAAction wrapping the receiver that executes the preExecutionBlock when run, before performing.
 */
- (UAAction *)preExecution:(UAActionPreExecutionBlock)preExecutionBlock;

/**
 * Operator for adding additional post-execution logic to an action.
 *
 * This operator serves the same purpose as [UAAction didPerformWithArguments:withResult:] but
 * can be used to customize an action ad-hoc without deriving a subclass.
 *
 * @param postExecutionBlock A UAActionPostExecutionBlock.
 * @return A new UAAction wrapping the receiver that executes the postExecutionBlock when run, before performing.
 */
- (UAAction *)postExecution:(UAActionPostExecutionBlock)postExecutionBlock;

@end

NS_ASSUME_NONNULL_END
