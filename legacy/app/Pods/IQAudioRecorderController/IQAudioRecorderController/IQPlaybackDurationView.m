//
//  IQPlaybackDurationView.m
// https://github.com/hackiftekhar/IQAudioRecorderController
// Created by Sebastian Ludwig
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


#import "IQPlaybackDurationView.h"
#import "NSString+IQTimeIntervalFormatter.h"

//IB_DESIGNABLE
@implementation IQPlaybackDurationView
{
    UISlider *_playerSlider;
    UILabel *_labelCurrentTime;
    UILabel *_labelRemainingTime;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

-(void)tintColorDidChange
{
    [super tintColorDidChange];
    
    _labelCurrentTime.textColor = self.tintColor;
    _labelRemainingTime.textColor = self.tintColor;
    _playerSlider.minimumTrackTintColor = self.tintColor;
}

- (void)setup
{
    //Current Time
    {
        _labelCurrentTime = [[UILabel alloc] init];

        {
            _labelCurrentTime.translatesAutoresizingMaskIntoConstraints = NO;
            [_labelCurrentTime setContentHuggingPriority:UILayoutPriorityDefaultLow+1 forAxis:UILayoutConstraintAxisHorizontal];
            [_labelCurrentTime setContentHuggingPriority:UILayoutPriorityDefaultLow+1 forAxis:UILayoutConstraintAxisVertical];
        }
        
        _labelCurrentTime.textColor = self.tintColor;
        _labelCurrentTime.text = [NSString timeStringForTimeInterval:0];
        _labelCurrentTime.font = [UIFont boldSystemFontOfSize:14.0];
        [self addSubview:_labelCurrentTime];
    }
    
    //Player Slider
    {
        _playerSlider = [[UISlider alloc] init];
        
        {
            _playerSlider.translatesAutoresizingMaskIntoConstraints = NO;
            [_playerSlider setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            [_playerSlider setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        }

        _playerSlider.minimumTrackTintColor = self.tintColor;
        _playerSlider.value = 0;
        [_playerSlider addTarget:self action:@selector(sliderStart) forControlEvents:UIControlEventTouchDown];
        [_playerSlider addTarget:self action:@selector(sliderMoved) forControlEvents:UIControlEventValueChanged];
        [_playerSlider addTarget:self action:@selector(sliderEnd) forControlEvents:UIControlEventTouchUpInside];
        [_playerSlider addTarget:self action:@selector(sliderEnd) forControlEvents:UIControlEventTouchUpOutside];
        [_playerSlider addTarget:self action:@selector(sliderEnd) forControlEvents:UIControlEventTouchCancel];
        [self addSubview:_playerSlider];
    }
    
    //Remaining Time
    {
        _labelRemainingTime = [[UILabel alloc] init];
        
        {
            _labelRemainingTime.translatesAutoresizingMaskIntoConstraints = NO;
            [_labelRemainingTime setContentHuggingPriority:UILayoutPriorityDefaultLow+1 forAxis:UILayoutConstraintAxisHorizontal];
            [_labelRemainingTime setContentHuggingPriority:UILayoutPriorityDefaultLow+1 forAxis:UILayoutConstraintAxisVertical];
        }

        _labelRemainingTime.textColor = self.tintColor;
        _labelRemainingTime.text = [NSString timeStringForTimeInterval:0];
        _labelRemainingTime.userInteractionEnabled = YES;
        [_labelRemainingTime addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleRemainingTimeDisplay:)]];
        _labelRemainingTime.font = _labelCurrentTime.font;
        [self addSubview:_labelRemainingTime];
    }

    //Constraint
    {
        NSDictionary *views = @{@"currentTime": _labelCurrentTime,
                                @"slider": _playerSlider,
                                @"remainingTime": _labelRemainingTime};
        
        NSArray *constraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[currentTime]-[slider]-[remainingTime]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views];
        [self addConstraints:constraints1];
        
        NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[slider]|" options:0 metrics:nil views:views];
        [self addConstraints:constraints2];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_playerSlider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    }
}

- (void)prepareForInterfaceBuilder
{
    self.duration = 60;
    self.currentTime = 17;
    [self updateRemainingTimeLabel];
}

- (void)setShowRemainingTime:(BOOL)showRemainingTime
{
    _showRemainingTime = showRemainingTime;
    
    [self updateRemainingTimeLabel];
}

- (void)setDuration:(NSTimeInterval)duration
{
    _duration = duration;
    _playerSlider.maximumValue = duration;
    
    [self updateRemainingTimeLabel];
}

-(void)setCurrentTime:(NSTimeInterval)currentTime
{
    [self setCurrentTime:currentTime animated:NO];
}

- (void)setCurrentTime:(NSTimeInterval)currentTime animated:(BOOL)animated
{
    _currentTime = currentTime;
    [_playerSlider setValue:currentTime animated:animated];
    _labelCurrentTime.text = [NSString timeStringForTimeInterval:currentTime];
    
    [self updateRemainingTimeLabel];
}

#pragma mark Private methods

- (void)updateRemainingTimeLabel
{
    if (self.showRemainingTime)
    {
        _labelRemainingTime.text = [NSString timeStringForTimeInterval:(self.duration-self.currentTime)];
    }
    else
    {
        _labelRemainingTime.text = [NSString timeStringForTimeInterval:self.duration];
    }
}

- (void)toggleRemainingTimeDisplay:(UITapGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        self.showRemainingTime = !self.showRemainingTime;
    }
}

-(void)sliderStart
{
    if ([self.delegate respondsToSelector:@selector(playbackDurationView:didStartScrubbingAtTime:)])
    {
        [self.delegate playbackDurationView:self didStartScrubbingAtTime:_playerSlider.value];
    }
}

-(void)sliderMoved
{
    if ([self.delegate respondsToSelector:@selector(playbackDurationView:didScrubToTime:)])
    {
        [self.delegate playbackDurationView:self didScrubToTime:_playerSlider.value];
    }
}

-(void)sliderEnd
{
    if ([self.delegate respondsToSelector:@selector(playbackDurationView:didEndScrubbingAtTime:)])
    {
        [self.delegate playbackDurationView:self didEndScrubbingAtTime:_playerSlider.value];
    }
}

@end
