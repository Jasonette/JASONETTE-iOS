//
//  NSObject+DTRuntime.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/25/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Methods to dynamically modify objects at runtime
 */

@interface NSObject (DTRuntime)

/**-------------------------------------------------------------------------------------
 @name Blocks
 ---------------------------------------------------------------------------------------
 */

/**
 Adds a block to be executed as soon as the receiver's memory is deallocated
 @param block The block to execute when the receiver is being deallocated
 */
- (void)addDeallocBlock:(void(^)(void))block;

/**
 Adds a new instance method to a class. All instances of this class will have this method.
 
 The block captures `self` in the calling context. To allow access to the instance from within the block it is passed as parameter to the block.
 @param selectorName The name of the method.
 @param block The block to execute for the instance method, a pointer to the instance is passed as the only parameter.
 @returns `YES` if the operation was successful
 */
+ (BOOL)addInstanceMethodWithSelectorName:(NSString *)selectorName block:(void(^)(id))block;

/**-------------------------------------------------------------------------------------
 @name Method Swizzling
 ---------------------------------------------------------------------------------------
 */

/**
 Exchanges two method implementations. After the call methods to the first selector will now go to the second one and vice versa.
 @param selector The first method
 @param otherSelector The second method
 */
+ (void)swizzleMethod:(SEL)selector withMethod:(SEL)otherSelector;
 
 
/**
 Exchanges two class method implementations. After the call methods to the first selector will now go to the second one and vice versa.
 @param selector The first method
 @param otherSelector The second method
 */
+ (void)swizzleClassMethod:(SEL)selector withMethod:(SEL)otherSelector;

@end
