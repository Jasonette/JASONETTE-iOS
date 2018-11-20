/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>

@class UADefaultMessageCenterStyle;
@class UADefaultMessageCenterListViewController;
@class UADefaultMessageCenterMessageViewController;

/**
 * Default implementation of an adaptive message center controller.
 */
@interface UADefaultMessageCenterSplitViewController : UISplitViewController

///---------------------------------------------------------------------------------------
/// @name Default Message Center Split View Controller Properties
///---------------------------------------------------------------------------------------

/**
 * An optional predicate for filtering messages.
 */
@property (nonatomic, strong) NSPredicate *filter;

/**
 * The style to apply to the message center
 */
@property(nonatomic, strong) UADefaultMessageCenterStyle *style;

/**
 * The embedded list view controller.
 */
@property(nonatomic, readonly) UADefaultMessageCenterListViewController *listViewController;

@end
