//
//  DTObjectBlockExecutor.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 12.02.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTObjectBlockExecutor.h"


@implementation DTObjectBlockExecutor

+ (id)blockExecutorWithDeallocBlock:(void(^)(void))block
{
    DTObjectBlockExecutor *executor = [[DTObjectBlockExecutor alloc] init];
    executor.deallocBlock = block; // copy
    return executor;
}

- (void)dealloc
{
    if (_deallocBlock)
    {
        _deallocBlock();
        _deallocBlock = nil;
    }
}

@end
