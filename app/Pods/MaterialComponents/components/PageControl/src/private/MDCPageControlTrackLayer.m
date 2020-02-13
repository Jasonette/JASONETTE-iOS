// Copyright 2015-present the Material Components for iOS authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MDCPageControlTrackLayer.h"

static const NSTimeInterval kPageControlAnimationDuration = 0.2;
static const NSInteger kPageControlKeyframeCount = 2;
static NSString *const kPageControlAnimationKeyDraw = @"drawTrack";

@implementation MDCPageControlTrackLayer {
  CGFloat _radius;
  CGPoint _startPoint, _endPoint, _midPoint;
  BOOL _isAnimating;
}

- (instancetype)initWithRadius:(CGFloat)radius {
  self = [super init];
  if (self) {
    _trackHidden = YES;
    _radius = radius;
    self.cornerRadius = radius;
  }
  return self;
}

- (void)setTrackColor:(UIColor *)trackColor {
  _trackColor = trackColor;
  self.fillColor = trackColor.CGColor;
  self.backgroundColor = trackColor.CGColor;
}

#pragma mark - Draw/Extend Track

- (void)drawTrackFromStartPoint:(CGPoint)startPoint toEndPoint:(CGPoint)endPoint {
  if (_isAnimating || !_trackHidden || [self isPointZero:startPoint] ||
      [self isPointZero:endPoint]) {
    return;
  }

  // First reset track frame.
  [self resetTrackFrame];

  _isAnimating = YES;
  _startPoint = startPoint;
  _endPoint = endPoint;
  _midPoint = [self midPointFromPoint:startPoint toPoint:endPoint];
  [self resetHidden:NO];

  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    // After drawn, remove animation and update track frame.
    [self removeAnimationForKey:kPageControlAnimationKeyDraw];
    [self updateTrackFrameWithAnimation:NO completion:nil];
    self->_trackHidden = NO;
    self->_isAnimating = NO;
  }];

  // Get animation keyframes.
  NSMutableArray<UIBezierPath *> *values = [NSMutableArray array];
  for (NSInteger i = 0; i < kPageControlKeyframeCount; i++) {
    [values addObject:(id)[self pathAtKeyframe:i]];
  }

  // Add animation path.
  CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
  animation.duration = kPageControlAnimationDuration;
  animation.removedOnCompletion = NO;
  animation.fillMode = kCAFillModeForwards;
  animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  animation.values = values;
  [self addAnimation:animation forKey:kPageControlAnimationKeyDraw];
  [CATransaction commit];
}

- (void)extendTrackFromStartPoint:(CGPoint)startPoint toEndPoint:(CGPoint)endPoint {
  if (_trackHidden || [self isPointZero:startPoint] || [self isPointZero:endPoint]) {
    return;
  }

  // Extend track to encompass minimum startPoint and maximum endPoint.
  _startPoint = (startPoint.x < _startPoint.x) ? startPoint : _startPoint;
  _endPoint = (endPoint.x > _endPoint.x) ? endPoint : _endPoint;
  [self updateTrackFrameWithAnimation:YES completion:nil];
}

- (void)drawAndExtendTrackFromStartPoint:(CGPoint)startPoint
                              toEndPoint:(CGPoint)endPoint
                              completion:(void (^)(void))completion {
  _trackHidden = NO;
  if ([self isPointZero:_startPoint]) {
    // If no previous start point, first set frame without animation.
    _startPoint = startPoint;
    _endPoint = endPoint;
    [self updateTrackFrameWithAnimation:NO
                             completion:^{
                               [self updateTrackFrameWithAnimation:YES
                                                        completion:^{
                                                          if (completion) {
                                                            completion();
                                                          }
                                                        }];
                             }];
  } else {
    // Previous startPoint exists, therefore animate to new start and end points.
    _startPoint = startPoint;
    _endPoint = endPoint;
    [self updateTrackFrameWithAnimation:YES
                             completion:^{
                               if (completion) {
                                 completion();
                               }
                             }];
  }
}

- (void)updateTrackFrameWithAnimation:(BOOL)animated completion:(void (^)(void))completion {
  // Set track frame without implicit animation.
  [self resetHidden:NO];
  [CATransaction begin];
  [CATransaction setDisableActions:!animated];
  [CATransaction setCompletionBlock:^{
    if (completion) {
      completion();
    }
  }];
  self.frame = CGRectMake(_startPoint.x - _radius, _startPoint.y - _radius,
                          _endPoint.x - _startPoint.x + (_radius * 2), _radius * 2);
  [CATransaction commit];
}

- (void)resetTrackFrame {
  // Reset track frame without implicit animation.
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  self.frame = CGRectZero;
  [CATransaction commit];
}

- (void)resetHidden:(BOOL)hidden {
  // Reset hidden without implicit animation.
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  self.hidden = hidden;
  [CATransaction commit];
}

#pragma mark - Remove Track

- (void)removeTrackTowardsPoint:(CGPoint)point completion:(void (^)(void))completion {
  // Animate the track removal towards a single point.
  _startPoint = point;
  _endPoint = point;
  [self updateTrackFrameWithAnimation:YES
                           completion:^{
                             [self reset];
                             if (completion) {
                               completion();
                             }
                           }];
}

