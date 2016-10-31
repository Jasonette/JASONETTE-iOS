//
//  UITableView+DHSmartScreenshot.m
//  TableViewScreenshots
//
//  Created by Hernandez Alvarez, David on 11/28/13.
//  Copyright (c) 2013 David Hernandez. All rights reserved.
//

#import "UITableView+DHSmartScreenshot.h"
#import "UIView+DHSmartScreenshot.h"
#import "UIImage+DHImageAdditions.h"

@implementation UITableView (DHSmartScreenshot)

- (UIImage *)screenshot
{
	return [self screenshotExcludingHeadersAtSections:nil
						   excludingFootersAtSections:nil
							excludingRowsAtIndexPaths:nil];
}

- (UIImage *)screenshotOfCellAtIndexPath:(NSIndexPath *)indexPath
{
	UIImage *cellScreenshot = nil;
	
	// Current tableview offset
	CGPoint currTableViewOffset = self.contentOffset;
	
	// First, scroll the tableview so the cell would be rendered on the view and able to screenshot'it
	[self scrollToRowAtIndexPath:indexPath
				atScrollPosition:UITableViewScrollPositionTop
						animated:NO];
	
	// Take the screenshot
	cellScreenshot = [[self cellForRowAtIndexPath:indexPath] screenshot];
	
	// scroll back to the original offset
	[self setContentOffset:currTableViewOffset animated:NO];
	
	return cellScreenshot;
}

- (UIImage *)screenshotOfHeaderView
{
	CGPoint originalOffset = [self contentOffset];
	CGRect headerRect = [self tableHeaderView].frame;
	
	[self scrollRectToVisible:headerRect animated:NO];
	UIImage *headerScreenshot = [self screenshotForCroppingRect:headerRect];
	[self setContentOffset:originalOffset animated:NO];
	
	return headerScreenshot;
}

- (UIImage *)screenshotOfFooterView
{
	CGPoint originalOffset = [self contentOffset];
	CGRect footerRect = [self tableFooterView].frame;
	
	[self scrollRectToVisible:footerRect animated:NO];
	UIImage *footerScreenshot = [self screenshotForCroppingRect:footerRect];
	[self setContentOffset:originalOffset animated:NO];
	
	return footerScreenshot;
}

- (UIImage *)screenshotOfHeaderViewAtSection:(NSUInteger)section
{
	CGPoint originalOffset = [self contentOffset];
	CGRect headerRect = [self rectForHeaderInSection:section];
	
	[self scrollRectToVisible:headerRect animated:NO];
	UIImage *headerScreenshot = [self screenshotForCroppingRect:headerRect];
	[self setContentOffset:originalOffset animated:NO];
	
	return headerScreenshot;
}

- (UIImage *)screenshotOfFooterViewAtSection:(NSUInteger)section
{
	CGPoint originalOffset = [self contentOffset];
	CGRect footerRect = [self rectForFooterInSection:section];
	
	[self scrollRectToVisible:footerRect animated:NO];
	UIImage *footerScreenshot = [self screenshotForCroppingRect:footerRect];
	[self setContentOffset:originalOffset animated:NO];
	
	return footerScreenshot;
}

- (UIImage *)screenshotExcludingAllHeaders:(BOOL)withoutHeaders
					   excludingAllFooters:(BOOL)withoutFooters
						  excludingAllRows:(BOOL)withoutRows
{
	NSArray *excludedHeadersOrFootersSections = nil;
	if (withoutHeaders || withoutFooters) excludedHeadersOrFootersSections = [self allSectionsIndexes];
	
	NSArray *excludedRows = nil;
	if (withoutRows) excludedRows = [self allRowsIndexPaths];
	
	return [self screenshotExcludingHeadersAtSections:(withoutHeaders)?[NSSet setWithArray:excludedHeadersOrFootersSections]:nil
						   excludingFootersAtSections:(withoutFooters)?[NSSet setWithArray:excludedHeadersOrFootersSections]:nil
							excludingRowsAtIndexPaths:(withoutRows)?[NSSet setWithArray:excludedRows]:nil];
}

- (UIImage *)screenshotExcludingHeadersAtSections:(NSSet *)excludedHeaderSections
					   excludingFootersAtSections:(NSSet *)excludedFooterSections
						excludingRowsAtIndexPaths:(NSSet *)excludedIndexPaths
{
	NSMutableArray *screenshots = [NSMutableArray array];
	// Header Screenshot
	UIImage *headerScreenshot = [self screenshotOfHeaderView];
	if (headerScreenshot) [screenshots addObject:headerScreenshot];
	for (int section=0; section<self.numberOfSections; section++) {
		// Header Screenshot
		UIImage *headerScreenshot = [self screenshotOfHeaderViewAtSection:section excludedHeaderSections:excludedHeaderSections];
		if (headerScreenshot) [screenshots addObject:headerScreenshot];
		
		// Screenshot of every cell of this section
		for (int row=0; row<[self numberOfRowsInSection:section]; row++) {
			NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
			UIImage *cellScreenshot = [self screenshotOfCellAtIndexPath:cellIndexPath excludedIndexPaths:excludedIndexPaths];
			if (cellScreenshot) [screenshots addObject:cellScreenshot];
		}
		
		// Footer Screenshot
		UIImage *footerScreenshot = [self screenshotOfFooterViewAtSection:section excludedFooterSections:excludedFooterSections];
		if (footerScreenshot) [screenshots addObject:footerScreenshot];
	}
	UIImage *footerScreenshot = [self screenshotOfFooterView];
	if (footerScreenshot) [screenshots addObject:footerScreenshot];
	return [UIImage verticalImageFromArray:screenshots];
}

