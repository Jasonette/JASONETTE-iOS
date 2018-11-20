/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UARateAppAction.h"

/**
 * View Controller interface for showing and dismissing Rate App
 * link prompts.
 */
@interface UARateAppPromptViewController : UIViewController

///---------------------------------------------------------------------------------------
/// @name Rate App Action View Controller Internal Display Methods
///---------------------------------------------------------------------------------------

/**
 * Displays the link prompt with an optional custom header and description.
 * If the header and description are left nil - the header and description defined in
 * the UARateAppPromptView.xib are used by default.
 */
-(void)displayWithHeader:(NSString * _Nullable)header description:(NSString * _Nullable)description completionHandler:(void (^_Nonnull)(BOOL dismissed))completionHandler;

@end
