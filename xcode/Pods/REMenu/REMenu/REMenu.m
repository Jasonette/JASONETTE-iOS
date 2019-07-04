//
// REMenu.m
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

#import "REMenu.h"
#import "REMenuItem.h"
#import "REMenuItemView.h"

@interface REMenuItem ()

@property (assign, readwrite, nonatomic) REMenuItemView *itemView;

@end

@interface REMenu ()

@property (strong, readwrite, nonatomic) UIView *menuView;
@property (strong, readwrite, nonatomic) UIView *menuWrapperView;
@property (strong, readwrite, nonatomic) REMenuContainerView *containerView;
@property (strong, readwrite, nonatomic) UIButton *backgroundButton;
@property (assign, readwrite, nonatomic) BOOL isOpen;
@property (assign, readwrite, nonatomic) BOOL isAnimating;
@property (strong, readwrite, nonatomic) NSMutableArray *itemViews;
@property (weak, readwrite, nonatomic) UINavigationBar *navigationBar;
@property (strong, readwrite, nonatomic) UIToolbar *toolbar;

@end

@implementation REMenu

- (id)init
{
    self = [super init];
    if (self) {
        _imageAlignment = REMenuImageAlignmentLeft;
        _closeOnSelection = YES;
        _itemHeight = 48.0;
        _separatorHeight = 2.0;
        _separatorOffset = CGSizeMake(0.0, 0.0);
        _waitUntilAnimationIsComplete = YES;
        
        _textOffset = CGSizeMake(0, 0);
        _subtitleTextOffset = CGSizeMake(0, 0);
        _font = [UIFont boldSystemFontOfSize:21.0];
        _subtitleFont = [UIFont systemFontOfSize:14.0];
        
        _backgroundAlpha = 1.0;
        _backgroundColor = [UIColor colorWithRed:53/255.0 green:53/255.0 blue:52/255.0 alpha:1.0];
        _separatorColor = [UIColor colorWithPatternImage:self.separatorImage];
        _textColor = [UIColor colorWithRed:128/255.0 green:126/255.0 blue:124/255.0 alpha:1.0];
        _textShadowColor = [UIColor blackColor];
        _textShadowOffset = CGSizeMake(0, -1.0);
        _textAlignment = NSTextAlignmentCenter;
        
        _highlightedBackgroundColor = [UIColor colorWithRed:28/255.0 green:28/255.0 blue:27/255.0 alpha:1.0];
        _highlightedSeparatorColor = [UIColor colorWithRed:28/255.0 green:28/255.0 blue:27/255.0 alpha:1.0];
        _highlightedTextColor = [UIColor colorWithRed:128/255.0 green:126/255.0 blue:124/255.0 alpha:1.0];
        _highlightedTextShadowColor = [UIColor blackColor];
        _highlightedTextShadowOffset = CGSizeMake(0, -1.0);
        
        _subtitleTextColor = [UIColor colorWithWhite:0.425 alpha:1.000];
        _subtitleTextShadowColor = [UIColor blackColor];
        _subtitleTextShadowOffset = CGSizeMake(0, -1.0);
        _subtitleHighlightedTextColor = [UIColor colorWithRed:0.389 green:0.384 blue:0.379 alpha:1.000];
        _subtitleHighlightedTextShadowColor = [UIColor blackColor];
        _subtitleHighlightedTextShadowOffset = CGSizeMake(0, -1.0);
        _subtitleTextAlignment = NSTextAlignmentCenter;
        
        _borderWidth = 1.0;
        _borderColor =  [UIColor colorWithRed:28/255.0 green:28/255.0 blue:27/255.0 alpha:1.0];
        _animationDuration = 0.3;
        _closeAnimationDuration = 0.2;
        _bounce = YES;
        _bounceAnimationDuration = 0.2;
        
        _appearsBehindNavigationBar = REUIKitIsFlatMode() ? YES : NO;
    }
    return self;
}

