//
//  DTProgressHUDWindow.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 12.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTProgressHUDWindow.h"

#if TARGET_OS_IPHONE && !TARGET_OS_TV && !TARGET_OS_WATCH

#import "DTProgressHUD.h"
#import "UIScreen+DTFoundation.h"

#define DegreesToRadians(degrees) (degrees * M_PI / 180)

// local helper function
static CGAffineTransform _transformForInterfaceOrientation(UIInterfaceOrientation orientation)
{
	switch (orientation)
	{
		case UIInterfaceOrientationLandscapeLeft:
		{
			return CGAffineTransformMakeRotation(-DegreesToRadians(90));
		}
		case UIInterfaceOrientationLandscapeRight:
		{
			return CGAffineTransformMakeRotation(DegreesToRadians(90));
		}
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			return CGAffineTransformMakeRotation(DegreesToRadians(180));
		}
		default:
		case UIInterfaceOrientationPortrait:
		{
			return CGAffineTransformMakeRotation(DegreesToRadians(0));
		}
	}
}

@implementation DTProgressHUDWindow

- (instancetype)initWithProgressHUD:(DTProgressHUD *)progressHUD
{
	NSParameterAssert(progressHUD);
	
	self = [super initWithFrame:[UIScreen mainScreen].bounds];
	
	if (self)
	{
		self.windowLevel = UIWindowLevelAlert;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = NO;
		
		// use a dummy view controller to calm iOS 7's warning about missing root VC
		UIViewController *viewController = [[UIViewController alloc] init];
		viewController.view = progressHUD;
		self.rootViewController = viewController; // this replaces the addSubview
		
		// observe interface rotations
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarDidChangeFrame:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
		
		// set initial transform
		UIInterfaceOrientation orientation = [[UIScreen mainScreen] orientation];
		[self setTransform:_transformForInterfaceOrientation(orientation)];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)statusBarDidChangeFrame:(NSNotification *)notification
{
	UIInterfaceOrientation orientation = [[UIScreen mainScreen] orientation];
	[self setTransform:_transformForInterfaceOrientation(orientation)];
}

@end

#endif
