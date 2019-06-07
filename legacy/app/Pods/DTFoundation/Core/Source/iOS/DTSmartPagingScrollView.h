//
//  DTSmartPagingScrollView.h
//  DTSmartPhotoView
//
//  Created by Stefan Gugarel on 5/11/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <DTFoundation/DTWeakSupport.h>

@class DTSmartPagingScrollView;


/**
 Protocol for providing pages to <DTSmartPagingScrollView>
 */
@protocol DTSmartPagingScrollViewDatasource <NSObject>

/**
 The number of pages for the <DTSmartPagingScrollView>
 @param smartPagingScrollView The scroll view asking
 @returns The number of pages
 */
- (NSUInteger)numberOfPagesInSmartPagingScrollView:(DTSmartPagingScrollView *)smartPagingScrollView;

/**
 Method to provide UIViews to be used for the pages
 
 The frame of the passed view will be adjusted to the page size of the scroll view
 @param smartPagingScrollView The scroll view asking
 @param index The index of the page to provide
 @returns The view to use for the given page index.
 */
- (UIView *)smartPagingScrollView:(DTSmartPagingScrollView *)smartPagingScrollView viewForPageAtIndex:(NSUInteger)index;

@optional
/**
 The number of pages for the <DTSmartPagingScrollView>
 @param smartPagingScrollView The scroll view asking
 @param index The index of the page
 */
- (void)smartPagingScrollView:(DTSmartPagingScrollView *)smartPagingScrollView didScrollToPageAtIndex:(NSUInteger)index;

@end

/**
 A scroll view that automatically manages a set of pages
 */
@interface DTSmartPagingScrollView : UIScrollView <UIScrollViewDelegate>

/**
 The page data source for the receiver
 */
@property (nonatomic, DT_WEAK_PROPERTY) IBOutlet id <DTSmartPagingScrollViewDatasource> pageDatasource;

/**
 The current page index visible on the receiver
 */
@property (nonatomic, assign) NSUInteger currentPageIndex;

/**
 Reloads the pages from the datasource
 */
- (void)reloadData;

/**
 The range of indexes of the currently visible pages
 */
- (NSRange)rangeOfVisiblePages;

/**
 Scroll the receiver to the given page index
 @param page The index of the page to move to
 @param animated Whether the move should be animated
 */
- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated;

/**
 Get a view for a specified index
 @param index The index of the view to retrieve
 */
- (UIView *)viewForIndex:(NSUInteger)index;

@end
