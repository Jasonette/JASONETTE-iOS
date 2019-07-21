//
//  UIView+DTDebug.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 2/8/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "UIView+DTDebug.h"
#import "NSObject+DTRuntime.h"
#import "DTLog.h"

@implementation UIView (DTDebug)

- (void)methodCalledNotFromMainThread:(NSString *)methodName
{
	DTLogError(@"-[%@ %@] being called on background queue. Break on %s to find out where", NSStringFromClass([self class]), methodName, __PRETTY_FUNCTION__);
}

- (void)_setNeedsLayout_MainThreadCheck
{
	if (![NSThread isMainThread])
	{
		[self methodCalledNotFromMainThread:NSStringFromSelector(_cmd)];
	}
	
	// not really an endless loop, this calls the original
	[self _setNeedsLayout_MainThreadCheck];
}

- (void)_setNeedsDisplay_MainThreadCheck
{
	if (![NSThread isMainThread])
	{
		[self methodCalledNotFromMainThread:NSStringFromSelector(_cmd)];
	}
	
	// not really an endless loop, this calls the original
	[self _setNeedsDisplay_MainThreadCheck];
}

- (void)_setNeedsDisplayInRect_MainThreadCheck:(CGRect)rect
{
	if (![NSThread isMainThread])
	{
		[self methodCalledNotFromMainThread:NSStringFromSelector(_cmd)];
	}
	
	// not really an endless loop, this calls the original
	[self _setNeedsDisplayInRect_MainThreadCheck:rect];
}

+ (void)toggleViewMainThreadChecking
{
	[UIView swizzleMethod:@selector(setNeedsLayout) withMethod:@selector(_setNeedsLayout_MainThreadCheck)];
	[UIView swizzleMethod:@selector(setNeedsDisplay) withMethod:@selector(_setNeedsDisplay_MainThreadCheck)];
	[UIView swizzleMethod:@selector(setNeedsDisplayInRect:) withMethod:@selector(_setNeedsDisplayInRect_MainThreadCheck:)];
}

@end
