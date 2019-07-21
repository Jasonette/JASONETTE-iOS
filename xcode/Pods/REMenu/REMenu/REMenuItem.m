//
// REMenuItem.m
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

#import "REMenuItem.h"
#import "REMenuItemView.h"

@interface REMenuItem ()
@property (assign, nonatomic) REMenuItemView *itemView;
@end


@implementation REMenuItem

- (id)initWithTitle:(NSString *)title image:(UIImage *)image highlightedImage:(UIImage *)highlightedImage action:(void (^)(REMenuItem *item))action
{
    self = [super init];
    if (self) {
        _title = title;
        _image = image;
        _highlightedImage = highlightedImage;
        _action = action;
        _textAlignment = -1;
        _subtitleTextAlignment = -1;
    }
    return self;
}

- (id)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image highlightedImage:(UIImage *)highlightedImage action:(void (^)(REMenuItem *item))action
{
    self = [super init];
    if (self) {
        _title = title;
        _subtitle = subtitle;
        _image = image;
        _highlightedImage = highlightedImage;
        _action = action;
        _textAlignment = -1;
        _subtitleTextAlignment = -1;
    }
    return self;
}

- (id)initWithTitle:(NSString *)title image:(UIImage *)image backgroundColor:(UIColor *)bgColor highlightedImage:(UIImage *)highlightedImage action:(void (^)(REMenuItem *item))action
{
    self = [super init];
    if (self) {
        _title = title;
        _image = image;
        _imageBackgroundColor = bgColor;
        _highlightedImage = highlightedImage;
        _action = action;
        _textAlignment = -1;
        _subtitleTextAlignment = -1;
    }
    return self;
}

- (id)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image backgroundColor:(UIColor *)bgColor highlightedImage:(UIImage *)highlightedImage action:(void (^)(REMenuItem *item))action
{
    self = [super init];
    if (self) {
        _title = title;
        _subtitle = subtitle;
        _image = image;
        _imageBackgroundColor = bgColor;
        _highlightedImage = highlightedImage;
        _action = action;
        _textAlignment = -1;
        _subtitleTextAlignment = -1;
    }
    return self;
}

- (id)initWithCustomView:(UIView *)customView action:(void (^)(REMenuItem *item))action
{
    self = [super init];
    if (self) {
        _customView = customView;
        _action = action;
    }
    return self;
}

- (id)initWithCustomView:(UIView *)customView
{
    self = [super init];
    if (self) {
        _customView = customView;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<title: %@; subtitle: %@; tag: %li>", self.title, self.subtitle, (long)self.tag];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.itemView.titleLabel.text = title;
    self.itemView.accessibilityLabel = title;
}

- (void)setSubtitle:(NSString *)subtitle
{
    _subtitle = subtitle;
    self.itemView.subtitleLabel.text = subtitle;
    self.itemView.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", self.itemView.titleLabel.text, subtitle];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.itemView.imageView.image = image;
}

- (void)setImageBackgroundColor:(UIColor *)imageBackgroundColor
{
    _imageBackgroundColor = imageBackgroundColor;
    self.itemView.imageView.backgroundColor = imageBackgroundColor;
}

- (void)setHighlightedImage:(UIImage *)highlightedImage
{
    _highlightedImage = highlightedImage;
    self.itemView.imageView.highlightedImage = highlightedImage;
}

- (void)setNeedsLayout
{
    [self.itemView layoutSubviews];
}

@end
