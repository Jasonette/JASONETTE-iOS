//
// DTFoundation 
//
// Created by rene on 25.11.13.
// Copyright 2013 Drobnik.com. All rights reserved.
//
// 
//


#import "DTSidePanelPanGestureRecognizer.h"

int const static kDirectionPanThreshold = 20;

@implementation DTSidePanelPanGestureRecognizer {

	CGFloat _moveY;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStatePossible)
	{
		CGPoint nowPoint = [[touches anyObject] locationInView:self.view];
		CGPoint prevPoint = [[touches anyObject] previousLocationInView:self.view];
		_moveY += prevPoint.y - nowPoint.y;

		if (fabs(_moveY) > kDirectionPanThreshold)
		{
			self.state = UIGestureRecognizerStateFailed;
		}
	}

	if (self.state == UIGestureRecognizerStateFailed)
	{
		return;
	}
	[super touchesMoved:touches withEvent:event];

}


- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
	if (self.state == UIGestureRecognizerStateChanged)
	{
		return YES;
	}
	return NO;
}


- (void)reset {
	[super reset];
	_moveY = 0;
}
@end