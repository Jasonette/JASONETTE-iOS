//
//  DTProgressHUDWindow.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 12.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <Availability.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE && !TARGET_OS_TV && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

@class DTProgressHUD;

/**
 Class for correcting rotations when using UIWindow in iOS
 */
@interface DTProgressHUDWindow : UIWindow

/**
 Designated initializer. Sets the passed DTProgressHUD view as root view
 @param progressHUD The DTProgressHUD instance to set as root view
 */
- (instancetype)initWithProgressHUD:(DTProgressHUD *)progressHUD;

@end

#endif
