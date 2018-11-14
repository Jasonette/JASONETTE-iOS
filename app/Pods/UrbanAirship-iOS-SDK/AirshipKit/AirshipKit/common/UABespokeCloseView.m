/* Copyright 2017 Urban Airship and Contributors */

#import "UABespokeCloseView.h"

@implementation UABespokeCloseView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO; //peek through around the circle!
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    UIColor *strokeColor = [UIColor whiteColor];

    // Draw a white circle
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);

    NSInteger circleInset = 5;
    CGRect circleRect = CGRectInset(self.bounds, circleInset, circleInset);
    CGContextFillEllipseInRect(context, circleRect);

    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextStrokeEllipseInRect(context, circleRect);

    // The X gets to be a little smaller than the circle
    NSInteger xInset = 7;

    CGRect xFrame = CGRectInset(circleRect, xInset, xInset);

    // CGRect gymnastics
    UIBezierPath *aPath = [UIBezierPath bezierPath];
    [aPath moveToPoint:xFrame.origin];//minx, miny
    [aPath addLineToPoint:CGPointMake(CGRectGetMaxX(xFrame), CGRectGetMaxY(xFrame))];

    UIBezierPath *bPath = [UIBezierPath bezierPath];
    [bPath moveToPoint:CGPointMake(CGRectGetMaxX(xFrame), CGRectGetMinY(xFrame))];
    [bPath addLineToPoint:CGPointMake(CGRectGetMinX(xFrame), CGRectGetMaxY(xFrame))];

    // Set the render colors.
    [strokeColor setStroke];

    // Adjust the drawing options as needed.
    aPath.lineWidth = 3;
    bPath.lineWidth = 3;

    // Line cap style
    aPath.lineCapStyle = kCGLineCapButt;
    bPath.lineCapStyle = kCGLineCapButt;

    // Draw both strokes
    [aPath stroke];
    [bPath stroke];
}

@end
