//
// REMenuItemView.m
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

#import "REMenuItemView.h"
#import "REMenuItem.h"

@interface REMenuItemView ()

@property (strong, readwrite, nonatomic) UIView *backgroundView;

@end

@implementation REMenuItemView

- (id)initWithFrame:(CGRect)frame menu:(REMenu *)menu item:(REMenuItem*) item hasSubtitle:(BOOL)hasSubtitle
{
    self = [super initWithFrame:frame];
    if (self) {
        self.menu = menu;
        self.item = item;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.accessibilityHint = NSLocalizedString(@"Double tap to choose", @"Double tap to choose");
        
        _backgroundView = ({
            UIView *view = [[UIView alloc] initWithFrame:self.bounds];
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            view;
        });
        [self addSubview:_backgroundView];
        
        CGRect titleFrame;
        if (hasSubtitle) {
            // Dividing lines at 1/1.725 (vs 1/2.000) results in labels about 28-top 20-bottom or 60/40 title/subtitle (for a 48 frame height)
            //
            titleFrame = CGRectMake(self.item.textOffset.width == 0.0 && self.item.textOffset.height == 0.0 ? self.menu.textOffset.width : self.item.textOffset.width, self.item.textOffset.width == 0.0 && self.item.textOffset.height == 0.0 ? self.menu.textOffset.height : self.item.textOffset.height, 0, floorf(frame.size.height / 1.725));

            CGRect subtitleFrame = CGRectMake(self.item.subtitleTextOffset.width == 0.0 && self.item.subtitleTextOffset.height == 0.0 ? self.menu.subtitleTextOffset.width : self.item.subtitleTextOffset.width, (self.item.subtitleTextOffset.width == 0.0 && self.item.subtitleTextOffset.height == 0.0 ? self.menu.subtitleTextOffset.height : self.item.subtitleTextOffset.height) + titleFrame.size.height, 0, floorf(frame.size.height * (1.0 - 1.0 / 1.725)));
            self.subtitleLabel = ({
                UILabel *label =[[UILabel alloc] initWithFrame:subtitleFrame];
                label.contentMode = UIViewContentModeCenter;
                label.textAlignment = (NSInteger)self.item.subtitleTextAlignment == -1 ? self.menu.subtitleTextAlignment : self.item.subtitleTextAlignment;
                label.backgroundColor = [UIColor clearColor];
                label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                label.isAccessibilityElement = NO;
                label;
            });
            [self addSubview:_subtitleLabel];
        } else {
            titleFrame = CGRectMake(self.item.textOffset.width == 0.0 && self.item.textOffset.height == 0.0 ? self.menu.textOffset.width : self.item.textOffset.width, self.item.textOffset.width == 0.0 && self.item.textOffset.height == 0.0 ? self.menu.textOffset.height : self.item.textOffset.height, 0, frame.size.height);
        }

        _titleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:titleFrame];
            label.isAccessibilityElement = NO;
            label.contentMode = UIViewContentModeCenter;
            label.textAlignment = (NSInteger)self.item.textAlignment == -1 ? self.menu.textAlignment : self.item.subtitleTextAlignment;
            label.backgroundColor = [UIColor clearColor];
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            label;
        });

        _imageView = [[UIImageView alloc] initWithFrame:CGRectNull];
        
        _badgeLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.backgroundColor = [UIColor colorWithWhite:0.559 alpha:1.000];
            label.font = [UIFont systemFontOfSize:11];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            label.hidden = YES;
            label.layer.cornerRadius = 4.0;
            label.layer.borderColor =  [UIColor colorWithWhite:0.630 alpha:1.000].CGColor;
            label.layer.borderWidth = 1.0;
            label.layer.masksToBounds = YES;
            label;
        });
        
        [self addSubview:_titleLabel];
        [self addSubview:_imageView];
        [self addSubview:_badgeLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.image = self.item.image;
    
    // Adjust frames
    //
    CGFloat verticalOffset = floor((self.frame.size.height - self.item.image.size.height) / 2.0);
    CGFloat horizontalOffset = floor((self.menu.itemHeight - self.item.image.size.height) / 2.0);
    CGFloat x = (self.menu.imageAlignment == REMenuImageAlignmentLeft) ? horizontalOffset + self.menu.imageOffset.width :
                                                                         self.titleLabel.frame.size.width - (horizontalOffset + self.menu.imageOffset.width + self.item.image.size.width);
    self.imageView.frame = CGRectMake(x, verticalOffset + self.menu.imageOffset.height, self.item.image.size.width, self.item.image.size.height);
    if ([self.imageView respondsToSelector:@selector(setTintColor:)]) {
        self.imageView.tintColor = self.menu.imageTintColor;
    }
    
    if ([self.imageView respondsToSelector:@selector(setBackgroundColor:)]) {
        self.imageView.backgroundColor = self.item.imageBackgroundColor;
    }
    
    // Set up badge
    //
    self.badgeLabel.hidden = !self.item.badge;
    if (self.item.badge) {
        self.badgeLabel.text = self.item.badge;
        NSAttributedString *badgeAttributedString = [[NSAttributedString alloc] initWithString:self.item.badge
                                                                                    attributes:@{NSFontAttributeName:self.badgeLabel.font}];
        CGRect rect = [badgeAttributedString boundingRectWithSize:CGSizeMake(CGRectGetMaxX(self.frame), CGRectGetMaxY(self.frame))
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                          context:nil];
        CGFloat x = self.menu.imageAlignment == REMenuImageAlignmentLeft ? CGRectGetMaxX(self.imageView.frame) - 2.0 :
        CGRectGetMinX(self.imageView.frame) - rect.size.height - 4.0;
        self.badgeLabel.frame = CGRectMake(x, self.imageView.frame.origin.y - 2.0, rect.size.width + 6.0, rect.size.height + 2.0);
       
        if (self.menu.badgeLabelConfigurationBlock)
            self.menu.badgeLabelConfigurationBlock(self.badgeLabel, self.item);
    }
    
    // Accessibility
    //
    self.accessibilityLabel = self.item.title;
    if (self.subtitleLabel.text)
        self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", self.item.title, self.item.subtitle];
    
    // Adjust styles
    //
    self.backgroundView.backgroundColor = self.item.backgroundColor == nil ? [UIColor clearColor] : self.item.backgroundColor;
    self.titleLabel.font = self.item.font == nil ? self.menu.font : self.item.font;
    self.titleLabel.text = self.item.title;
    self.titleLabel.textColor = self.item.textColor == nil ? self.menu.textColor : self.item.textColor;
    self.titleLabel.shadowColor = self.item.textShadowColor ? self.menu.textShadowColor : self.item.textShadowColor;
    self.titleLabel.shadowOffset = self.item.textShadowOffset.width == 0 && self.item.textShadowOffset.height == 0 ? self.menu.textShadowOffset : self.item.textShadowOffset;
    self.titleLabel.textAlignment = (NSInteger)self.item.textAlignment == -1 ? self.menu.textAlignment : self.item.textAlignment;
    self.subtitleLabel.font = self.item.subtitleFont == nil ? self.menu.subtitleFont : self.item.subtitleFont
;
    self.subtitleLabel.text = self.item.subtitle;
    self.subtitleLabel.textColor = self.item.subtitleTextColor == nil ? self.menu.subtitleTextColor : self.item.subtitleTextColor;
    self.subtitleLabel.shadowColor = self.item.subtitleTextShadowColor == nil ? self.menu.subtitleTextShadowColor : self.item.subtitleTextShadowColor;
    self.subtitleLabel.shadowOffset = self.item.subtitleTextShadowOffset.width == 0 && self.item.subtitleTextShadowOffset.height == 0 ? self.menu.subtitleTextShadowOffset : self.item.subtitleTextShadowOffset;
    self.subtitleLabel.textAlignment = (NSInteger)self.item.subtitleTextAlignment == -1 ? self.menu.subtitleTextAlignment : self.item.subtitleTextAlignment;
    
    self.item.customView.frame = CGRectMake(0, 0, self.titleLabel.frame.size.width, self.frame.size.height);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.backgroundView.backgroundColor = self.item.highlightedBackgroundColor == nil ? self.menu.highlightedBackgroundColor : self.item.highlightedBackgroundColor;
    self.separatorView.backgroundColor = self.item.highlightedSeparatorColor == nil ? self.menu.highlightedSeparatorColor : self.item.highlightedSeparatorColor;
    self.imageView.image = self.item.highlightedImage ? self.item.highlightedImage : self.item.image;
    if ([self.imageView respondsToSelector:@selector(setTintColor:)]) {
        self.imageView.tintColor = self.menu.highlightedImageTintColor;
    }
    self.titleLabel.textColor = self.item.highlightedTextColor == nil ? self.menu.highlightedTextColor : self.item.highlightedTextColor;
    self.titleLabel.shadowColor = self.item.highlightedTextShadowColor == nil ? self.menu.highlightedTextShadowColor : self.item.highlightedTextShadowColor;
    self.titleLabel.shadowOffset = self.item.highlightedTextShadowOffset.width == 0 && self.item.highlightedTextShadowOffset.height == 0 ? self.menu.highlightedTextShadowOffset : self.item.highlightedTextShadowOffset;
    self.subtitleLabel.textColor = self.item.subtitleHighlightedTextColor == nil ? self.menu.subtitleHighlightedTextColor : self.item.subtitleHighlightedTextColor;
    self.subtitleLabel.shadowColor = self.item.subtitleHighlightedTextShadowColor == nil ? self.menu.subtitleHighlightedTextShadowColor : self.item.subtitleHighlightedTextShadowColor;
    self.subtitleLabel.shadowOffset = self.item.subtitleHighlightedTextShadowOffset.width == 0 && self.item.subtitleHighlightedTextShadowOffset.height == 0 ? self.menu.subtitleHighlightedTextShadowOffset : self.item.subtitleHighlightedTextShadowOffset;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.backgroundView.backgroundColor = self.item.backgroundColor == nil ? [UIColor clearColor] : self.item.backgroundColor;
    self.separatorView.backgroundColor = self.menu.separatorColor;
    self.imageView.image = self.item.image;
    if ([self.imageView respondsToSelector:@selector(setTintColor:)]) {
        self.imageView.tintColor = self.menu.imageTintColor;
    }
    self.titleLabel.textColor = self.item.textColor == nil ? self.menu.textColor : self.item.textColor;
    self.titleLabel.shadowColor = self.item.textShadowColor == nil ?self.menu.textShadowColor : self.item.textShadowColor;
    self.titleLabel.shadowOffset = self.item.textShadowOffset.width == 0  && self.item.textShadowOffset.height == 0 ? self.menu.textShadowOffset : self.item.textShadowOffset;
    self.subtitleLabel.textColor = self.item.subtitleTextColor == nil ? self.menu.subtitleTextColor : self.item.subtitleTextColor;
    self.subtitleLabel.shadowColor = self.item.subtitleTextShadowColor == nil ? self.menu.subtitleTextShadowColor : self.item.subtitleTextShadowColor;
    self.subtitleLabel.shadowOffset = self.item.subtitleTextShadowOffset.width == 0 && self.item.subtitleTextShadowOffset.height == 0 ? self.menu.subtitleTextShadowOffset : self.item.subtitleTextShadowOffset;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.backgroundView.backgroundColor = self.item.backgroundColor == nil ? [UIColor clearColor] : self.item.backgroundColor;
    self.separatorView.backgroundColor = self.item.separatorColor == nil ? self.menu.separatorColor : self.item.separatorColor;
    self.imageView.image = self.item.image;
    if ([self.imageView respondsToSelector:@selector(setTintColor:)]) {
        self.imageView.tintColor = self.menu.imageTintColor;
    }
    self.titleLabel.textColor = self.item.textColor == nil ? self.menu.textColor : self.item.textColor;
    self.titleLabel.shadowColor = self.item.textShadowColor == nil ? self.menu.textShadowColor : self.item.textShadowColor;
    self.titleLabel.shadowOffset = self.item.textShadowOffset.width == 0 && self.item.textShadowOffset.height ? self.menu.textShadowOffset : self.item.textShadowOffset;
    self.subtitleLabel.textColor = self.item.subtitleTextColor == nil ? self.menu.subtitleTextColor : self.item.subtitleTextColor;
    self.subtitleLabel.shadowColor = self.menu.subtitleTextShadowColor == nil ? self.menu.subtitleTextShadowColor : self.item.subtitleTextShadowColor;
    self.subtitleLabel.shadowOffset = self.item.subtitleTextShadowOffset.width == 0 && self.item.subtitleTextShadowOffset.height == 0 ? self.menu.subtitleTextShadowOffset : self.item.subtitleTextShadowOffset;

    CGPoint endedPoint = [touches.anyObject locationInView:self];
    if (endedPoint.y < 0 || endedPoint.y > CGRectGetHeight(self.bounds))
        return;
    
    if (!self.menu.closeOnSelection) {
        if (self.item.action)
            self.item.action(self.item);
    } else {
        if (self.item.action) {
            if (self.menu.waitUntilAnimationIsComplete) {
                __typeof (&*self) __weak weakSelf = self;
                [self.menu closeWithCompletion:^{
                    weakSelf.item.action(weakSelf.item);
                }];
            } else {
                [self.menu close];
                self.item.action(self.item);
            }
        }
    }
}

@end
