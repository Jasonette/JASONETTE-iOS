//
//  DTCustomColoredAccessory.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 2/10/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTCustomColoredAccessory.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

@implementation DTCustomColoredAccessory
{
	UIColor *_accessoryColor;
	UIColor *_highlightedColor;
	
	DTCustomColoredAccessoryType _type;
}

#pragma mark - Creating A Custom-Colored Accessory

+ (DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color
{
	return [self accessoryWithColor:color type:DTCustomColoredAccessoryTypeRight];
}

+ (DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color type:(DTCustomColoredAccessoryType)type
{
	DTCustomColoredAccessory *ret = [[DTCustomColoredAccessory alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)];
	ret.accessoryColor = color;
	ret.frontSquareAccessoryColor = color;
	ret.type = type;
	ret.backSquareAccessoryColor = color == [UIColor blackColor] ? [UIColor whiteColor] : [UIColor blackColor];
	
	return ret;
}

+ (DTCustomColoredAccessory *)squareAccessoryWithColor:(UIColor *)color backgroundColor:(UIColor *)backgroundColor
{
	DTCustomColoredAccessory *ret = [[DTCustomColoredAccessory alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)];
	ret.accessoryColor = color;
	ret.frontSquareAccessoryColor = color;
	ret.type = DTCustomColoredAccessoryTypeSquare;
	ret.backSquareAccessoryColor = backgroundColor;
	
	return ret;
}

#pragma mark - Internal Methods

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctxt = UIGraphicsGetCurrentContext();
	
	const CGFloat R = 4.5;
	
	BOOL doFinal = true;
	
	switch (_type)
	{
		case DTCustomColoredAccessoryTypeRight:
		{
			// (x,y) is the tip of the arrow
			CGFloat x = CGRectGetMaxX(self.bounds)-3.0;;
			CGFloat y = CGRectGetMidY(self.bounds);
			
			CGContextMoveToPoint(ctxt, x-R, y-R);
			CGContextAddLineToPoint(ctxt, x, y);
			CGContextAddLineToPoint(ctxt, x-R, y+R);
			
			break;
		}
			
		case DTCustomColoredAccessoryTypeLeft:
		{
			// (x,y) is the tip of the arrow
			CGFloat x = CGRectGetMaxX(self.bounds)-10.0;;
			CGFloat y = CGRectGetMidY(self.bounds);
			
			CGContextMoveToPoint(ctxt, x+R, y+R);
			CGContextAddLineToPoint(ctxt, x, y);
			CGContextAddLineToPoint(ctxt, x+R, y-R);
			break;
		}
			
		case DTCustomColoredAccessoryTypeUp:
		{
			// (x,y) is the tip of the arrow
			CGFloat x = CGRectGetMaxX(self.bounds)-7.0;;
			CGFloat y = CGRectGetMinY(self.bounds)+5.0;
			
			CGContextMoveToPoint(ctxt, x-R, y+R);
			CGContextAddLineToPoint(ctxt, x, y);
			CGContextAddLineToPoint(ctxt, x+R, y+R);
			
			break;
		}
			
		case DTCustomColoredAccessoryTypeDown:
		{
			// (x,y) is the tip of the arrow
			CGFloat x = CGRectGetMaxX(self.bounds)-7.0;;
			CGFloat y = CGRectGetMaxY(self.bounds)-5.0;
			
			CGContextMoveToPoint(ctxt, x-R, y-R);
			CGContextAddLineToPoint(ctxt, x, y);
			CGContextAddLineToPoint(ctxt, x+R, y-R);
			
			break;
		}
			
		case DTCustomColoredAccessoryTypeSquare:
		{
			doFinal = false;
			
			// (x,y) is the tip of the arrow
			CGFloat x = CGRectGetMinX(self.bounds)+5.0;
			CGFloat y = CGRectGetMinY(self.bounds)+1.0;
			
			CGFloat s = 9.0;
			
			CGContextMoveToPoint(ctxt, x, y);
			CGContextAddLineToPoint(ctxt, x+s, y);
			CGContextAddLineToPoint(ctxt, x+s, y+s);
			CGContextAddLineToPoint(ctxt, x, y+s);
			CGContextClosePath(ctxt);
			
			CGContextSetLineCap(ctxt, kCGLineCapSquare);
			CGContextSetLineJoin(ctxt, kCGLineJoinMiter);
			CGContextSetLineWidth(ctxt, 3);
			
			if (self.highlighted)
			{
				[self.highlightedColor setStroke];
			}
			else
			{
				_accessoryColor = self.backSquareAccessoryColor;
				[self.accessoryColor setStroke];
			}
			
			CGContextStrokePath(ctxt);
			
			x = CGRectGetMinX(self.bounds)+3.0;
			y = CGRectGetMinY(self.bounds)+3.0;
			
			CGContextMoveToPoint(ctxt, x, y);
			CGContextAddLineToPoint(ctxt, x+s, y);
			CGContextAddLineToPoint(ctxt, x+s, y+s);
			CGContextAddLineToPoint(ctxt, x, y+s);
			CGContextClosePath(ctxt);
			
			CGContextSetLineCap(ctxt, kCGLineCapSquare);
			CGContextSetLineJoin(ctxt, kCGLineJoinMiter);
			CGContextSetLineWidth(ctxt, 3);
			
			if (self.highlighted)
			{
				[self.highlightedColor setStroke];
			}
			else
			{
				_accessoryColor = self.frontSquareAccessoryColor;
				[self.accessoryColor setStroke];
			}
			
			CGContextStrokePath(ctxt);
			
			break;
		}
			
		default:
			break;
	}
	
	if (doFinal)
	{
		CGContextSetLineCap(ctxt, kCGLineCapSquare);
		CGContextSetLineJoin(ctxt, kCGLineJoinMiter);
		CGContextSetLineWidth(ctxt, 3);
		
		if (self.highlighted)
		{
			[self.highlightedColor setStroke];
		}
		else
		{
			[self.accessoryColor setStroke];
		}
		
		CGContextStrokePath(ctxt);
	}
}

#pragma mark - Properties

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	
	[self setNeedsDisplay];
}

- (UIColor *)accessoryColor
{
	if (!_accessoryColor)
	{
		return [UIColor blackColor];
	}
	
	return _accessoryColor;
}

- (UIColor *)highlightedColor
{
	if (!_highlightedColor)
	{
		return [UIColor whiteColor];
	}
	
	return _highlightedColor;
}

@synthesize accessoryColor = _accessoryColor;
@synthesize highlightedColor = _highlightedColor;
@synthesize type = _type;

@end

#endif
