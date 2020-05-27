//
//  DTAlertView.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/22/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <DTFoundation/DTWeakSupport.h>
#import <Availability.h>

#if !TARGET_OS_TV && __IPHONE_OS_VERSION_MIN_REQUIRED < 80000

// the block to execute when an alert button is tapped
typedef void (^DTAlertViewBlock)(void);

/**
 Extends UIAlertView with support for blocks.
 */

@interface DTAlertView : UIAlertView

/**
* Initializes the alert view. Add buttons and their blocks afterwards.
 @param title The alert title
 @param message The alert message
*/
- (id)initWithTitle:(NSString *)title message:(NSString *)message;

/**
 Adds a button to the alert view

 @param title The title of the new button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */
- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block;

/**
 Same as above, but for a cancel button.
 @param title The title of the cancel button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */
- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block;

/**
 Set a block to be run on alertViewCancel:.
 @param block The block to execute.
 */
- (void)setCancelBlock:(DTAlertViewBlock)block;


/**
 * Use the alertViewDelegate when you want to to receive UIAlertViewDelegate messages.
 */
@property (nonatomic, DT_WEAK_PROPERTY) id<UIAlertViewDelegate> alertViewDelegate;

@end
#endif
