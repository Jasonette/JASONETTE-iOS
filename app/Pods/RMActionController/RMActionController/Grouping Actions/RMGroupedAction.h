//
//  RMGroupedAction.h
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMAction.h"

/**
 *  A RMGroupedAction instance represents a number of actions that can be grouped.
 *
 *  Normally, a RMActionController uses one row for every action that has been added. RMGroupedActions offers the possibility to show multiple RMActions in one row.
 */
@interface RMGroupedAction<T : UIView *> : RMAction<T>

/// @name Getting an Instance
#pragma mark - Getting an Instance

/**
 *  Returns a new instance of RMGroupedAction.
 *
 *  @param style   The style of the action.
 *  @param actions The actions that are contained in the grouped action.
 *
 *  @return The new instance of RMGroupedAction
 */
+ (nullable instancetype)actionWithStyle:(RMActionStyle)style andActions:(nonnull NSArray<RMAction<T> *> *)actions;

/**
 *  An array of actions the RMGroupedAction consists of.
 */
@property (nonnull, nonatomic, strong, readonly) NSArray<RMAction<T> *> *actions;

@end
