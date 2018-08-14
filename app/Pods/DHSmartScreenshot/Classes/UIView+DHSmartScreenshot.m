//
//  UIView+DHSmartScreenshot.m
//  TableViewScreenshots
//
//  Created by Hernandez Alvarez, David on 11/30/13.
//  Copyright (c) 2013 David Hernandez. All rights reserved.
//

#import "UIView+DHSmartScreenshot.h"

@implementation UIView (DHSmartScreenshot)

- (UIImage *)screenshot
{
	return [self screenshotForCroppingRect:self.bounds];
}

- (UIImage *)screenshotForCroppingRect:(CGRect)croppingRect
{
	UIGraphicsBeginImageContextWithOptions(croppingRect.size, NO, [UIScreen mainScreen].scale);
    // Create a graphics context and translate it the view we want to crop so
    // that even in grabbing (0,0), that origin point now represents the actual
    // cropping origin desired:
    CGContextRef context = UIGraphicsGetCurrentContext();
	if (context == NULL) return nil;
    CGContextTranslateCTM(context, -croppingRect.origin.x, -croppingRect.origin.y);
	
	[self layoutIfNeeded];
	[self.layer renderInContext:context];
	
	UIImage *screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenshotImage;
}

@end
