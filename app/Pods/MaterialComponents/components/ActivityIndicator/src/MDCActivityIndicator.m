// Copyright 2016-present the Material Components for iOS authors. All Rights Reserved.
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

#import "MDCActivityIndicator.h"

#import <MDFInternationalization/MDFInternationalization.h>
#import <MotionAnimator/MotionAnimator.h>
#import <QuartzCore/QuartzCore.h>

#import "private/MDCActivityIndicator+Private.h"
#import "private/MDCActivityIndicatorMotionSpec.h"
#import "private/MaterialActivityIndicatorStrings.h"
#import "private/MaterialActivityIndicatorStrings_table.h"
#import "MDCActivityIndicatorDelegate.h"
#import "MaterialPalettes.h"
#import "MaterialApplication.h"

static const NSInteger kTotalDetentCount = 5;
static const NSTimeInterval kAnimateOutDuration = 0.1;
static const CGFloat kCycleRotation = (CGFloat)(3.0 / 2);
static const CGFloat kOuterRotationIncrement = (CGFloat)(1.0 / kTotalDetentCount) * (CGFloat)M_PI;
static const CGFloat kSpinnerRadius = 12;
static const CGFloat kStrokeLength = (CGFloat)0.75;

#ifndef CGFLOAT_EPSILON
#if CGFLOAT_IS_DOUBLE
#define CGFLOAT_EPSILON DBL_EPSILON
#else
#define CGFLOAT_EPSILON FLT_EPSILON
#endif
#endif

// The Bundle for string resources.
static NSString *const kBundle = @"MaterialActivityIndicator.bundle";

/**
 Total rotation (outer rotation + stroke rotation) per _cycleCount. One turn is 2.
 */
static const CGFloat kSingleCycleRotation =
    2 * kStrokeLength + kCycleRotation + (CGFloat)(1.0 / kTotalDetentCount);

@interface MDCActivityIndicator ()

/**
 The minimum stroke difference to use when collapsing the stroke to a dot. Based on current
 radius and stroke width.
 */
@property(nonatomic, assign, readonly) CGFloat minStrokeDifference;

/**
 The index of the current stroke color in the @c cycleColors array.

 @note Subclasses can change this value to start the spinner at a different color.
 */
@property(nonatomic, assign) NSUInteger cycleColorsIndex;

/**
 The current cycle count.
 */
@property(nonatomic, assign, readonly) NSInteger cycleCount;

/**
 The cycle index at which to start the activity spinner animation. Default is 0, which corresponds
 to the top of the spinner (12 o'clock position). Spinner cycle indices are based on a 5-point
 star.
 */
@property(nonatomic, assign) NSInteger cycleStartIndex;

/**
 The outer layer that handles cycle rotations and houses the stroke layer.
 */
@property(nonatomic, strong, readonly, nullable) CALayer *outerRotationLayer;

/**
 The shape layer that handles the animating stroke.
 */
@property(nonatomic, strong, readonly, nullable) CAShapeLayer *strokeLayer;

/**
 The shape layer that shows a faint, circular track along the path of the stroke layer. Enabled
 via the trackEnabled property.
 */
@property(nonatomic, strong, readonly, nullable) CAShapeLayer *trackLayer;

/**
 The currently queued stop transition, which will be run as soon as the current animation cycle
 completes. At all other times should be nil.
 */
@property(nonatomic, strong, nullable) MDCActivityIndicatorTransition *stopTransition;

@end

@implementation MDCActivityIndicator {
  BOOL _animatingOut;
  BOOL _animationsAdded;
  BOOL _animationInProgress;
  BOOL _backgrounded;
  BOOL _cycleInProgress;
  CGFloat _currentProgress;
  CGFloat _lastProgress;

  MDMMotionAnimator *_animator;
}

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonMDCActivityIndicatorInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonMDCActivityIndicatorInit];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  [self applyPropertiesWithoutAnimation:^{
    // Resize and recenter rotation layer.
    self.outerRotationLayer.bounds = self.bounds;
    self.outerRotationLayer.position =
        CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);

    self.strokeLayer.bounds = self.outerRotationLayer.bounds;
    self.strokeLayer.position = self.outerRotationLayer.position;

    [self updateStrokePath];
  }];

  [self updateStrokeColor];
}

