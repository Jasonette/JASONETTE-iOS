//
//  UIView+DTActionHandlers.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 03.06.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Methods to add simple block-based actions to UIViews.
 */

@interface UIView (DTActionHandlers)

/**
 Attaches the given block for a single tap action to the receiver.
 @param block The block to execute.
 */
- (void)setTapActionWithBlock:(void (^)(void))block;

/**
 Attaches the given block for a long press action to the receiver.
 @param block The block to execute.
 */
- (void)setLongPressActionWithBlock:(void (^)(void))block;

@end
