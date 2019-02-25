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

#import "MDCPageControl.h"

#import "private/MDCPageControlIndicator.h"
#import "private/MDCPageControlTrackLayer.h"
#import "private/MaterialPageControlStrings.h"
#import "private/MaterialPageControlStrings_table.h"

#include <tgmath.h>

// The Bundle for string resources.
static NSString *const kMaterialPageControlBundle = @"MaterialPageControl.bundle";

// The keypath for the content offset of a scrollview.
static NSString *const kMaterialPageControlScrollViewContentOffset = @"bounds.origin";

// Matches native UIPageControl minimum height.
static const CGFloat kPageControlMinimumHeight = 48.0f;

// Matches native UIPageControl indicator radius.
static const CGFloat kPageControlIndicatorRadius = 3.5f;

// Matches native UIPageControl indicator spacing margin.
static const CGFloat kPageControlIndicatorMargin = kPageControlIndicatorRadius * 2.5;

// Delay for revealing indicators staggered towards current page indicator.
static const NSTimeInterval kPageControlIndicatorShowDelay = 0.04f;

// Default indicator opacity.
static const CGFloat kPageControlIndicatorDefaultOpacity = 0.5f;

// Default white level for current page indicator color.
static const CGFloat kPageControlCurrentPageIndicatorWhiteColor = 0.38f;

// Default white level for page indicator color.
static const CGFloat kPageControlPageIndicatorWhiteColor = 0.62f;

// Normalize to [0,1] range.
static inline CGFloat normalizeValue(CGFloat value, CGFloat minRange, CGFloat maxRange) {
  CGFloat diff = maxRange - minRange;
  return (diff > 0) ? ((value - minRange) / diff) : 0;
}

@implementation MDCPageControl {
  UIView *_containerView;
  NSMutableArray<MDCPageControlIndicator *> *_indicators;
  NSMutableArray<NSValue *> *_indicatorPositions;
  MDCPageControlIndicator *_animatedIndicator;
  MDCPageControlTrackLayer *_trackLayer;
  CGFloat _trackLength;
  BOOL _isDeferredScrolling;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonMDCPageControlInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self commonMDCPageControlInit];
  }
  return self;
}

- (void)commonMDCPageControlInit {
  CGFloat radius = kPageControlIndicatorRadius;
  CGFloat topEdge = (CGFloat)(floor(CGRectGetHeight(self.bounds) - (radius * 2)) / 2);
  CGRect containerFrame = CGRectMake(0, topEdge, CGRectGetWidth(self.bounds), radius * 2);
  _containerView = [[UIView alloc] initWithFrame:containerFrame];

  _trackLayer = [[MDCPageControlTrackLayer alloc] initWithRadius:radius];
  [_containerView.layer addSublayer:_trackLayer];
  _containerView.autoresizingMask =
      UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
      UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  [self addSubview:_containerView];

  // Defaults.
  _currentPage = 0;
  _currentPageIndicatorTintColor =
      [UIColor colorWithWhite:kPageControlCurrentPageIndicatorWhiteColor alpha:1];
  _pageIndicatorTintColor = [UIColor colorWithWhite:kPageControlPageIndicatorWhiteColor alpha:1];

  UITapGestureRecognizer *tapGestureRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
  [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  if (_numberOfPages == 0 || (_hidesForSinglePage && [_indicators count] == 1)) {
    self.hidden = YES;
    return;
  }
  self.hidden = NO;
  for (MDCPageControlIndicator *indicator in _indicators) {
    NSInteger indicatorIndex = [_indicators indexOfObject:indicator];
    if (indicatorIndex == _currentPage) {
      indicator.hidden = YES;
    }
    indicator.color = _pageIndicatorTintColor;
  }
  _animatedIndicator.color = _currentPageIndicatorTintColor;
  _trackLayer.trackColor = _pageIndicatorTintColor;

  // TODO(cjcox): Add back in RTL once we get the view category ready.
  // This view must be mirrored by flipping instead of relayout, because we want to mirror
  // the view itself, not its subviews.
  //  if ([self class] == [MDCPageControl class]) {
  //    [self mdc_flipViewForRTL];
  //  }
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
  _numberOfPages = MAX(0, numberOfPages);
  _currentPage = MAX(0, MIN(_numberOfPages - 1, _currentPage));
  [self resetControl];
}

- (void)setCurrentPage:(NSInteger)currentPage {
  [self setCurrentPage:currentPage animated:NO];
}

- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated {
  [self setCurrentPage:currentPage animated:animated duration:0];
}
- (void)setCurrentPage:(NSInteger)currentPage
              animated:(BOOL)animated
              duration:(NSTimeInterval)duration {
  currentPage = MAX(0, MIN(_numberOfPages - 1, currentPage));
  NSInteger previousPage = _currentPage;
  BOOL shouldReverse = (previousPage > currentPage);
  _currentPage = currentPage;

  if (_numberOfPages == 0) {
    return;
  }

  if (animated) {
    // Draw and extend track.
    CGPoint startPoint = [_indicatorPositions[previousPage] CGPointValue];
    CGPoint endPoint = [_indicatorPositions[currentPage] CGPointValue];
    if (shouldReverse) {
      startPoint = [_indicatorPositions[currentPage] CGPointValue];
      endPoint = [_indicatorPositions[previousPage] CGPointValue];
    }

    // Remove track and reveal hidden indicators staggered towards current page indicator. Reveal
    // indicators in reverse if scrolling to left.
    void (^completionBlock)(void) = ^{
      // We are using the delay to increase the time between the end of the extension of the track
      // ahead of the dots movement and the contraction of the track under the dot at the
      // destination.
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), ^{
                       [self->_trackLayer removeTrackTowardsPoint:shouldReverse ? startPoint : endPoint
                                                 completion:^{
                                                   // Once track is removed, reveal indicators once
                                                   // more to ensure
                                                   // no hidden indicators remain.
                                                   [self revealIndicatorsReversed:shouldReverse];
                                                 }];
                       [self revealIndicatorsReversed:shouldReverse];
                     });
    };

    [_trackLayer drawAndExtendTrackFromStartPoint:startPoint
                                       toEndPoint:endPoint
                                       completion:completionBlock];
  } else {
    // If not animated, simply move indicator to new position and reset track.
    CGPoint point = [_indicatorPositions[currentPage] CGPointValue];
    [_animatedIndicator updateIndicatorTransformX:point.x - kPageControlIndicatorRadius];
    [_trackLayer resetAtPoint:point];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [_indicators[previousPage] setHidden:NO];
    [CATransaction commit];
  }
}