- (void)commonMDCActivityIndicatorInit {
  // Register notifications for foreground and background if needed.
  [self registerForegroundAndBackgroundNotificationObserversIfNeeded];

  // UISemanticContentAttribute was added in iOS SDK 9.0 but is available on devices running earlier
  // version of iOS. We ignore the partial-availability warning that gets thrown on our use of this
  // symbol.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  // The activity indicator reflects the passage of time (a spatial semantic context) and so
  // will not be mirrored in RTL languages.
  self.mdf_semanticContentAttribute = UISemanticContentAttributeSpatial;
#pragma clang diagnostic pop

  _animator = [[MDMMotionAnimator alloc] init];
  _animator.additive = NO;

  _cycleStartIndex = 0;
  _indicatorMode = MDCActivityIndicatorModeIndeterminate;

  // Property defaults.
  _radius = kSpinnerRadius;
  _strokeWidth = 2;

  // Colors.
  _cycleColorsIndex = 0;
  _cycleColors = [MDCActivityIndicator defaultCycleColors];
  self.accessibilityLabel = [self defaultAccessibilityLabel];

  // Track layer.
  _trackLayer = [CAShapeLayer layer];
  _trackLayer.lineWidth = _strokeWidth;
  _trackLayer.fillColor = [UIColor clearColor].CGColor;
  [self.layer addSublayer:_trackLayer];
  _trackLayer.hidden = YES;

  // Rotation layer.
  _outerRotationLayer = [CALayer layer];
  [self.layer addSublayer:_outerRotationLayer];

  // Stroke layer.
  _strokeLayer = [CAShapeLayer layer];
  _strokeLayer.lineWidth = _strokeWidth;
  _strokeLayer.fillColor = [UIColor clearColor].CGColor;
  _strokeLayer.strokeStart = 0;
  _strokeLayer.strokeEnd = 0;
  [_outerRotationLayer addSublayer:_strokeLayer];
}

#pragma mark - UIView

- (void)willMoveToWindow:(UIWindow *)newWindow {
  // If the activity indicator is removed from the window, we should
  // immediately stop animating, otherwise it will start chewing up CPU.
  if (!newWindow) {
    [self actuallyStopAnimating];
  } else if (_animating && !_backgrounded) {
    [self actuallyStartAnimating];
  }
}

- (CGSize)intrinsicContentSize {
  CGFloat edge = 2 * _radius + _strokeWidth;
  return CGSizeMake(edge, edge);
}

- (CGSize)sizeThatFits:(__unused CGSize)size {
  CGFloat edge = 2 * _radius + _strokeWidth;
  return CGSizeMake(edge, edge);
}

- (void)setHidden:(BOOL)hidden {
  [super setHidden:hidden];

  if (hidden) {
    [self stopAnimating];
  }
}

#pragma mark - Public methods

- (void)startAnimating {
  if (_animatingOut) {
    if ([_delegate respondsToSelector:@selector(activityIndicatorAnimationDidFinish:)]) {
      [_delegate activityIndicatorAnimationDidFinish:self];
    }
    [self removeAnimations];
  }

  if (_animating) {
    return;
  }

  _animating = YES;

  if (!self.window || _backgrounded) {
    return;
  }

  [self actuallyStartAnimating];
}

- (void)startAnimatingWithTransition:(nonnull MDCActivityIndicatorTransition *)startTransition
                     cycleStartIndex:(NSInteger)cycleStartIndex {
  if (_animating) {
    return;
  }

  BOOL indeterminate = self.indicatorMode == MDCActivityIndicatorModeIndeterminate;
  NSAssert(indeterminate, @"startAnimatingWithStartAnimation requires an indeterminate mode.");
  if (!indeterminate) {
    return;
  }

  if (_animatingOut) {
    if ([_delegate respondsToSelector:@selector(activityIndicatorAnimationDidFinish:)]) {
      [_delegate activityIndicatorAnimationDidFinish:self];
    }
    [self removeAnimations];
  }

  _animating = YES;

  if (!self.window || _backgrounded) {
    return;
  }

  _cycleStartIndex = cycleStartIndex;
  _cycleCount = _cycleStartIndex;

  _animationInProgress = YES;

  [CATransaction begin];
  {
    [CATransaction setCompletionBlock:^{
      self->_animationInProgress = NO;

      [self actuallyStartAnimating];

      self.cycleColorsIndex =
          self.cycleColors.count > 0 ? cycleStartIndex % self.cycleColors.count : 0;
      [self applyPropertiesWithoutAnimation:^{
        [self updateStrokeColor];
      }];

      if (startTransition.completion) {
        startTransition.completion();
      }
    }];
    [CATransaction setAnimationDuration:startTransition.duration];
    [CATransaction setDisableActions:YES];

    CGFloat outerRotation = kOuterRotationIncrement * _cycleStartIndex;
    CGFloat innerRotation = _cycleStartIndex * (CGFloat)M_PI;
    CGFloat strokeStart =
        (CGFloat)fmod(innerRotation + outerRotation, 2 * M_PI) / (CGFloat)(2 * M_PI);

    CGFloat strokeEnd = _minStrokeDifference + strokeStart;
    strokeEnd = strokeEnd > 1 ? strokeEnd - 1 : strokeEnd;

    startTransition.animation(strokeStart, strokeEnd);
  }
  [CATransaction commit];
}

