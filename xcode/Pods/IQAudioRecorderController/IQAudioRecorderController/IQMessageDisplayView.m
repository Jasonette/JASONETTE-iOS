//
// IQMessageDisplayView.m
// https://github.com/hackiftekhar/IQAudioRecorderController
// Created by Iftekhar Qurashi
// Copyright (c) 2015-16 Iftekhar Qurashi
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


#import "IQMessageDisplayView.h"

//IB_DESIGNABLE
@implementation IQMessageDisplayView
{
    UIImageView *imageView;
    UILabel *labelTitle;
    UILabel *labelMessage;
    UIButton *buttonAction;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    imageView = [[UIImageView alloc] init];
    imageView.tintColor = [UIColor lightGrayColor];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:imageView];
    
    labelTitle = [[UILabel alloc] init];
    labelTitle.translatesAutoresizingMaskIntoConstraints = NO;
    labelTitle.font = [UIFont boldSystemFontOfSize:20.0];
    labelTitle.textColor = [UIColor lightGrayColor];
    labelTitle.numberOfLines = 0;
    labelTitle.textAlignment = NSTextAlignmentCenter;
    [self addSubview:labelTitle];
    
    labelMessage = [[UILabel alloc] init];
    labelMessage.translatesAutoresizingMaskIntoConstraints = NO;
    labelMessage.font = [UIFont systemFontOfSize:13.0];
    labelMessage.textColor = [UIColor lightGrayColor];
    labelMessage.numberOfLines = 0;
    labelMessage.textAlignment = NSTextAlignmentCenter;
    [self addSubview:labelMessage];
    
    buttonAction = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonAction.enabled = NO;
    buttonAction.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonAction addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    buttonAction.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [self addSubview:buttonAction];
    
    //Constraint
    {
        NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        
        NSLayoutConstraint *constraint2 = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];

        NSLayoutConstraint *constraint3 = [NSLayoutConstraint constraintWithItem:labelTitle attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeBottom multiplier:1 constant:5];
        
        NSLayoutConstraint *constraint4 = [NSLayoutConstraint constraintWithItem:labelTitle attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
        
        NSLayoutConstraint *constraint5 = [NSLayoutConstraint constraintWithItem:labelTitle attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];

        NSLayoutConstraint *constraint6 = [NSLayoutConstraint constraintWithItem:labelMessage attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:labelTitle attribute:NSLayoutAttributeBottom multiplier:1 constant:5];
        
        NSLayoutConstraint *constraint7 = [NSLayoutConstraint constraintWithItem:labelMessage attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
        
        NSLayoutConstraint *constraint8 = [NSLayoutConstraint constraintWithItem:labelMessage attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
        
        NSLayoutConstraint *constraint9 = [NSLayoutConstraint constraintWithItem:buttonAction attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:labelMessage attribute:NSLayoutAttributeBottom multiplier:1 constant:15];
        
        NSLayoutConstraint *constraint10 = [NSLayoutConstraint constraintWithItem:buttonAction attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        
        NSLayoutConstraint *constraint11 = [NSLayoutConstraint constraintWithItem:buttonAction attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        
        [self addConstraints:@[constraint1,constraint2,constraint3,constraint4,constraint5,constraint6,constraint7,constraint8,constraint9,constraint10,constraint11]];
    }
}

-(void)setImage:(UIImage *)image
{
    _image = image;
    imageView.image = image;
}

-(void)setTitle:(NSString *)title
{
    _title = title;
    labelTitle.text = title;
}

-(void)setMessage:(NSString *)message
{
    _message = message;
    labelMessage.text = message;
}

-(void)setButtonTitle:(NSString *)buttonTitle
{
    _buttonTitle = buttonTitle;
    [buttonAction setTitle:buttonTitle forState:UIControlStateNormal];
    buttonAction.enabled = buttonTitle.length;
}

- (void)prepareForInterfaceBuilder
{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];

    self.image = [UIImage imageNamed:@"microphone_access" inBundle:bundle compatibleWithTraitCollection:nil];
    self.title = @"Access Denied!";
    self.message = @"We are unable to access microphone due to privacy restrictions. Please enable access for microphone in Settings->Privacy Settings->Microphone";
    self.buttonTitle = @"Go to Settings";
}

-(void)buttonAction:(UIButton*)button
{
    if ([self.delegate respondsToSelector:@selector(messageDisplayViewDidTapOnButton:)])
    {
        [self.delegate messageDisplayViewDidTapOnButton:self];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
