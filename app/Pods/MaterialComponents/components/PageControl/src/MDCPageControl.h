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

#import <UIKit/UIKit.h>

/**
 A Material page control.

 This control is designed to be a drop-in replacement for UIPageControl, but adhering to the
 Material Design specifications for animation and layout.

 The UIControlEventValueChanged control event is sent when the user changes the current page.

 ### UIScrollViewDelegate

 In order for the Page Control to respond correctly to scroll events set the scrollView.delegate to
 your pageControl:

   scrollView.delegate = pageControl;

 or forward the UIScrollViewDelegate methods:

   @c scrollViewDidScroll:
   @c scrollViewDidEndDecelerating:
   @c scrollViewDidEndScrollingAnimation:

 */
@interface MDCPageControl : UIControl <UIScrollViewDelegate>

#pragma mark Managing the page

/**
 The number of page indicators in the control.

 Negative values are clamped to 0.

 The default value is 0.
 */
@property(nonatomic) NSInteger numberOfPages;

/**
 The current page indicator of the control.

 See setCurrentPage:animated: for animated version.

 Values outside the possible range are clamped within [0, numberOfPages-1].

 The default value is 0.
 */
@property(nonatomic) NSInteger currentPage;

/**
 Sets the current page indicator of the control.

 @param currentPage Index of the desired page indicator. Values outside the possible range are
                    clamped within [0, numberOfPages-1].
 @param animated    YES the change will be animated; otherwise, NO.
 */
- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated;

/**
 A Boolean value that controls whether the page control is hidden when there is only one page.

 The default value is NO.
 */
@property(nonatomic) BOOL hidesForSinglePage;

#pragma mark Configuring the page colors

/** The color of the non-current page indicators. */
@property(nonatomic, strong, nullable) UIColor *pageIndicatorTintColor UI_APPEARANCE_SELECTOR;

/** The color of the current page indicator. */
@property(nonatomic, strong, nullable)
    UIColor *currentPageIndicatorTintColor UI_APPEARANCE_SELECTOR;

#pragma mark Configuring the page behavior

/**
 A Boolean value that controls when the current page is displayed.

 If enabled, user interactions that cause the current page to change will not be visually
 reflected until -updateCurrentPageDisplay is called.

 The default value is NO.
 */
@property(nonatomic) BOOL defersCurrentPageDisplay;

/**
 When this value is set to YES, the indicators will ascend from right to left in an RTL environment.

 @note In general, the MDCPageControl's UIScrollViewDelegate forwarding methods make assumptions
 about the originating scrollview's page number based off its contentOffset. When this property is
 set to YES in an RTL environment, a leftmost content offset will be considered the last page in the
 scrollview, as opposed to the first.

 The default value is NO.
 */
@property(nonatomic) BOOL respectsUserInterfaceLayoutDirection;

/**
 Updates the page indicator to the current page.

 This method is ignored if defersCurrentPageDisplay is NO.
 */
- (void)updateCurrentPageDisplay;

#pragma mark Resizing the control

/**
 Returns the size required to accommodate the given number of pages.

 @param pageCount The number of pages for which an estimated size should be returned.
 */
+ (CGSize)sizeForNumberOfPages:(NSInteger)pageCount;

#pragma mark UIScrollView interface

/** The owner must call this to inform the control that scrolling has occurred. */
- (void)scrollViewDidScroll:(nonnull UIScrollView *)scrollView;

/** The owner must call this when the scrollView has ended its deleration. */
- (void)scrollViewDidEndDecelerating:(nonnull UIScrollView *)scrollView;

/** The owner must call this when the scrollView has ended its scrolling animation. */
- (void)scrollViewDidEndScrollingAnimation:(nonnull UIScrollView *)scrollView;

/**
 A block that is invoked when the @c MDCPageControl receives a call to @c
 traitCollectionDidChange:. The block is called after the call to the superclass.
 */
@property(nonatomic, copy, nullable) void (^traitCollectionDidChangeBlock)
    (MDCPageControl *_Nonnull pageControl, UITraitCollection *_Nullable previousTraitCollection);

@end