- (void)setHidesForSinglePage:(BOOL)hidesForSinglePage {
  _hidesForSinglePage = hidesForSinglePage;
  [self setNeedsLayout];
}

- (BOOL)isPageIndexValid:(NSInteger)nextPage {
  // Returns YES if next page is within bounds of page control. Otherwise NO.
  return (nextPage >= 0 && nextPage < _numberOfPages);
}

#pragma mark - UIView(UIViewGeometry)

- (CGSize)sizeThatFits:(__unused CGSize)size {
  return [MDCPageControl sizeForNumberOfPages:_numberOfPages];
}

+ (CGSize)sizeForNumberOfPages:(NSInteger)pageCount {
   CGFloat radius = kPageControlIndicatorRadius;
   CGFloat margin = kPageControlIndicatorMargin;
   CGFloat width = pageCount * ((radius * 2) + margin) - margin;
   CGFloat height = MAX(kPageControlMinimumHeight, radius * 2);
   return CGSizeMake(width, height);
}

#pragma mark - Colors

- (void)setPageIndicatorTintColor:(UIColor *)pageIndicatorTintColor {
  _pageIndicatorTintColor = pageIndicatorTintColor;
  [self setNeedsLayout];
}

- (void)setCurrentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor {
  _currentPageIndicatorTintColor = currentPageIndicatorTintColor;
  [self setNeedsLayout];
}

#pragma mark - Scrolling

- (NSInteger)scrolledPageNumber:(UIScrollView *)scrollView {
  // Returns paged index of scrollView.
  NSInteger unboundedPageNumber = lround(scrollView.contentOffset.x / scrollView.frame.size.width);
  return MAX(0, MIN(_numberOfPages - 1, unboundedPageNumber));
}

- (CGFloat)scrolledPercentage:(UIScrollView *)scrollView {
  // Returns scrolled percentage of scrollView from 0 to 1. If the scrollView has bounced past
  // the edge of its content, it will return either a negative value or value above 1.
  return normalizeValue(scrollView.contentOffset.x, 0,
                        scrollView.contentSize.width - scrollView.frame.size.width);
}

