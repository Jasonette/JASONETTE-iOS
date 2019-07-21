//
//  UIView+DTDebug.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 2/8/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 Methods useful for debugging problems with UIView instances.
 */

@interface UIView (DTDebug)

/**
 @name Main Thread Checking
 */

/**
 Toggles on/off main thread checking on several methods of UIView.
 
 Currently the following methods are swizzeled and checked:
 
 - setNeedsDisplay
 - setNeedsDisplayInRect:
 - setNeedsLayout
 
 Those are triggered by a variety of methods in UIView, e.g. setBackgroundColor and thus it is not necessary to swizzle all of them.
 */
+ (void)toggleViewMainThreadChecking;

/**
 Method that gets called if one of the important methods of UIView is not being called on a main queue. 
 
 Toggle this on/off with <toggleViewMainThreadChecking>. Break on -[UIView methodCalledNotFromMainThread:] to catch it in debugger.
 @param methodName Symbolic name of the method being called
 */
- (void)methodCalledNotFromMainThread:(NSString *)methodName;

@end
