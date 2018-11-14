/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Wrapper around UIActivityViewController that takes an optional
 * block that will fire after the view disappears.
 */
@interface UAActivityViewController : UIActivityViewController <UIPopoverPresentationControllerDelegate, UIPopoverControllerDelegate>

///---------------------------------------------------------------------------------------
/// @name Activity View Controller Properties
///---------------------------------------------------------------------------------------

/**
 * Block called after the view has disappeared.
 */
@property (nonatomic, copy, nullable) void (^dismissalBlock)(void);

///---------------------------------------------------------------------------------------
/// @name Activity View Controller Management
///---------------------------------------------------------------------------------------

/**
 * Returns the desired source rect dimensions for the popover.
 */
- (CGRect)sourceRect;

@end

NS_ASSUME_NONNULL_END
