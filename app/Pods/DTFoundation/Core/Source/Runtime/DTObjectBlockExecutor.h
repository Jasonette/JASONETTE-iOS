//
//  DTObjectBlockExecutor.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 12.02.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 This class is used by [NSObject addDeallocBlock:] to execute blocks on dealloc
 */

@interface DTObjectBlockExecutor : NSObject

/**
 Convenience method to create a block executor with a deallocation block
 @param block The block to execute when the created receiver is being deallocated
 */
+ (id)blockExecutorWithDeallocBlock:(void(^)(void))block;

/**
 Block to execute when dealloc of the receiver is called
 */
@property (nonatomic, copy) void (^deallocBlock)(void);

@end