- (id)initWithItems:(NSArray *)items
{
    self = [self init];
    if (self) {
        _items = items;
    }
    return self;
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view
{
    if (self.isAnimating) {
        return;
    }
    
    self.isOpen = YES;
    self.isAnimating = YES;
    
    // Create views
    //
    self.containerView = ({
        REMenuContainerView *view = [[REMenuContainerView alloc] init];
        view.clipsToBounds = YES;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        if (self.backgroundView) {
            self.backgroundView.alpha = 0;
            [view addSubview:self.backgroundView];
        }
        view;
    });
    
    self.menuView = ({
        UIView *view = [[UIView alloc] init];
        if (!self.liveBlur || !REUIKitIsFlatMode()) {
            view.backgroundColor = self.backgroundColor;
        }
        view.layer.cornerRadius = self.cornerRadius;
        view.layer.borderColor = self.borderColor.CGColor;
        view.layer.borderWidth = self.borderWidth;
        view.layer.masksToBounds = YES;
        view.layer.shouldRasterize = YES;
        view.layer.rasterizationScale = [UIScreen mainScreen].scale;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        view;
    });
    
    if (REUIKitIsFlatMode()) {
        self.toolbar = ({
            UIToolbar *toolbar = [[UIToolbar alloc] init];
            toolbar.barStyle = (UIBarStyle)self.liveBlurBackgroundStyle;
            if ([toolbar respondsToSelector:@selector(setBarTintColor:)])
                [toolbar performSelector:@selector(setBarTintColor:) withObject:self.liveBlurTintColor];
            toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            toolbar.layer.cornerRadius = self.cornerRadius;
            toolbar.layer.borderColor = self.borderColor.CGColor;
            toolbar.layer.borderWidth = self.borderWidth;
            toolbar.layer.masksToBounds = YES;
            toolbar;
        });
    }
    
    self.menuWrapperView = ({
        UIView *view = [[UIView alloc] init];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        if (!self.liveBlur || !REUIKitIsFlatMode()) {
            view.layer.shadowColor = self.shadowColor.CGColor;
            view.layer.shadowOffset = self.shadowOffset;
            view.layer.shadowOpacity = self.shadowOpacity;
            view.layer.shadowRadius = self.shadowRadius;
            view.layer.shouldRasterize = YES;
            view.layer.rasterizationScale = [UIScreen mainScreen].scale;
        }
        view;
    });
    
    self.backgroundButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        button.accessibilityLabel = NSLocalizedString(@"Menu background", @"Menu background");
        button.accessibilityHint = NSLocalizedString(@"Double tap to close", @"Double tap to close");
        [button addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    
    CGFloat navigationBarOffset = self.appearsBehindNavigationBar && self.navigationBar ? 64 : 0;
    
    // Append new item views to REMenuView
    //
    for (REMenuItem *item in self.items) {
        NSInteger index = [self.items indexOfObject:item];
        
        CGFloat itemHeight = self.itemHeight;
        if (index == self.items.count - 1)
            itemHeight += self.cornerRadius;
        
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(self.separatorOffset.width,
                                                                         index * self.itemHeight + index * self.separatorHeight + 40.0 + navigationBarOffset + self.separatorOffset.height,
                                                                         rect.size.width - self.separatorOffset.width,
                                                                         self.separatorHeight)];
        separatorView.backgroundColor = self.separatorColor;
        separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.menuView addSubview:separatorView];
        
        REMenuItemView *itemView = [[REMenuItemView alloc] initWithFrame:CGRectMake(0,
                                                                                    index * self.itemHeight + (index + 1.0) * self.separatorHeight + 40.0 + navigationBarOffset,
                                                                                    rect.size.width,
                                                                                    itemHeight)
                                                                    menu:self item:item
                                                             hasSubtitle:item.subtitle.length > 0];
        itemView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        item.itemView = itemView;
        itemView.separatorView = separatorView;
        itemView.autoresizesSubviews = YES;
        if (item.customView) {
            item.customView.frame = itemView.bounds;
            [itemView addSubview:item.customView];
        }
        [self.menuView addSubview:itemView];
    }
    
    // Set up frames
    //
    self.menuWrapperView.frame = CGRectMake(0, -self.combinedHeight - navigationBarOffset, rect.size.width, self.combinedHeight + navigationBarOffset);
    self.menuView.frame = self.menuWrapperView.bounds;
    if (REUIKitIsFlatMode() && self.liveBlur) {
        self.toolbar.frame = self.menuWrapperView.bounds;
    }
    self.containerView.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    self.backgroundButton.frame = self.containerView.bounds;
    
    // Add subviews
    //
    if (REUIKitIsFlatMode() && self.liveBlur) {
        [self.menuWrapperView addSubview:self.toolbar];
    }
    [self.menuWrapperView addSubview:self.menuView];
    [self.containerView addSubview:self.backgroundButton];
    [self.containerView addSubview:self.menuWrapperView];
    [view addSubview:self.containerView];
    
    // Animate appearance
    //
    if (self.bounce) {
        self.isAnimating = YES;
        if ([UIView respondsToSelector:@selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)]) {
            [UIView animateWithDuration:self.animationDuration+self.bounceAnimationDuration
                                  delay:0.0
                 usingSpringWithDamping:0.6
                  initialSpringVelocity:4.0
                                options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                 self.backgroundView.alpha = self.backgroundAlpha;
                 CGRect frame = self.menuView.frame;
                 frame.origin.y = -40.0 - self.separatorHeight;
                 self.menuWrapperView.frame = frame;
             } completion:^(BOOL finished) {
                 self.isAnimating = NO;
             }];
        } else {
            [UIView animateWithDuration:self.animationDuration
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                 self.backgroundView.alpha = self.backgroundAlpha;
                 CGRect frame = self.menuView.frame;
                 frame.origin.y = -40.0 - self.separatorHeight;
                 self.menuWrapperView.frame = frame;
             } completion:^(BOOL finished) {
                 self.isAnimating = NO;
             }];

        }
    } else {
        [UIView animateWithDuration:self.animationDuration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.backgroundView.alpha = self.backgroundAlpha;
            CGRect frame = self.menuView.frame;
            frame.origin.y = -40.0 - self.separatorHeight;
            self.menuWrapperView.frame = frame;
        } completion:^(BOOL finished) {
            self.isAnimating = NO;
        }];
    }
}