- (void)stopAnimating {
  if (!_animating) {
    return;
  }

  _animating = NO;

  [self animateOut];
}

- (void)stopAnimatingWithTransition:(MDCActivityIndicatorTransition *)stopTransition {
  if (!_animating) {
    return;
  }

  BOOL indeterminate = self.indicatorMode == MDCActivityIndicatorModeIndeterminate;
  NSAssert(indeterminate, @"stopAnimationWithTransition requires an indeterminate mode.");
  if (!indeterminate) {
    return;
  }

  _animating = NO;
  _animatingOut = YES;

  self.stopTransition = stopTransition;
}

- (void)stopAnimatingImmediately {
  if (!_animating) {
    return;
  }

  _animating = NO;

  [self actuallyStopAnimating];

  if ([_delegate respondsToSelector:@selector(activityIndicatorAnimationDidFinish:)]) {
    [_delegate activityIndicatorAnimationDidFinish:self];
  }
}

- (void)resetStrokeColor {
  _cycleColorsIndex = 0;

  [self updateStrokeColor];
}

- (void)setStrokeColor:(UIColor *)strokeColor {
  _strokeLayer.strokeColor = strokeColor.CGColor;
  _trackLayer.strokeColor = [strokeColor colorWithAlphaComponent:(CGFloat)0.3].CGColor;
}

- (void)setIndicatorMode:(MDCActivityIndicatorMode)indicatorMode {
  if (_indicatorMode == indicatorMode) {
    return;
  }
  _indicatorMode = indicatorMode;
  if (_animating && !_animationInProgress) {
    switch (indicatorMode) {
      case MDCActivityIndicatorModeDeterminate:
        [self addTransitionToDeterminateCycle];
        break;
      case MDCActivityIndicatorModeIndeterminate:
        [self addTransitionToIndeterminateCycle];
        break;
    }
  } else if (!_animating) {
    if ([_delegate respondsToSelector:@selector(activityIndicatorModeTransitionDidFinish:)]) {
      [_delegate activityIndicatorModeTransitionDidFinish:self];
    }
  }
}

- (void)setIndicatorMode:(MDCActivityIndicatorMode)mode animated:(__unused BOOL)animated {
  [self setIndicatorMode:mode];
}

- (void)setProgress:(float)progress {
  [self setProgress:progress animated:YES];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
  _progress = MAX(0, MIN(progress, 1));
  if (_indicatorMode == MDCActivityIndicatorModeIndeterminate || _progress == _currentProgress) {
    return;
  }
  if (animated) {
    if (_animating && !_animationInProgress) {
      // Currently animating the determinate mode but no animation queued.
      [self addProgressAnimation];
    }
  } else {
    [self setDeterminateProgressWithoutAnimation];
  }
}

#pragma mark - Properties

- (void)setStrokeWidth:(CGFloat)strokeWidth {
  _strokeWidth = strokeWidth;
  _strokeLayer.lineWidth = _strokeWidth;
  _trackLayer.lineWidth = _strokeWidth;

  [self updateStrokePath];
}

- (void)setRadius:(CGFloat)radius {
  _radius = MAX(radius, 5);

  [self updateStrokePath];
}

- (void)setTrackEnabled:(BOOL)trackEnabled {
  _trackEnabled = trackEnabled;

  _trackLayer.hidden = !_trackEnabled;
}

#pragma mark - Private methods

/**
 If this class is not being run in an extension, register for foreground changes and initialize
 the app background state in case UI is created when the app is backgrounded. (Extensions always
 return UIApplicationStateBackground for |[UIApplication sharedApplication].applicationState|.)
 */
- (void)registerForegroundAndBackgroundNotificationObserversIfNeeded {
  if ([UIApplication mdc_isAppExtension]) {
    return;
  }

  _backgrounded =
      [UIApplication mdc_safeSharedApplication].applicationState == UIApplicationStateBackground;
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self
                         selector:@selector(controlAnimatingOnForegroundChange:)
                             name:UIApplicationWillEnterForegroundNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(controlAnimatingOnForegroundChange:)
                             name:UIApplicationDidEnterBackgroundNotification
                           object:nil];
}

