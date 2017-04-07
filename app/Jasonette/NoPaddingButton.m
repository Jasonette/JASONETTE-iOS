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
    UIEdgeInsets insets = self.contentEdgeInsets;
    contentSize.height += insets.top + insets.bottom;
    contentSize.width += insets.left + insets.right;
    return contentSize;
}
@end
