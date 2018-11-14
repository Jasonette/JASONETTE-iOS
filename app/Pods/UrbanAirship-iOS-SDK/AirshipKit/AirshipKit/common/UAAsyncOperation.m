/* Copyright 2017 Urban Airship and Contributors */

#import "UAAsyncOperation+Internal.h"

@interface UAAsyncOperation()

/**
 * Indicates whether the operation is currently executing.
 */
@property (nonatomic, assign) BOOL isExecuting;

/**
 * Indicates whether the operation has finished.
 */
@property (nonatomic, assign) BOOL isFinished;

/**
 * Block operation to run.
 */
@property (nonatomic, copy) void (^block)(UAAsyncOperation *);
@end

@implementation UAAsyncOperation

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isExecuting = NO;
        self.isFinished = NO;
    }
    return self;
}

- (instancetype)initWithBlock:(void (^)(UAAsyncOperation *))block {
    self = [self init];
    if (self) {
        self.block = block;
    }
    return self;
}

+ (instancetype)operationWithBlock:(void (^)(UAAsyncOperation *))block {
    return [[UAAsyncOperation alloc] initWithBlock:block];
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)setIsExecuting:(BOOL)isExecuting {
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setIsFinished:(BOOL)isFinished {
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)dealloc {
    self.block = nil;
}

- (void)cancel {
    @synchronized (self) {
        [super cancel];
    }
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            [self finish];
            return;
        }

        self.isExecuting = YES;
        [self startAsyncOperation];
    }
}

- (void)startAsyncOperation {
    if (self.block) {
        self.block(self);
    } else {
        [self finish];
    }
}

- (void)finish {
    @synchronized (self) {
        self.block = nil;

        if (self.isExecuting) {
            self.isExecuting = NO;
        }

        if (!self.isFinished) {
            self.isFinished = YES;
        }
    }
}

@end

