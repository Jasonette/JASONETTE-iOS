//
//  NoPaddingButton.m
//  Jasonette
//
//  Created by e on 4/7/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "NoPaddingButton.h"

@implementation NoPaddingButton
- (CGSize)intrinsicContentSize {
    CGSize labelContentSize = self.titleLabel.intrinsicContentSize;
    CGSize imageContentSize = self.imageView.frame.size;

    if(labelContentSize.width > 0){
        // label type => use the size sans padding
        UIEdgeInsets insets = self.contentEdgeInsets;
        labelContentSize.height += insets.top + insets.bottom;
        labelContentSize.width += insets.left + insets.right;
        return labelContentSize;
    } else {
        // image type => use the default size
        UIEdgeInsets insets = self.contentEdgeInsets;
        imageContentSize.height += insets.top + insets.bottom;
        imageContentSize.width += insets.left + insets.right;
        return imageContentSize;
    }
}
@end
