//
// REMenuContainerView.m
// REMenu
//
// Copyright (c) 2013 Roman Efimov (https://github.com/romaonthego)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "REMenuContainerView.h"
#import <QuartzCore/QuartzCore.h>

@implementation REMenuContainerView

- (void)layoutSubviews
{
    [super layoutSubviews];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    CGFloat landscapeOffset = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 32.0 : 44.0;
    
    if (self.navigationBar && !self.appearsBehindNavigationBar) {
        CGRect frame = self.frame;
        frame.origin.y = self.navigationBar.frame.origin.y + (UIDeviceOrientationIsPortrait(orientation) ? 44.0 : landscapeOffset);
        self.frame = frame;
    }
    
    if (self.appearsBehindNavigationBar) {
        CGRect frame = self.frame;
        frame.origin.y = (UIDeviceOrientationIsPortrait(orientation) ? 44.0 : landscapeOffset) - 44;
        self.frame = frame;
    }
}

@end