#pragma mark - UIScrollViewDelegate Observers

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat scrolledPercentage = [self scrolledPercentage:scrollView];

  // Detect if we are getting called from an animation block
  if ([scrollView.layer.animationKeys containsObject:kMaterialPageControlScrollViewContentOffset]) {
    CAAnimation *animation =
        [scrollView.layer animationForKey:kMaterialPageControlScrollViewContentOffset];

    // If the animation block has a delay it translates to the beginTime of the CAAnimation. We need
    // to ensure that we delay our animation of the page control to keep in sync with the animation
    // of the scrollView.contentOffset.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(animation.beginTime * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     NSInteger currentPage = [self scrolledPageNumber:scrollView];
                     [self setCurrentPage:currentPage animated:YES duration:animation.duration];

                     CGFloat transformX = scrolledPercentage * self->_trackLength;
                     [self->_animatedIndicator updateIndicatorTransformX:transformX
                                                                animated:YES
                                                                duration:animation.duration
                                                     mediaTimingFunction:animation.timingFunction];
                   });

  } else if (scrolledPercentage >= 0 && scrolledPercentage <= 1 && _numberOfPages > 0) {
    // Update active indicator position.
    CGFloat transformX = scrolledPercentage * _trackLength;
    if (!_isDeferredScrolling) {
      [_animatedIndicator updateIndicatorTransformX:transformX];
    }

    // Determine endpoints for drawing track depending on direction scrolled.
    NSInteger scrolledPageNumber = [self scrolledPageNumber:scrollView];
    CGPoint startPoint = [_indicatorPositions[scrolledPageNumber] CGPointValue];
    CGPoint endPoint = startPoint;
    CGFloat radius = kPageControlIndicatorRadius;
    if (transformX > startPoint.x - radius) {
      endPoint = [_indicatorPositions[scrolledPageNumber + 1] CGPointValue];
    } else if (transformX < startPoint.x - radius) {
      startPoint = [_indicatorPositions[scrolledPageNumber - 1] CGPointValue];
    }

    if (scrollView.isDragging) {
      // Draw or extend track.
      if (_trackLayer.isTrackHidden) {
        [_trackLayer drawTrackFromStartPoint:startPoint toEndPoint:endPoint];
      } else {
        [_trackLayer extendTrackFromStartPoint:startPoint toEndPoint:endPoint];
      }
    }

    // Hide indicators to be shown with animated reveal once track is removed.
    if (!_isDeferredScrolling) {
      [_indicators[scrolledPageNumber] setHidden:YES];
    }
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  // Remove track towards current active indicator position.
  NSInteger scrolledPageNumber = [self scrolledPageNumber:scrollView];
  CGPoint point = [_indicatorPositions[scrolledPageNumber] CGPointValue];
  BOOL shouldReverse = (_currentPage > scrolledPageNumber);
  BOOL sendAction = (_currentPage != scrolledPageNumber);
  _currentPage = scrolledPageNumber;

  [_trackLayer removeTrackTowardsPoint:point
                            completion:^{
                              // Animate hidden indicators once more when completed to ensure all
                              // indicators
                              // have been revealed.
                              [self revealIndicatorsReversed:shouldReverse];
                            }];

  // Animate hidden indicators staggered towards current page indicator. Show indicators
  // in reverse if scrolling to left.
  [self revealIndicatorsReversed:shouldReverse];

  // Send notification if new scrolled page.
  if (sendAction) {
    [self sendActionsForControlEvents:UIControlEventValueChanged];
  }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  _isDeferredScrolling = NO;
  NSInteger scrolledPageNumber = [self scrolledPageNumber:scrollView];
  BOOL shouldReverse = (_currentPage > scrolledPageNumber);
  _currentPage = scrolledPageNumber;
  [self revealIndicatorsReversed:shouldReverse];
}

#pragma mark - Indicators

- (void)revealIndicatorsReversed:(BOOL)reversed {
  // Animate hidden indicators staggered with delay.
  NSArray<MDCPageControlIndicator *> *indicators =
      reversed ? [[_indicators reverseObjectEnumerator] allObjects] : _indicators;
  NSInteger count = 0;
  for (MDCPageControlIndicator *indicator in indicators) {
    // Determine if this is the current page indicator.
    NSInteger indicatorIndex = [indicators indexOfObject:indicator];
    if (reversed) {
      indicatorIndex = [indicators count] - 1 - indicatorIndex;
    }
    BOOL isCurrentPageIndicator = indicatorIndex == _currentPage;

    // Reveal indicators if hidden and not current page indicator.
    if (indicator.isHidden && !isCurrentPageIndicator) {
      dispatch_time_t popTime = dispatch_time(
          DISPATCH_TIME_NOW, (int64_t)(kPageControlIndicatorShowDelay * count * NSEC_PER_SEC));
      dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [indicator revealIndicator];
      });
      count++;
    }
  }
}

#pragma mark - UIGestureRecognizer

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
  CGPoint touchPoint = [gesture locationInView:self];
  BOOL willDecrement = touchPoint.x < CGRectGetMidX(self.bounds);
  NSInteger nextPage;
  if (willDecrement) {
    nextPage = _currentPage - 1;
  } else {
    nextPage = _currentPage + 1;
  }

  // Quit if scrolling past bounds.
  if ([self isPageIndexValid:nextPage]) {
    if (_defersCurrentPageDisplay) {
      _isDeferredScrolling = YES;
      _currentPage = nextPage;
    } else {
      [self setCurrentPage:nextPage animated:YES];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
  }
}