- (void)controlAnimatingOnForegroundChange:(NSNotification *)notification {
  // Stop or restart animating if the app has a foreground change.
  _backgrounded = [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification];
  if (_animating) {
    if (_backgrounded) {
      [self actuallyStopAnimating];
    } else if (self.window) {
      [self actuallyStartAnimating];
    }
  }
}

- (void)actuallyStartAnimating {
  if (_animationsAdded) {
    return;
  }
  _animationsAdded = YES;
  _cycleCount = _cycleStartIndex;

  [self applyPropertiesWithoutAnimation:^{
    self.strokeLayer.strokeStart = 0;
    self.strokeLayer.strokeEnd = (CGFloat)0.001;
    self.strokeLayer.lineWidth = self.strokeWidth;
    self.trackLayer.lineWidth = self.strokeWidth;

    [self resetStrokeColor];
    [self updateStrokePath];
  }];

  switch (_indicatorMode) {
    case MDCActivityIndicatorModeIndeterminate:
      [self addStrokeRotationCycle];
      break;
    case MDCActivityIndicatorModeDeterminate:
      [self addProgressAnimation];
      break;
  }
}

- (void)actuallyStopAnimating {
  if (!_animationsAdded) {
    return;
  }

  [self removeAnimations];
  [self applyPropertiesWithoutAnimation:^{
    self.strokeLayer.strokeStart = 0;
    self.strokeLayer.strokeEnd = 0;
  }];
}

- (void)setCycleColors:(NSArray<UIColor *> *)cycleColors {
  if (cycleColors.count) {
    _cycleColors = [cycleColors copy];
  } else {
    _cycleColors = [MDCActivityIndicator defaultCycleColors];
  }

  if (self.cycleColors.count) {
    [self setStrokeColor:self.cycleColors[0]];
  }
}

- (void)addStopAnimation {
  MDCActivityIndicatorTransition *stopTransition = self.stopTransition;

  CGFloat innerRotation = [[_strokeLayer valueForKeyPath:MDMKeyPathRotation] floatValue];
  CGFloat outerRotation = [[_outerRotationLayer valueForKeyPath:MDMKeyPathRotation] floatValue];
  CGFloat totalRotation =
      (CGFloat)fmod(innerRotation + outerRotation, 2 * M_PI) / (CGFloat)(2 * M_PI);

  CGFloat strokeStart = _strokeLayer.strokeStart + totalRotation;
  strokeStart = strokeStart > 1 ? strokeStart - 1 : strokeStart;

  CGFloat strokeEnd = _strokeLayer.strokeEnd + totalRotation;
  strokeEnd = strokeEnd > 1 ? strokeEnd - 1 : strokeEnd;

  [self applyPropertiesWithoutAnimation:^{
    self.strokeLayer.strokeStart = 0;
    self.strokeLayer.strokeEnd = 0;
  }];

  [CATransaction begin];
  {
    [CATransaction setCompletionBlock:^{
      if (stopTransition.completion) {
        stopTransition.completion();
      }
      if (stopTransition == self.stopTransition) {
        if ([self.delegate respondsToSelector:@selector(activityIndicatorAnimationDidFinish:)]) {
          [self.delegate activityIndicatorAnimationDidFinish:self];
        }
        [self removeAnimations];
      }
    }];
    [CATransaction setAnimationDuration:stopTransition.duration];
    [CATransaction setDisableActions:YES];
    stopTransition.animation(strokeStart, strokeEnd);
  }
  [CATransaction commit];
}

- (void)updateStrokePath {
  CGFloat offsetRadius = _radius - _strokeLayer.lineWidth / 2;
  UIBezierPath *strokePath = [UIBezierPath bezierPathWithArcCenter:_strokeLayer.position
                                                            radius:offsetRadius
                                                        startAngle:-1 * (CGFloat)M_PI_2
                                                          endAngle:3 * (CGFloat)M_PI_2
                                                         clockwise:YES];
  _strokeLayer.path = strokePath.CGPath;
  _trackLayer.path = strokePath.CGPath;

  _minStrokeDifference = _strokeLayer.lineWidth / ((CGFloat)M_PI * 2 * _radius);
}

