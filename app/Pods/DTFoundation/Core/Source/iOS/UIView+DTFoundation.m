//
//  UIView+DTFoundation.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 12/23/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import "UIView+DTFoundation.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

NSString *shadowContext = @"Shadow";

@implementation UIView (DTFoundation)

- (UIImage *)snapshotImage
{
	NSAssert(self.bounds.size.height > 0 && self.bounds.size.width > 0, @"Trying to create a snapshot from a zero size view");
	
	UIGraphicsBeginImageContext(self.bounds.size);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

- (void)setRoundedCornersWithRadius:(CGFloat)radius width:(CGFloat)width color:(UIColor * _Nullable)color
{
	self.clipsToBounds = YES;
	self.layer.cornerRadius = radius;
	self.layer.borderWidth = width;
	
	if (color)
	{
		self.layer.borderColor = color.CGColor;
	}
}

- (void)addShadowWithColor:(UIColor * _Nullable)color alpha:(CGFloat)alpha radius:(CGFloat)radius offset:(CGSize)offset
{
	self.layer.shadowOpacity = alpha;
	self.layer.shadowRadius = radius;
	self.layer.shadowOffset = offset;
	
	if (color)
	{
		self.layer.shadowColor = [color CGColor];
	}
	
	// cannot have masking	
	self.layer.masksToBounds = NO;
}

- (void)updateShadowPathToBounds:(CGRect)bounds withDuration:(NSTimeInterval)duration
{
	CGPathRef oldPath = self.layer.shadowPath;
	CGPathRef newPath = CGPathCreateWithRect(bounds, NULL);
	
	if (oldPath && duration>0)
	{
		CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
		theAnimation.duration = duration;
		theAnimation.fromValue = (__bridge id)oldPath;
		theAnimation.toValue = (__bridge id)newPath;
		theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		[self.layer addAnimation:theAnimation forKey:@"shadowPath"];
	}
	
	self.layer.shadowPath = newPath;

	CGPathRelease(newPath);
}

@end

#endif
