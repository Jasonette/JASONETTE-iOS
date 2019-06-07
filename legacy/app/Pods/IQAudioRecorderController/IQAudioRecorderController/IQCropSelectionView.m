//
//  IQCropSelectionView.m
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

#import "IQCropSelectionView.h"
#import "NSString+IQTimeIntervalFormatter.h"

@implementation IQCropSelectionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, CGRectGetHeight(self.bounds))];
        lineView.backgroundColor = [UIColor redColor];
        [self addSubview:lineView];
        
        smallLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds)/2, CGRectGetWidth(lineView.frame))];
        smallLineView.backgroundColor = [UIColor redColor];
        [self addSubview:smallLineView];
        
        timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds)-20, CGRectGetWidth(self.bounds), 20)];
        timeLabel.textColor = [UIColor redColor];
        timeLabel.minimumScaleFactor = 0.5;
        timeLabel.adjustsFontSizeToFitWidth = YES;
        timeLabel.textAlignment = NSTextAlignmentCenter;
        timeLabel.font = [UIFont boldSystemFontOfSize:12];
        [self addSubview:timeLabel];
        self.clipsToBounds = NO;
    }
    return self;
}

-(void)setCropTime:(NSTimeInterval)cropTime
{
    _cropTime = cropTime;
    
    timeLabel.text = [NSString timeStringForTimeInterval:cropTime];
}

@end
