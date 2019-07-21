//
//  DTProgressHUDWindow.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 12.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

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
