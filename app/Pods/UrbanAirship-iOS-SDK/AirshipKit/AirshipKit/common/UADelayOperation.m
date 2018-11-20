/* Copyright 2017 Urban Airship and Contributors */

#import "UADelayOperation+Internal.h"

@interface UADelayOperation()
@property (nonatomic, assign) NSTimeInterval seconds;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;    // GCD objects use ARC
@end

@implementation UADelayOperation

- (instancetype)initWithDelayInSeconds:(NSTimeInterval)seconds {
    self = [super init];
    if (self) {
        self.semaphore = dispatch_semaphore_create(0);
        __weak UADelayOperation *_self = self;

        [self addExecutionBlock:^{
            //dispatch time is calculated as nanoseconds delta offset
            dispatch_semaphore_wait(_self.semaphore, dispatch_time(DISPATCH_TIME_NOW, (seconds * NSEC_PER_SEC)));
        }];

        self.seconds = seconds;
    }

    return self;
}

- (void)cancel {
    [super cancel];
    dispatch_semaphore_signal(self.semaphore);
}

+ (instancetype)operationWithDelayInSeconds:(NSTimeInterval)seconds {
    return [[self alloc] initWithDelayInSeconds:seconds];
}

@end
