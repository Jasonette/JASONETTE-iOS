//
//  JasonHorizontalSectionItem.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonHorizontalSectionItem.h"

@implementation JasonHorizontalSectionItem
{
    BOOL isWidthCalculated;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for(UIView *subview in [self.contentView subviews]) {
        [subview removeFromSuperview];
    }
}
- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes

{
    UICollectionViewLayoutAttributes *attributes = [layoutAttributes copy];
    if(!isWidthCalculated){
        [self setNeedsLayout];
        [self layoutIfNeeded];
        float desiredWidth = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].width;
        CGRect frame = attributes.frame;
        frame.size.width = desiredWidth;
        attributes.frame = frame;
        isWidthCalculated = YES;
    }
    return attributes;

}


@end
