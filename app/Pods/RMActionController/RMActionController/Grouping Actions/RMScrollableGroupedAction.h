//
//  RMScrollableGroupedAction.h
//  RMImageAction-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMGroupedAction.h"

/**
 *  Like RMGroupedActions allows to show multiple RMActions in a row. However, instead to equally divide the available width, RMScrollableGroupedAction uses a fix width for each RMAction and allows the user to scroll when the available width is not sufficient.
 *
 *  When combined with RMImageAction, the result looks very much like the Apple share sheet.
 */
@interface RMScrollableGroupedAction<T : UIView *> : RMGroupedAction<T>

/**
 *  Returns a new instance of RMScrollableGroupedAction.
 *
 *  @param style       The style of the action.
 *  @param actionWidth The width available to each action.
 *  @param actions     The actions that are contained in the grouped action.
 *
 *  @return The new instance of RMScrollableGroupedAction
 */
+ (nullable instancetype)actionWithStyle:(RMActionStyle)style actionWidth:(CGFloat)actionWidth andActions:(nonnull NSArray *)actions;

@end