- (void)showInView:(UIView *)view
{
    [self showFromRect:view.bounds inView:view];
}

- (void)showFromNavigationController:(UINavigationController *)navigationController
{
    if (self.isAnimating) {
        return;
    }
    
    self.navigationBar = navigationController.navigationBar;
    [self showFromRect:CGRectMake(0, 0, navigationController.navigationBar.frame.size.width, navigationController.view.frame.size.height) inView:navigationController.view];
    self.containerView.appearsBehindNavigationBar = self.appearsBehindNavigationBar;
    self.containerView.navigationBar = navigationController.navigationBar;
    if (self.appearsBehindNavigationBar) {
        [navigationController.view bringSubviewToFront:navigationController.navigationBar];
    }
}

- (void)closeWithCompletion:(void (^)(void))completion
{
    if (self.isAnimating) return;
    
    self.isAnimating = YES;
    
    CGFloat navigationBarOffset = self.appearsBehindNavigationBar && self.navigationBar ? 64 : 0;
    
    void (^closeMenu)(void) = ^{
        [UIView animateWithDuration:self.closeAnimationDuration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                         animations:^ {
            CGRect frame = self.menuView.frame;
            frame.origin.y = - self.combinedHeight - navigationBarOffset;
            self.menuWrapperView.frame = frame;
            self.backgroundView.alpha = 0;
        } completion:^(BOOL finished) {
            self.isOpen = NO;
            self.isAnimating = NO;
            
            [self.menuView removeFromSuperview];
            [self.menuWrapperView removeFromSuperview];
            [self.backgroundButton removeFromSuperview];
            [self.backgroundView removeFromSuperview];
            [self.containerView removeFromSuperview];
            
            if (completion) {
                completion();
            }
            
            if (self.closeCompletionHandler) {
                self.closeCompletionHandler();
            }
        }];
        
    };
    
    if (self.closePreparationBlock) {
        self.closePreparationBlock();
    }
    
    if (self.bounce) {
        [UIView animateWithDuration:self.bounceAnimationDuration animations:^{
            CGRect frame = self.menuView.frame;
            frame.origin.y = -20.0;
            self.menuWrapperView.frame = frame;
        } completion:^(BOOL finished) {
            closeMenu();
        }];
    } else {
        closeMenu();
    }
}

- (void)close
{
    [self closeWithCompletion:nil];
}

- (CGFloat)combinedHeight
{
    return self.items.count * self.itemHeight + self.items.count * self.separatorHeight + 40.0 + self.cornerRadius;
}

- (void)setNeedsLayout
{
    [UIView animateWithDuration:0.35 animations:^{
        [self.containerView layoutSubviews];
    }];
}

#pragma mark -
#pragma mark Setting style

- (UIImage *)separatorImage
{
    UIGraphicsBeginImageContext(CGSizeMake(1, 4.0));
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:28/255.0 green:28/255.0 blue:27/255.0 alpha:1.0].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 1.0, 2.0));
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:79/255.0 green:79/255.0 blue:77/255.0 alpha:1.0].CGColor);
    CGContextFillRect(context, CGRectMake(0, 3.0, 1.0, 2.0));
    UIGraphicsPopContext();
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:outputImage.CGImage scale:2.0 orientation:UIImageOrientationUp];
}

@end
