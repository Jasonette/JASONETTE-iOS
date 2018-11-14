/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAJavaScriptDelegate.h"

/**
 * Library-internal implementation of UAJavaScriptDelegate.
 *
 * This class exclusively handles UAJavaScriptDelegate calls with the
 * run-action-cb, run-actions, run-basic-actions and close commands.
 */
@interface UAActionJSDelegate : NSObject<UAJavaScriptDelegate>

@end