- (void)updateStrokeColor {
  if (self.cycleColors.count > 0 && self.cycleColors.count > self.cycleColorsIndex) {
    [self setStrokeColor:self.cycleColors[self.cycleColorsIndex]];
  } else {
    NSAssert(NO, @"cycleColorsIndex is outside the bounds of cycleColors.");
    [self setStrokeColor:[[MDCActivityIndicator defaultCycleColors] firstObject]];
  }
}

- (void)addStrokeRotationCycle {
  if (_animationInProgress) {
    return;
  }

  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    [self strokeRotationCycleFinishedFromState:MDCActivityIndicatorStateIndeterminate];
  }];

  MDCActivityIndicatorMotionSpecIndeterminate timing =
      MDCActivityIndicatorMotionSpec.loopIndeterminate;
  // These values may be equal if we've never received a progress. In this case we don't want our
  // duration to become zero.
  if (fabs(_lastProgress - _currentProgress) > CGFLOAT_EPSILON) {
    timing.strokeEnd.duration *= ABS(_lastProgress - _currentProgress);
  }

  [_animator animateWithTiming:timing.outerRotation
                       toLayer:_outerRotationLayer
                    withValues:@[
                      @(kOuterRotationIncrement * _cycleCount),
                      @(kOuterRotationIncrement * (_cycleCount + 1))
                    ]
                       keyPath:MDMKeyPathRotation];

  CGFloat startRotation = _cycleCount * (CGFloat)M_PI;
  CGFloat endRotation = startRotation + kCycleRotation * (CGFloat)M_PI;
  [_animator animateWithTiming:timing.innerRotation
                       toLayer:_strokeLayer
                    withValues:@[ @(startRotation), @(endRotation) ]
                       keyPath:MDMKeyPathRotation];

  [_animator animateWithTiming:timing.strokeStart
                       toLayer:_strokeLayer
                    withValues:@[ @0, @(kStrokeLength) ]
                       keyPath:MDMKeyPathStrokeStart];

  // Ensure the stroke never completely disappears on start by animating from non-zero start and
  // to a value slightly larger than the strokeStart's final value.
  [_animator animateWithTiming:timing.strokeEnd
                       toLayer:_strokeLayer
                    withValues:@[ @(_minStrokeDifference), @(kStrokeLength + _minStrokeDifference) ]
                       keyPath:MDMKeyPathStrokeEnd];

  [CATransaction commit];

  _animationInProgress = YES;
}

- (void)addTransitionToIndeterminateCycle {
  if (_animationInProgress) {
    return;
  }
  // Find the nearest cycle to transition through.
  NSInteger nearestCycle = 0;
  CGFloat nearestDistance = CGFLOAT_MAX;
  const CGFloat normalizedProgress = MAX(_lastProgress - _minStrokeDifference, 0);
  for (NSInteger cycle = 0; cycle < kTotalDetentCount; cycle++) {
    const CGFloat currentRotation = [self normalizedRotationForCycle:cycle];
    if (currentRotation >= normalizedProgress) {
      if (nearestDistance >= (currentRotation - normalizedProgress)) {
        nearestDistance = currentRotation - normalizedProgress;
        nearestCycle = cycle;
      }
    }
  }

  if (nearestCycle == 0 && _lastProgress <= _minStrokeDifference) {
    // Special case for 0% progress.
    _cycleCount = nearestCycle;
    [self strokeRotationCycleFinishedFromState:MDCActivityIndicatorStateTransitionToIndeterminate];
    if ([_delegate respondsToSelector:@selector(activityIndicatorModeTransitionDidFinish:)]) {
      [_delegate activityIndicatorModeTransitionDidFinish:self];
    }
    return;
  }

  _cycleCount = nearestCycle;

  CGFloat targetRotation = [self normalizedRotationForCycle:nearestCycle];
  if (targetRotation <= (CGFloat)0.001) {
    targetRotation = 1;
  }
  CGFloat pointCycleDuration = (CGFloat)MDCActivityIndicatorMotionSpec.pointCycleDuration;
  CGFloat pointCycleMinimumVariableDuration =
      (CGFloat)MDCActivityIndicatorMotionSpec.pointCycleMinimumVariableDuration;
  CGFloat normalizedDuration =
      2 * (targetRotation + _currentProgress) / kSingleCycleRotation * pointCycleDuration;
  CGFloat strokeEndTravelDistance = targetRotation - _currentProgress + _minStrokeDifference;
  CGFloat totalDistance = targetRotation + strokeEndTravelDistance;
  CGFloat strokeStartDuration =
      MAX(normalizedDuration * targetRotation / totalDistance, pointCycleMinimumVariableDuration);
  CGFloat strokeEndDuration = MAX(normalizedDuration * strokeEndTravelDistance / totalDistance,
                                  pointCycleMinimumVariableDuration);

  [CATransaction begin];
  {
    [CATransaction setCompletionBlock:^{
      [self
          strokeRotationCycleFinishedFromState:MDCActivityIndicatorStateTransitionToIndeterminate];
      if ([self.delegate respondsToSelector:@selector(activityIndicatorModeTransitionDidFinish:)]) {
        [self.delegate activityIndicatorModeTransitionDidFinish:self];
      }
    }];
    [CATransaction setDisableActions:YES];

    MDCActivityIndicatorMotionSpecTransitionToIndeterminate timing =
        MDCActivityIndicatorMotionSpec.willChangeToIndeterminate;

    _outerRotationLayer.transform = CATransform3DIdentity;
    _strokeLayer.transform = CATransform3DIdentity;

    timing.strokeStart.duration = strokeStartDuration;
    timing.strokeStart.delay = strokeEndDuration;
    [_animator animateWithTiming:timing.strokeStart
                         toLayer:_strokeLayer
                      withValues:@[ @0, @(targetRotation) ]
                         keyPath:MDMKeyPathStrokeStart];

    timing.strokeEnd.duration = strokeEndDuration;
    timing.strokeEnd.delay = 0;
    [_animator animateWithTiming:timing.strokeEnd
                         toLayer:_strokeLayer
                      withValues:@[ @(_currentProgress), @(targetRotation + _minStrokeDifference) ]
                         keyPath:MDMKeyPathStrokeEnd];
  }
  [CATransaction commit];

  _animationInProgress = YES;
}

