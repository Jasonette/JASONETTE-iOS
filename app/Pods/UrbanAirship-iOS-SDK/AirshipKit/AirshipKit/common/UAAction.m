/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"
#import "UAAction+Internal.h"
#import "UAActionResult+Internal.h"
#import "UAGlobal.h"

@implementation UAAction

#pragma mark init

- (instancetype)initWithBlock:(UAActionBlock)actionBlock {
    self = [super init];
    if (self) {
        self.actionBlock = actionBlock;
    }

    return self;
}

#pragma mark internal methods

- (void)runWithArguments:(UAActionArguments *)arguments
       completionHandler:(UAActionCompletionHandler)completionHandler {
    
    completionHandler = completionHandler ?: ^(UAActionResult *result) {
        //if no completion handler was passed, use an empty block in its place
    };
    
    typedef void (^voidBlock)(void);
    
    //execute the passed block directly if we're on the main thread, otherwise
    //dispatch it to the main queue
    void (^dispatchMainIfNecessary)(voidBlock) = ^(voidBlock block) {
        if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
            dispatch_async(dispatch_get_main_queue(), block);
        } else {
            block();
        }
    };
    
    //make sure the initial acceptsArguments/willPerform/perform is executed on the main queue
    dispatchMainIfNecessary(^{
        if (![self acceptsArguments:arguments]) {
            UA_LDEBUG(@"Action %@ rejected arguments %@.", [self description], [arguments description]);
            completionHandler([UAActionResult rejectedArgumentsResult]);
        } else {
            UA_LDEBUG(@"Action %@ performing with arguments %@.", [self description], [arguments description]);
            [self willPerformWithArguments:arguments];
            [self performWithArguments:arguments completionHandler:^(UAActionResult *result) {
                //make sure the passed completion handler and didPerformWithArguments are executed on the
                //main queue
                dispatchMainIfNecessary(^{
                    if (!result) {
                        UA_LWARN("Action %@ called the completion handler with a nil result", [self description]);
                    }

                    UAActionResult *normalizedResult = result ?: [UAActionResult emptyResult];
                    [self didPerformWithArguments:arguments withResult:normalizedResult];
                    completionHandler(normalizedResult);
                });
            }];
        }
    });
}


#pragma mark core methods

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    if (self.acceptsArgumentsBlock) {
        return self.acceptsArgumentsBlock(arguments);
    }
    return YES;
}

- (void)willPerformWithArguments:(UAActionArguments *)arguments {
    //override
}

- (void)performWithArguments:(UAActionArguments *)args completionHandler:(UAActionCompletionHandler)completionHandler {
    if (self.actionBlock) {
        self.actionBlock(args, completionHandler);
    } else {
        completionHandler([UAActionResult emptyResult]);
    }
}

- (void)didPerformWithArguments:(UAActionArguments *)arguments
                     withResult:(UAActionResult *)result {
    //override
}

#pragma mark factory methods

+ (instancetype)actionWithBlock:(UAActionBlock)actionBlock {
    return [[self alloc] initWithBlock:actionBlock];
}

+ (instancetype)actionWithBlock:(UAActionBlock)actionBlock
             acceptingArguments:(UAActionPredicate)predicateBlock {
    UAAction *action = [self actionWithBlock:actionBlock];
    action.acceptsArgumentsBlock = predicateBlock;
    return action;
}

@end
