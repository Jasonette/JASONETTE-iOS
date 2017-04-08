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
    CGSize contentSize = self.titleLabel.intrinsicContentSize;
    if(contentSize.width > 0){
        // label type => use the size sans padding
        UIEdgeInsets insets = self.contentEdgeInsets;
        contentSize.height += insets.top + insets.bottom;
        contentSize.width += insets.left + insets.right;
        return contentSize;
    } else {
        // image type => use the default size
        return [super intrinsicContentSize];
    }
}
@end