- (void)updateCurrentPageDisplay {
  // If _defersCurrentPageDisplay = YES, then update control only when this method is called.
  if (_defersCurrentPageDisplay && [self isPageIndexValid:_currentPage]) {
    [self setCurrentPage:_currentPage];

    // Reset hidden state of indicators.
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (int i = 0; i < _numberOfPages; i++) {
      MDCPageControlIndicator *indicator = _indicators[i];
      indicator.hidden = (i == _currentPage) ? YES : NO;
    }
    [CATransaction commit];
  }
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
  return YES;
}

- (NSString *)accessibilityLabel {
  return
      [[self class] pageControlAccessibilityLabelWithPage:_currentPage + 1 ofPages:_numberOfPages];
}

- (UIAccessibilityTraits)accessibilityTraits {
  return UIAccessibilityTraitAdjustable;
}

- (void)accessibilityIncrement {
  // Quit if scrolling past bounds.
  NSInteger nextPage = _currentPage + 1;
  if ([self isPageIndexValid:nextPage]) {
    [self setCurrentPage:nextPage animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                    [self accessibilityLabel]);
  }
}

- (void)accessibilityDecrement {
  // Quit if scrolling past bounds.
  NSInteger nextPage = _currentPage - 1;
  if ([self isPageIndexValid:nextPage]) {
    [self setCurrentPage:nextPage animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                    [self accessibilityLabel]);
  }
}

#pragma mark - Private

- (void)resetControl {
  // Clear indicators.
  for (CALayer *layer in [_containerView.layer.sublayers copy]) {
    if (layer != _trackLayer) {
      [layer removeFromSuperlayer];
    }
  }
  _indicators = [NSMutableArray arrayWithCapacity:_numberOfPages];
  _indicatorPositions = [NSMutableArray arrayWithCapacity:_numberOfPages];

  if (_numberOfPages == 0) {
    [self setNeedsLayout];
    return;
  }

  // Create indicators.
  CGFloat radius = kPageControlIndicatorRadius;
  CGFloat margin = kPageControlIndicatorMargin;
  for (int i = 0; i < _numberOfPages; i++) {
    CGFloat offsetX = i * (margin + (radius * 2));
    CGFloat offsetY = radius;
    CGPoint center = CGPointMake(offsetX + radius, offsetY);
    MDCPageControlIndicator *indicator =
        [[MDCPageControlIndicator alloc] initWithCenter:center radius:radius];
    indicator.opacity = kPageControlIndicatorDefaultOpacity;
    [_containerView.layer addSublayer:indicator];
    [_indicators addObject:indicator];
    [_indicatorPositions addObject:[NSValue valueWithCGPoint:indicator.position]];
  }

  // Resize container view to keep indicators centered.
  CGFloat frameWidth = _containerView.frame.size.width;
  CGSize controlSize = [MDCPageControl sizeForNumberOfPages:_numberOfPages];
  _containerView.frame = CGRectInset(_containerView.frame, (frameWidth - controlSize.width) / 2, 0);
  _trackLength = CGRectGetWidth(_containerView.frame) - (radius * 2);

  // Add animated indicator that will travel freely across the container. Its transform will be
  // updated by calling its -updateIndicatorTransformX method.
  CGPoint center = CGPointMake(radius, radius);
  CGPoint point = [_indicatorPositions[_currentPage] CGPointValue];
  _animatedIndicator = [[MDCPageControlIndicator alloc] initWithCenter:center radius:radius];
  [_animatedIndicator updateIndicatorTransformX:point.x - kPageControlIndicatorRadius];
  [_containerView.layer addSublayer:_animatedIndicator];

  [self setNeedsLayout];
}

#pragma mark - Strings

+ (NSString *)pageControlAccessibilityLabelWithPage:(NSInteger)currentPage
                                            ofPages:(NSInteger)ofPages {
  NSString *key = kMaterialPageControlStringTable[kStr_MaterialPageControlAccessibilityLabel];
  NSString *localizedString = NSLocalizedStringFromTableInBundle(
      key, kMaterialPageControlStringsTableName, [self bundle], @"page {number} of {total number}");
  return [NSString localizedStringWithFormat:localizedString, currentPage, ofPages];
}

#pragma mark - Resource bundle

+ (NSBundle *)bundle {
  static NSBundle *bundle = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    bundle = [NSBundle bundleWithPath:[self bundlePathWithName:kMaterialPageControlBundle]];
  });

  return bundle;
}

+ (NSString *)bundlePathWithName:(NSString *)bundleName {
  // In iOS 8+, we could be included by way of a dynamic framework, and our resource bundles may
  // not be in the main .app bundle, but rather in a nested framework, so figure out where we live
  // and use that as the search location.
  NSBundle *bundle = [NSBundle bundleForClass:[MDCPageControl class]];
  NSString *resourcePath = [(nil == bundle ? [NSBundle mainBundle] : bundle)resourcePath];
  return [resourcePath stringByAppendingPathComponent:bundleName];
}

@end
