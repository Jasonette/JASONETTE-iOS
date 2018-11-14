/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>

@class UAInboxMessage;
@class UADefaultMessageCenterStyle;

/**
 * The UITableViewCell subclass used by the default message center.
 */
@interface UADefaultMessageCenterListCell : UITableViewCell

///---------------------------------------------------------------------------------------
/// @name Default Message Center List Cell Properties
///---------------------------------------------------------------------------------------

/**
 * The style to apply to the cell.
 */
@property (nonatomic, strong) UADefaultMessageCenterStyle *style;

/**
 * Displays the message date.
 */
@property (nonatomic, weak) IBOutlet UILabel *date;

/**
 * Displays the message title.
 */
@property (nonatomic, weak) IBOutlet UILabel *title;

/**
 * Indicates whether a message has previously been read.
 */
@property (nonatomic, weak) IBOutlet UIView *unreadIndicator;

/**
 * The message icon view.
 */
@property (nonatomic, weak) IBOutlet UIImageView *listIconView;

///---------------------------------------------------------------------------------------
/// @name Default Message Center List Cell Config
///---------------------------------------------------------------------------------------

/**
 * Configures the cell according to the associated message object.
 * @param message The associated message object.
 */
- (void)setData:(UAInboxMessage *)message;

@end