- (void)addTransitionToDeterminateCycle {
  if (_animationInProgress) {
    return;
  }
  if (!_cycleCount) {
    // The animation period is complete: no need for transition.
    [_strokeLayer removeAllAnimations];
    [_outerRotationLayer removeAllAnimations];
    // Necessary for transition from indeterminate to determinate when cycle == 0.
    _currentProgress = 0;
    _lastProgress = _currentProgress;
    [self strokeRotationCycleFinishedFromState:MDCActivityIndicatorStateTransitionToDeterminate];
    if ([_delegate respondsToSelector:@selector(activityIndicatorModeTransitionDidFinish:)]) {
      [_delegate activityIndicatorModeTransitionDidFinish:self];
    }
  } else {
    _currentProgress = MAX(_progress, _minStrokeDifference);

    CGFloat rotationDelta = 1 - [self normalizedRotationForCycle:_cycleCount];

    // Change the duration relative to the distance in order to keep same relative speed.
    CGFloat pointCycleDuration = (CGFloat)MDCActivityIndicatorMotionSpec.pointCycleDuration;
    CGFloat pointCycleMinimumVariableDuration =
        (CGFloat)MDCActivityIndicatorMotionSpec.pointCycleMinimumVariableDuration;
    CGFloat duration =
        2 * (rotationDelta + _currentProgress) / kSingleCycleRotation * pointCycleDuration;
    duration = MAX(duration, pointCycleMinimumVariableDuration);

    [CATransaction begin];
    {
      [CATransaction setCompletionBlock:^{
        [self
            strokeRotationCycleFinishedFromState:MDCActivityIndicatorStateTransitionToDeterminate];
        if ([self.delegate
                respondsToSelector:@selector(activityIndicatorModeTransitionDidFinish:)]) {
          [self.delegate activityIndicatorModeTransitionDidFinish:self];
        }
      }];
      [CATransaction setDisableActions:YES];
      [CATransaction mdm_setTimeScaleFactor:@(duration)];

      MDCActivityIndicatorMotionSpecTransitionToDeterminate spec =
          MDCActivityIndicatorMotionSpec.willChangeToDeterminate;

      _outerRotationLayer.transform =
          CATransform3DMakeRotation(kOuterRotationIncrement * _cycleCount, 0, 0, 1);

      CGFloat startRotation = _cycleCount * (CGFloat)M_PI;
      CGFloat endRotation = startRotation + rotationDelta * 2 * (CGFloat)M_PI;
      [_animator animateWithTiming:spec.innerRotation
                           toLayer:_strokeLayer
                        withValues:@[ @(startRotation), @(endRotation) ]
                           keyPath:MDMKeyPathRotation];

      _strokeLayer.strokeStart = 0;

      [_animator animateWithTiming:spec.strokeEnd
                           toLayer:_strokeLayer
                        withValues:@[ @(_minStrokeDifference), @(_currentProgress) ]
                           keyPath:MDMKeyPathStrokeEnd];
    }
    [CATransaction commit];

    _animationInProgress = YES;
    _lastProgress = _currentProgress;
  }
}

