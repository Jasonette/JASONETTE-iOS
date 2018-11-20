/* Copyright 2017 Urban Airship and Contributors */


#import "UAAction+Operators.h"
#import "UAAction+Internal.h"
#import "UAGlobal.h"

@implementation UAAction (Operators)

NSString * const UAActionOperatorErrorDomain = @"com.urbanairship.actions.operator";


- (UAAction *)bind:(UAActionBindBlock)bindBlock {
    if (!bindBlock) {
        return self;
    }

    UAActionBlock actionBlock = ^(UAActionArguments *args, UAActionCompletionHandler handler) {
        [self runWithArguments:args completionHandler:handler];
    };

    UAActionPredicate acceptsArgumentsBlock = ^(UAActionArguments *args) {
        return [self acceptsArguments:args];
    };

    UAAction *action = bindBlock(actionBlock, acceptsArgumentsBlock);
    return action;
}

- (UAAction *)lift:(UAActionLiftBlock)actionLiftBlock transformingPredicate:(UAActionPredicateLiftBlock)predicateLiftBlock {
    if (!actionLiftBlock || !predicateLiftBlock) {
        return self;
    }

    UAActionBindBlock bindBlock = ^(UAActionBlock actionBlock, UAActionPredicate predicate) {
        UAActionBlock transformedActionBlock = actionLiftBlock(actionBlock);
        UAActionPredicate transformedAcceptsArgumentsBlock = predicateLiftBlock(predicate);

        UAAction *aggregate = [UAAction actionWithBlock:^(UAActionArguments *args, UAActionCompletionHandler handler) {
            transformedActionBlock(args, handler);
        } acceptingArguments: transformedAcceptsArgumentsBlock];

        return aggregate;
    };

    UAAction *action = [self bind:bindBlock];
    return action;
}

- (UAAction *)lift:(UAActionLiftBlock)liftBlock {
    if(!liftBlock) {
        return self;
    }
    return [self lift:liftBlock transformingPredicate:^(UAActionPredicate predicate) {
        return predicate;
    }];
}

- (UAAction *)continueWith:(UAAction *)next {
    if (!next) {
        return self;
    }

    UAActionLiftBlock liftBlock = ^(UAActionBlock actionBlock) {
        UAActionBlock transformedActionBlock = ^(UAActionArguments *args, UAActionCompletionHandler handler) {
            actionBlock(args, ^(UAActionResult *result) {
                switch (result.status) {
                    case UAActionStatusCompleted:
                    {
                        UAActionArguments *nextArgs = [UAActionArguments argumentsWithValue:result.value
                                                                              withSituation:args.situation
                                                                                   metadata:args.metadata];

                        [next runWithArguments:nextArgs completionHandler:^(UAActionResult *nextResult) {
                            handler(nextResult);
                        }];

                        break;
                    }
                    case UAActionStatusArgumentsRejected:
                    {
                        NSError *error = [NSError errorWithDomain:UAActionOperatorErrorDomain
                                                             code:UAActionOperatorErrorCodeChildActionRejectedArgs
                                                         userInfo:@{NSLocalizedDescriptionKey : @"Internal action rejected arguments"}];
                        handler([UAActionResult resultWithError:error]);
                        break;
                    }
                    default:
                        handler(result);
                        break;
                }

            });
        };

        return transformedActionBlock;
    };

    return [self lift:liftBlock];
}

- (UAAction *)filter:(UAActionPredicate)filterBlock {
    if (!filterBlock) {
        return self;
    }

    UAActionLiftBlock actionLiftBlock = ^(UAActionBlock actionBlock) {
        return actionBlock;
    };

    UAActionPredicateLiftBlock predicateLiftBlock = ^(UAActionPredicate predicate) {
        UAActionPredicate transformedPredicate = ^(UAActionArguments *args) {
            if (!filterBlock(args)) {
                return NO;
            }
            return predicate(args);
        };

        return transformedPredicate;
    };

    return [self lift:actionLiftBlock transformingPredicate:predicateLiftBlock];
}

- (UAAction *)map:(UAActionMapArgumentsBlock)mapArgumentsBlock {
    if (!mapArgumentsBlock) {
        return self;
    }

    UAActionLiftBlock actionLiftBlock = ^(UAActionBlock actionBlock) {
        UAActionBlock transformedActionBlock = ^(UAActionArguments *args, UAActionCompletionHandler handler) {
            actionBlock(mapArgumentsBlock(args), handler);
        };

        return transformedActionBlock;
    };

    UAActionPredicateLiftBlock predicateLiftBlock = ^(UAActionPredicate predicate) {
        UAActionPredicate transformedPredicate = ^(UAActionArguments *args) {
            return predicate(mapArgumentsBlock(args));
        };

        return transformedPredicate;
    };

    return [self lift:actionLiftBlock transformingPredicate:predicateLiftBlock];
}

- (UAAction *)preExecution:(UAActionPreExecutionBlock)preExecutionBlock {
    if (!preExecutionBlock) {
        return self;
    }

    UAActionLiftBlock liftBlock = ^(UAActionBlock actionBlock) {
        UAActionBlock transformedActionBlock = ^(UAActionArguments *args, UAActionCompletionHandler handler) {
            preExecutionBlock(args);
            actionBlock(args, handler);
        };
        return transformedActionBlock;
    };

    return [self lift:liftBlock];
}

- (UAAction *)postExecution:(UAActionPostExecutionBlock)postExecutionBlock {
    if (!postExecutionBlock) {
        return self;
    }

    UAActionLiftBlock liftBlock = ^(UAActionBlock actionBlock) {
        UAActionBlock transformedActionBlock = ^(UAActionArguments *args, UAActionCompletionHandler handler) {
            actionBlock(args, ^(UAActionResult *result) {
                postExecutionBlock(args, result);
                handler(result);
            });
        };
        return transformedActionBlock;
    };

    return [self lift:liftBlock];
}

@end