- (void)resetAtPoint:(CGPoint)point {
  // Resets the track at single point without animation.
  _startPoint = point;
  _endPoint = point;
  [self updateTrackFrameWithAnimation:NO
                           completion:^{
                             [self reset];
                           }];
}

- (void)reset {
  // Reset track frame without implicit animation.
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  [self removeAllAnimations];
  _isAnimating = NO;
  _trackHidden = YES;
  [self resetHidden:YES];
  [CATransaction commit];
}

#pragma mark - Private

- (CGPoint)midPointFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint {
  // Returns midpoint between two points.
  return CGPointMake((fromPoint.x + toPoint.x) / 2, (fromPoint.y + toPoint.y) / 2);
}

- (CGPathRef)pathAtKeyframe:(NSInteger)keyframe {
  // Generates bezier path keyframes that can be animated forward and in reverse.
  CGFloat r = _radius;
  CGFloat d = _radius * 2;
  UIBezierPath *bezierPath = UIBezierPath.bezierPath;

  if (keyframe == 0) {
    // Create circles at start and end points.
    [self addRoundedEndpontToBezierPath:bezierPath atPoint:_startPoint];
    [self addRoundedEndpontToBezierPath:bezierPath atPoint:_endPoint];

    // Create an arc from top of startpoint circle to midpoint.
    [bezierPath moveToPoint:[self pointOnCircleWithRadius:r angleInDegrees:300 origin:_startPoint]];
    [bezierPath addQuadCurveToPoint:_midPoint controlPoint:CGPointMake(_midPoint.x - r / 2, r)];

    // Create an arc from midpoint to top of endpoint circle.
    [bezierPath addQuadCurveToPoint:[self pointOnCircleWithRadius:r
                                                   angleInDegrees:240
                                                           origin:_endPoint]
                       controlPoint:CGPointMake(_midPoint.x + r / 2, r)];

    // Create a line from top of endpoint circle to bottom of endpoint circle.
    [bezierPath addLineToPoint:[self pointOnCircleWithRadius:r
                                              angleInDegrees:120
                                                      origin:_endPoint]];

    // Create an arc from bottom of endpoint circle to midpoint.
    [bezierPath addQuadCurveToPoint:_midPoint controlPoint:CGPointMake(_midPoint.x + r / 2, r)];

    // Create an arc from midpoint to bottom of startpoint circle.
    [bezierPath addQuadCurveToPoint:[self pointOnCircleWithRadius:r
                                                   angleInDegrees:60
                                                           origin:_startPoint]
                       controlPoint:CGPointMake(_midPoint.x - r / 2, r)];

    // Create line from bottom of startpoint circle to top of startpoint circle.
    [bezierPath addLineToPoint:[self pointOnCircleWithRadius:r
                                              angleInDegrees:300
                                                      origin:_startPoint]];

    // Close path.
    [bezierPath closePath];

  } else if (keyframe == 1) {
    // Creates rectangular path from startpoint to endpoint with rounded ends.
    // Requires same number of paths as previous keyframe to animate properly.
    [self addRoundedEndpontToBezierPath:bezierPath atPoint:_startPoint];
    [self addRoundedEndpontToBezierPath:bezierPath atPoint:_endPoint];
    [bezierPath moveToPoint:CGPointMake(_startPoint.x, 0)];
    [bezierPath addLineToPoint:CGPointMake(_midPoint.x, 0)];
    [bezierPath addLineToPoint:CGPointMake(_endPoint.x, 0)];
    [bezierPath addLineToPoint:CGPointMake(_endPoint.x, d)];
    [bezierPath addLineToPoint:CGPointMake(_midPoint.x, d)];
    [bezierPath addLineToPoint:CGPointMake(_startPoint.x, d)];
    [bezierPath closePath];
  }
  return bezierPath.CGPath;
}

- (void)addRoundedEndpontToBezierPath:(UIBezierPath *)bezierPath atPoint:(CGPoint)point {
  // Creates a closed circle at designated point.
  [bezierPath moveToPoint:CGPointMake(point.x, _radius * 2)];
  [bezierPath addArcWithCenter:point
                        radius:_radius
                    startAngle:0
                      endAngle:[self degreesToRadians:360]
                     clockwise:YES];
}

- (CGPoint)pointOnCircleWithRadius:(CGFloat)radius
                    angleInDegrees:(CGFloat)angleInDegrees
                            origin:(CGPoint)origin {
  // Returns a point along a circles edge at given angle.
  CGFloat locationX = (CGFloat)(radius * cos([self degreesToRadians:angleInDegrees])) + origin.x;
  CGFloat locationY = (CGFloat)(radius * sin([self degreesToRadians:angleInDegrees])) + origin.y;
  return CGPointMake(locationX, locationY);
}

- (CGFloat)degreesToRadians:(CGFloat)degrees {
  return degrees * (CGFloat)M_PI / 180;
}

- (BOOL)isPointZero:(CGPoint)point {
  return CGPointEqualToPoint(point, CGPointZero);
}

@end