- (UIImage *)screenshotOfHeadersAtSections:(NSSet *)includedHeaderSections
						 footersAtSections:(NSSet *)includedFooterSections
						  rowsAtIndexPaths:(NSSet *)includedIndexPaths
{
	NSMutableArray *screenshots = [NSMutableArray array];
	
	for (int section=0; section<self.numberOfSections; section++) {
		// Header Screenshot
		UIImage *headerScreenshot = [self screenshotOfHeaderViewAtSection:section includedHeaderSections:includedHeaderSections];
		if (headerScreenshot) [screenshots addObject:headerScreenshot];
		
		// Screenshot of every cell of the current section
		for (int row=0; row<[self numberOfRowsInSection:section]; row++) {
			NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
			UIImage *cellScreenshot = [self screenshotOfCellAtIndexPath:cellIndexPath includedIndexPaths:includedIndexPaths];
			if (cellScreenshot) [screenshots addObject:cellScreenshot];
		}
		
		// Footer Screenshot
		UIImage *footerScreenshot = [self screenshotOfFooterViewAtSection:section includedFooterSections:includedFooterSections];
		if (footerScreenshot) [screenshots addObject:footerScreenshot];
	}
	return [UIImage verticalImageFromArray:screenshots];
}

#pragma mark - Hard Working for Screenshots

- (UIImage *)screenshotOfCellAtIndexPath:(NSIndexPath *)indexPath excludedIndexPaths:(NSSet *)excludedIndexPaths
{
	if ([excludedIndexPaths containsObject:indexPath]) return nil;
	return [self screenshotOfCellAtIndexPath:indexPath];
}

- (UIImage *)screenshotOfHeaderViewAtSection:(NSUInteger)section excludedHeaderSections:(NSSet *)excludedHeaderSections
{
	if ([excludedHeaderSections containsObject:@(section)]) return nil;
	
	UIImage *sectionScreenshot = nil;
	sectionScreenshot = [self screenshotOfHeaderViewAtSection:section];
	if (! sectionScreenshot) {
		sectionScreenshot = [self blankScreenshotOfHeaderAtSection:section];
	}
	return sectionScreenshot;
}

- (UIImage *)screenshotOfFooterViewAtSection:(NSUInteger)section excludedFooterSections:(NSSet *)excludedFooterSections
{
	if ([excludedFooterSections containsObject:@(section)]) return nil;
	
	UIImage *sectionScreenshot = nil;
	sectionScreenshot = [self screenshotOfFooterViewAtSection:section];
	if (! sectionScreenshot) {
		sectionScreenshot = [self blankScreenshotOfFooterAtSection:section];
	}
	return sectionScreenshot;
}

- (UIImage *)screenshotOfCellAtIndexPath:(NSIndexPath *)indexPath includedIndexPaths:(NSSet *)includedIndexPaths
{
	if (![includedIndexPaths containsObject:indexPath]) return nil;
	return [self screenshotOfCellAtIndexPath:indexPath];
}

- (UIImage *)screenshotOfHeaderViewAtSection:(NSUInteger)section includedHeaderSections:(NSSet *)includedHeaderSections
{
	if (![includedHeaderSections containsObject:@(section)]) return nil;
	
	UIImage *sectionScreenshot = nil;
	sectionScreenshot = [self screenshotOfHeaderViewAtSection:section];
	if (! sectionScreenshot) {
		sectionScreenshot = [self blankScreenshotOfHeaderAtSection:section];
	}
	return sectionScreenshot;
}

- (UIImage *)screenshotOfFooterViewAtSection:(NSUInteger)section includedFooterSections:(NSSet *)includedFooterSections
{
	if (![includedFooterSections containsObject:@(section)]) return nil;
	
	UIImage *sectionScreenshot = nil;
	sectionScreenshot = [self screenshotOfFooterViewAtSection:section];
	if (! sectionScreenshot) {
		sectionScreenshot = [self blankScreenshotOfFooterAtSection:section];
	}
	return sectionScreenshot;
}

#pragma mark - Blank Screenshots

- (UIImage *)blankScreenshotOfHeaderAtSection:(NSUInteger)section
{
	CGSize headerRectSize = CGSizeMake(self.bounds.size.width, [self rectForHeaderInSection:section].size.height);
	return [UIImage imageWithColor:[UIColor clearColor] size:headerRectSize];
}

- (UIImage *)blankScreenshotOfFooterAtSection:(NSUInteger)section
{
	CGSize footerRectSize = CGSizeMake(self.bounds.size.width, [self rectForFooterInSection:section].size.height);
	return [UIImage imageWithColor:[UIColor clearColor] size:footerRectSize];
}

#pragma mark - All Headers / Footers sections

- (NSArray *)allSectionsIndexes
{
	long numOfSections = [self numberOfSections];
	NSMutableArray *allSectionsIndexes = [NSMutableArray array];
	for (int section=0; section < numOfSections; section++) {
		[allSectionsIndexes addObject:@(section)];
	}
	return allSectionsIndexes;
}

#pragma mark - All Rows Index Paths

- (NSArray *)allRowsIndexPaths
{
	NSMutableArray *allRowsIndexPaths = [NSMutableArray array];
	for (NSNumber *sectionIdx in [self allSectionsIndexes]) {
		for (int rowNum=0; rowNum<[self numberOfRowsInSection:[sectionIdx unsignedIntegerValue]]; rowNum++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowNum inSection:[sectionIdx unsignedIntegerValue]];
			[allRowsIndexPaths addObject:indexPath];
		}
	}
	return allRowsIndexPaths;
}
@end