- (void)addProgressAnimation {
  if (_animationInProgress) {
    return;
  }

  _currentProgress = MAX(_progress, _minStrokeDifference);

  [CATransaction begin];
  {
    [CATransaction setCompletionBlock:^{
      [self strokeRotationCycleFinishedFromState:MDCActivityIndicatorStateDeterminate];
    }];
    [CATransaction setDisableActions:YES];

    _outerRotationLayer.transform = CATransform3DIdentity;
    _strokeLayer.transform = CATransform3DIdentity;
    _strokeLayer.strokeStart = 0;

    [_animator animateWithTiming:MDCActivityIndicatorMotionSpec.willChangeProgress.strokeEnd
                         toLayer:_strokeLayer
                      withValues:@[ @(_lastProgress), @(_currentProgress) ]
                         keyPath:MDMKeyPathStrokeEnd];
  }

  [CATransaction commit];

  _lastProgress = _currentProgress;
  _animationInProgress = YES;
}

- (void)setDeterminateProgressWithoutAnimation {
  [self removeAnimations];
  _animationInProgress = NO;
  _currentProgress = MAX(_progress, _minStrokeDifference);
  _strokeLayer.strokeStart = 0.0;
  _strokeLayer.strokeEnd = _currentProgress;
  _lastProgress = _currentProgress;
}

- (void)strokeRotationCycleFinishedFromState:(MDCActivityIndicatorState)state {
  _animationInProgress = NO;

  if (!_animationsAdded) {
    return;
  }

  if (self.stopTransition) {
    [self addStopAnimation];
    return;
  }

  if (state == MDCActivityIndicatorStateIndeterminate) {
    if (self.cycleColors.count > 0) {
      self.cycleColorsIndex = (self.cycleColorsIndex + 1) % self.cycleColors.count;
      [self updateStrokeColor];
    }
    _cycleCount = (_cycleCount + 1) % kTotalDetentCount;
  }

  switch (_indicatorMode) {
    case MDCActivityIndicatorModeDeterminate:
      switch (state) {
        case MDCActivityIndicatorStateDeterminate:
        case MDCActivityIndicatorStateTransitionToDeterminate:
          [self addProgressAnimationIfRequired];
          break;
        case MDCActivityIndicatorStateIndeterminate:
        case MDCActivityIndicatorStateTransitionToIndeterminate:
          [self addTransitionToDeterminateCycle];
          break;
      }
      break;
    case MDCActivityIndicatorModeIndeterminate:
      switch (state) {
        case MDCActivityIndicatorStateDeterminate:
        case MDCActivityIndicatorStateTransitionToDeterminate:
          [self addTransitionToIndeterminateCycle];
          break;
        case MDCActivityIndicatorStateIndeterminate:
        case MDCActivityIndicatorStateTransitionToIndeterminate:
          [self addStrokeRotationCycle];
          break;
      }
      break;
  }
}

- (void)addProgressAnimationIfRequired {
  if (_indicatorMode == MDCActivityIndicatorModeDeterminate) {
    if (MAX(_progress, _minStrokeDifference) != _currentProgress) {
      // The values were changes in the while animating or animation is starting.
      [self addProgressAnimation];
    }
  }
}

/**
 Rotation that a given cycle has. Represented between 0 (cycle has no rotation) and 1.
 */
- (CGFloat)normalizedRotationForCycle:(NSInteger)cycle {
  CGFloat cycleRotation = cycle * kSingleCycleRotation / 2;
  return cycleRotation - ((NSInteger)cycleRotation);
}

- (void)animateOut {
  _animatingOut = YES;

  [CATransaction begin];

  [CATransaction setCompletionBlock:^{
    if (self->_animatingOut) {
      [self removeAnimations];
      if ([self.delegate respondsToSelector:@selector(activityIndicatorAnimationDidFinish:)]) {
        [self.delegate activityIndicatorAnimationDidFinish:self];
      }
    }
  }];
  [CATransaction setAnimationDuration:kAnimateOutDuration];

  _strokeLayer.lineWidth = 0;
  _trackLayer.lineWidth = 0;

  [CATransaction commit];
}

