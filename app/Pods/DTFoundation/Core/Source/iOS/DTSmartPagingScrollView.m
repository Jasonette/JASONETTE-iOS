//
//  DTSmartPagingScrollView.m
//  DTSmartPhotoView
//
//  Created by Stefan Gugarel on 5/11/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTSmartPagingScrollView.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

#import "DTCoreGraphicsUtils.h"

@interface DTSmartPagingScrollView ()

- (void)_setupVisiblePageViews;
- (CGRect)frameForPageViewAtIndex:(NSUInteger)index;
- (void)_updateCurrentPage;
- (void)_commonInit;

@end


@implementation DTSmartPagingScrollView
{
	DT_WEAK_VARIABLE id <DTSmartPagingScrollViewDatasource> _pageDatasource;
	
	NSUInteger _numberOfPages;
	NSMutableDictionary *_viewsByPage;
	
	NSMutableSet *_visiblePageViews;
	
	NSUInteger _currentPageIndex;
	
	BOOL _firstLayoutDone;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self _commonInit];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self _commonInit];
	}
	return self;
}

- (void)_commonInit
{
#if !TARGET_OS_TV
	self.pagingEnabled = YES;
#endif
	// no indicators because zooming subview has there
	self.showsVerticalScrollIndicator = NO;
	self.showsHorizontalScrollIndicator = NO;
	
	_viewsByPage = [[NSMutableDictionary alloc] init];
	_visiblePageViews = [[NSMutableSet alloc] init];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (!_numberOfPages)
	{
		return;
	}
	
	if (self.dragging)
	{
		// perform update right away
		[self _updateCurrentPage];
	}
	
	// Note: first content size plus page so that the visible view is properly shown
	CGSize neededContentSize = CGSizeMake(self.bounds.size.width * _numberOfPages, self.bounds.size.height);
	
	if (!CGSizeEqualToSize(neededContentSize, self.contentSize))
	{
		// frame changed
		self.contentSize = neededContentSize;
		
		[self scrollToPage:_currentPageIndex animated:NO];
	}
	
	[self _setupVisiblePageViews];
}

- (void)_updateCurrentPage
{
	NSUInteger newPageIndex = round(self.contentOffset.x / self.frame.size.width);
	
	if (_currentPageIndex != newPageIndex)
	{
		[self willChangeValueForKey:@"currentPageIndex"];
		_currentPageIndex = newPageIndex;
		
		if ([_pageDatasource respondsToSelector:@selector(smartPagingScrollView:didScrollToPageAtIndex:)])
		{
			[_pageDatasource smartPagingScrollView:self didScrollToPageAtIndex:_currentPageIndex];
		}
		
 		[self didChangeValueForKey:@"currentPageIndex"];
	}
}

- (NSRange)rangeOfVisiblePages
{
	CGFloat position = self.contentOffset.x / self.bounds.size.width;
	
	NSInteger firstVisibleIndex = MAX(CGFloat_(0), floor(position));
	NSInteger lastVisibleIndex = MIN(ceil(position), CGFloat_(_numberOfPages-1));
	
	// check if right page is really visible
	CGRect rightFrame = [self frameForPageViewAtIndex:lastVisibleIndex];
	
	if (!CGRectIntersectsRect(rightFrame, self.bounds))
	{
		lastVisibleIndex--;
	}
	
	// check if left page is really visible
	CGRect leftFrame = [self frameForPageViewAtIndex:firstVisibleIndex];
	
	if (!CGRectIntersectsRect(leftFrame, self.bounds))
	{
		firstVisibleIndex++;
	}
	
	return NSMakeRange(firstVisibleIndex, lastVisibleIndex - firstVisibleIndex + 1);
}

- (UIView *)viewForIndex:(NSUInteger)index
{
	NSNumber *cacheKey = [NSNumber numberWithUnsignedInteger:index];
	
	UIView *view = [_viewsByPage objectForKey:cacheKey];
	
	if (view)
	{
		// got cached view
		return view;
	}
	
	// get view from datasource
	view = [_pageDatasource smartPagingScrollView:self viewForPageAtIndex:index];
	
	// cache it
	[_viewsByPage setObject:view forKey:cacheKey];
	
	return view;
}

- (void)_setupVisiblePageViews
{
    NSRange visibleRange = [self rangeOfVisiblePages];
    
    [CATransaction begin];
    [CATransaction setDisableActions:NO];
    
    NSMutableSet *newVisiblePageViews = [NSMutableSet set];
    
    for (NSInteger idx = visibleRange.location; idx<NSMaxRange(visibleRange); idx++)
    {
        UIView *view = [self viewForIndex:idx];
        
        CGRect viewFrame = [self frameForPageViewAtIndex:idx];
        view.tag = (1000 + idx);
        
        if (view.superview!=self)
        {
            [self insertSubview:view atIndex:0];
        }
        
        if (!CGRectEqualToRect(view.frame, viewFrame))
        {
            view.frame = viewFrame;
        }
        
        [newVisiblePageViews addObject:view];
    }
    
    // remove pages that are no longer visible
    
    NSMutableSet *toBeRemoved = _visiblePageViews;
    [toBeRemoved minusSet:newVisiblePageViews];
    _visiblePageViews = newVisiblePageViews;
    
    for (UIView *view in toBeRemoved)
    {
        [view removeFromSuperview];
        
        NSNumber *cacheKey = [NSNumber numberWithUnsignedInteger:(view.tag - 1000)];
        [_viewsByPage removeObjectForKey:cacheKey];
    }
    [CATransaction commit];
}

- (CGRect)frameForPageViewAtIndex:(NSUInteger)index
{
	CGRect frame = self.bounds;
	frame.origin.x = index * frame.size.width;
	
	frame = CGRectInset(frame, CGFloat_(10), CGFloat_(0));
	
	return frame;
}

- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated
{
	CGRect pageRect = CGRectMake(CGFloat_(page) * self.frame.size.width, CGFloat_(0), self.frame.size.width, self.frame.size.height);
	[self scrollRectToVisible:pageRect animated:animated];
}

- (void)reloadData
{
	if (!_pageDatasource)
	{
		return;
	}
	
	// clean up
	for (UIView *oneView in _visiblePageViews)
	{
		[oneView removeFromSuperview];
	}
	
	[_visiblePageViews removeAllObjects];
	[_viewsByPage removeAllObjects];
	
	// load
	_numberOfPages = [_pageDatasource numberOfPagesInSmartPagingScrollView:self];
	
	// make sure we stay in valid range
	_currentPageIndex = MAX(0, MIN(_currentPageIndex, _numberOfPages-1));
	
	[self setNeedsLayout];
}

- (void)setPageDatasource:(id<DTSmartPagingScrollViewDatasource>)pageDatasource
{
	if (_pageDatasource != pageDatasource)
	{
		_pageDatasource = pageDatasource;
		
		// refresh parameters
		[self reloadData];
	}
}

- (void)setCurrentPageIndex:(NSUInteger)currentPageIndex
{
	if (_currentPageIndex != currentPageIndex)
	{
		_currentPageIndex = currentPageIndex;
		
		[self scrollToPage:_currentPageIndex animated:NO];
	}
}

@synthesize pageDatasource = _pageDatasource;
@synthesize currentPageIndex = _currentPageIndex;

@end

#endif
