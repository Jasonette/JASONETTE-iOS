//
//  DTPieProgressIndicator.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 16.05.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPieProgressIndicator.h"
#import "DTCoreGraphicsUtils.h"

#define PIE_SIZE CGFloat_(34)

@implementation DTPieProgressIndicator
{
	float _progressPercent;
	UIColor *_color;
}

+ (DTPieProgressIndicator *)pieProgressIndicator
{
	return [[DTPieProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, PIE_SIZE, PIE_SIZE)];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.contentMode = UIViewContentModeRedraw;
	self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect
{
	// Drawing code
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (_color)
	{
		[_color set];
	}
	else 
	{
		[self.tintColor set];
	}
	
	CGContextBeginTransparencyLayer(ctx, NULL);
	
	CGFloat smallerDimension = MIN(self.bounds.size.width-CGFloat_(6), self.bounds.size.height-CGFloat_(6));
	CGRect drawRect =  CGRectMake(round(CGRectGetMidX(self.bounds)-smallerDimension/CGFloat_(2)), round(CGRectGetMidY(self.bounds)-smallerDimension/CGFloat_(2)), smallerDimension, smallerDimension);
	
	CGContextSetLineWidth(ctx, CGFloat_(3));
	CGContextStrokeEllipseInRect(ctx, drawRect);
	
	// enough percent to draw
	if (_progressPercent > 0.1f)
	{
		CGPoint center = CGPointMake(CGRectGetMidX(drawRect), CGRectGetMidY(drawRect));
		CGFloat radius = center.x - drawRect.origin.x;
		CGFloat angle = CGFloat_(_progressPercent) * CGFloat_(2.0 * M_PI);
		
		CGContextMoveToPoint(ctx, center.x, center.y);
		CGContextAddArc(ctx, center.x, center.y, radius, CGFloat_(-M_PI_2), angle-CGFloat_(M_PI_2), 0);
		CGContextAddLineToPoint(ctx, center.x, center.y);
		
		CGContextFillPath(ctx);
	}
	
	CGContextEndTransparencyLayer(ctx);
}

- (void)tintColorDidChange
{
	[super tintColorDidChange];
	[self setNeedsDisplay];
}

#pragma mark Properties

- (void)setProgressPercent:(float)progressPercent
{
	if (_progressPercent != progressPercent)
	{
		_progressPercent = progressPercent;
		
		[self setNeedsDisplay];
	}
}

- (void)setColor:(UIColor *)color
{
	if (_color != color)
	{
		_color = color;
		
		[self setNeedsDisplay];
	}
}

@end