- (void)removeAnimations {
  _animationsAdded = NO;
  _animatingOut = NO;
  self.stopTransition = nil;
  [_strokeLayer removeAllAnimations];
  [_outerRotationLayer removeAllAnimations];

  // Reset current and latest progress, to ensure addProgressAnimationIfRequired adds a progress
  // animation when returning from hidden.
  _currentProgress = 0;
  _lastProgress = 0;

  // Reset cycle count to 0 rather than cycleStart to reflect default starting position (top).
  _cycleCount = 0;
  // However _animationInProgress represents the CATransaction that hasn't finished, so we leave it
  // alone here.
}

+ (CGFloat)defaultHeight {
  return kSpinnerRadius * 2;
}

+ (NSArray<UIColor *> *)defaultCycleColors {
  static NSArray<UIColor *> *s_defaultCycleColors;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    s_defaultCycleColors = @[
      MDCPalette.bluePalette.tint500, MDCPalette.redPalette.tint500,
      MDCPalette.yellowPalette.tint500, MDCPalette.greenPalette.tint500
    ];
  });
  return s_defaultCycleColors;
}

- (void)applyPropertiesWithoutAnimation:(void (^)(void))setPropBlock {
  [CATransaction begin];

  // Disable implicit CALayer animations
  [CATransaction setDisableActions:YES];
  setPropBlock();

  [CATransaction commit];
}

#pragma mark - Resource Bundle

+ (NSBundle *)bundle {
  static NSBundle *bundle = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    bundle = [NSBundle bundleWithPath:[self bundlePathWithName:kBundle]];
  });

  return bundle;
}

+ (NSString *)bundlePathWithName:(NSString *)bundleName {
  // In iOS 8+, we could be included by way of a dynamic framework, and our resource bundles may
  // not be in the main .app bundle, but rather in a nested framework, so figure out where we live
  // and use that as the search location.
  NSBundle *bundle = [NSBundle bundleForClass:[MDCActivityIndicator class]];
  NSString *resourcePath = [(nil == bundle ? [NSBundle mainBundle] : bundle) resourcePath];
  return [resourcePath stringByAppendingPathComponent:bundleName];
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
  return self.isAnimating;
}

- (NSString *)defaultAccessibilityLabel {
  MaterialActivityIndicatorStringId keyIndex = kStr_MaterialActivityIndicatorAccessibilityLabel;
  NSString *key = kMaterialActivityIndicatorStringTable[keyIndex];
  return NSLocalizedStringFromTableInBundle(key, kMaterialActivityIndicatorStringsTableName,
                                            [[self class] bundle], @"Activity Indicator");
}

- (NSString *)accessibilityValue {
  if (self.isAnimating) {
    if (self.indicatorMode == MDCActivityIndicatorModeIndeterminate) {
      MaterialActivityIndicatorStringId keyIndex =
          kStr_MaterialActivityIndicatorInProgressAccessibilityValue;
      NSString *key = kMaterialActivityIndicatorStringTable[keyIndex];
      return NSLocalizedStringFromTableInBundle(key, kMaterialActivityIndicatorStringsTableName,
                                                [[self class] bundle], @"In Progress");
    } else {
      NSUInteger percentage = (int)(self.progress * 100);
      MaterialActivityIndicatorStringId keyIndex =
          kStr_MaterialActivityIndicatorProgressCompletedAccessibilityValue;
      NSString *key = kMaterialActivityIndicatorStringTable[keyIndex];
      NSString *localizedString = NSLocalizedStringFromTableInBundle(
          key, kMaterialActivityIndicatorStringsTableName, [[self class] bundle],
          @"{percentage} Percent Complete");
      return [NSString localizedStringWithFormat:localizedString, percentage];
    }
  } else {
    MaterialActivityIndicatorStringId keyIndex =
        kStr_MaterialActivityIndicatorProgressHaltedAccessibilityValue;
    NSString *key = kMaterialActivityIndicatorStringTable[keyIndex];
    return NSLocalizedStringFromTableInBundle(key, kMaterialActivityIndicatorStringsTableName,
                                              [[self class] bundle], @"Progress Halted");
  }
}

- (UIAccessibilityTraits)accessibilityTraits {
  return UIAccessibilityTraitUpdatesFrequently;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];

  if (self.traitCollectionDidChangeBlock) {
    self.traitCollectionDidChangeBlock(self, previousTraitCollection);
  }
}

@end

@implementation MDCActivityIndicatorTransition
- (nonnull instancetype)initWithAnimation:(_Nonnull MDCActivityIndicatorAnimation)animation {
  self = [super init];
  if (self) {
    self.animation = animation;
  }
  return self;
}
@end
