/* Copyright 2017 Urban Airship and Contributors */

#import "UADisposable.h"

@interface UADisposable ()
@property (nonatomic, copy) UADisposalBlock disposalBlock;
@end

@implementation UADisposable

- (instancetype)initWithDisposalBlock:(UADisposalBlock)disposalBlock {
    self = [super init];

    if (self) {
        self.disposalBlock = disposalBlock;
    }

    return self;
}

- (void)dispose {
    @synchronized(self) {
        if (self.disposalBlock) {
            self.disposalBlock();
            self.disposalBlock = nil;
        }
    }
}

+ (instancetype)disposableWithBlock:(UADisposalBlock)disposalBlock {
    return [[self alloc] initWithDisposalBlock:disposalBlock];
}

@end
