//
// IQAudioRecorderController.m
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


#import <CoreMedia/CMTime.h>

#import "IQAudioRecorderViewController.h"
#import "NSString+IQTimeIntervalFormatter.h"
#import "IQPlaybackDurationView.h"
#import "IQMessageDisplayView.h"
#import "SCSiriWaveformView.h"
#import "IQAudioCropperViewController.h"

/************************************/

@interface IQAudioRecorderViewController() <AVAudioRecorderDelegate,AVAudioPlayerDelegate,IQPlaybackDurationViewDelegate,IQMessageDisplayViewDelegate,IQAudioCropperViewControllerDelegate>
{
    BOOL _isFirstTime;
    
    //Recording...
    CADisplayLink *meterUpdateDisplayLink;
    
    //Playing
    AVAudioPlayer *_audioPlayer;
    BOOL _wasPlaying;
    CADisplayLink *playProgressDisplayLink;

    //Recording controls
    BOOL _isRecordingPaused;
    
    //Private variables
    NSString *_oldSessionCategory;
    BOOL _wasIdleTimerDisabled;
}

//BlurrView
@property UIVisualEffectView *visualEffectView;

//Playing
@property IQPlaybackDurationView *viewPlayerDuration;

//Recording...
@property AVAudioRecorder *audioRecorder;
@property SCSiriWaveformView *musicFlowView;
@property NSString *recordingFilePath;

//Access
@property IQMessageDisplayView *viewMicrophoneDenied;

//Navigation Bar
@property NSString *navigationTitle;
@property UIBarButtonItem *cancelButton, *doneButton;

//Playing controls
@property UIBarButtonItem *playButton, *pauseButton, *stopPlayButton, *flexItem;

//Recording controls
@property UIBarButtonItem *cancelRecordingButton, *startRecordingButton, *continueRecordingButton, *pauseRecordingButton, *stopRecordingButton;

//Crop/Delete controls
@property UIBarButtonItem *cropOrDeleteButton;

@property(nonatomic, assign) BOOL blurrEnabled;

@end

@implementation IQAudioRecorderViewController

@dynamic title;

#pragma mark - Private Helper

-(void)setNormalTintColor:(UIColor *)normalTintColor
{
    _normalTintColor = normalTintColor;

    _playButton.tintColor = [self _normalTintColor];
    _pauseButton.tintColor = [self _normalTintColor];
    _stopPlayButton.tintColor = [self _normalTintColor];
    _startRecordingButton.tintColor = [self _normalTintColor];
    _cropOrDeleteButton.tintColor = [self _normalTintColor];
}

-(UIColor*)_normalTintColor
{
    if (_normalTintColor)
    {
        return _normalTintColor;
    }
    else
    {
        if (self.barStyle == UIBarStyleDefault)
        {
            return [UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:1.0];
        }
        else
        {
            return [UIColor whiteColor];
        }
    }
}

-(void)setHighlightedTintColor:(UIColor *)highlightedTintColor
{
    _highlightedTintColor = highlightedTintColor;
    _viewPlayerDuration.tintColor = [self _highlightedTintColor];
    _cancelRecordingButton.tintColor = [self _highlightedTintColor];
}

-(UIColor *)_highlightedTintColor
{
    if (_highlightedTintColor)
    {
        return _highlightedTintColor;
    }
    else
    {
        if (self.barStyle == UIBarStyleDefault)
        {
            return [UIColor colorWithRed:255.0/255.0 green:64.0/255.0 blue:64.0/255.0 alpha:1.0];
        }
        else
        {
            return [UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:1.0];
        }
    }
}

#pragma mark - View Lifecycle

-(void)loadView
{
    _visualEffectView = [[UIVisualEffectView alloc] initWithEffect:nil];
    _visualEffectView.frame = [UIScreen mainScreen].bounds;
    
    self.view = _visualEffectView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _isFirstTime = YES;
    
    if (self.title.length == 0)
    {
        _navigationTitle = NSLocalizedString(@"Audio Recorder",nil);
    }
    else
    {
        _navigationTitle = self.title;
    }

    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    if (bundle == nil)  bundle = [NSBundle mainBundle];
    NSBundle *resourcesBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"IQAudioRecorderController" ofType:@"bundle"]];
    if (resourcesBundle == nil) resourcesBundle = bundle;

    {
        _viewMicrophoneDenied = [[IQMessageDisplayView alloc] initWithFrame:_visualEffectView.contentView.bounds];
        _viewMicrophoneDenied.delegate = self;
        _viewMicrophoneDenied.alpha = 0.0;
        
        if (self.barStyle == UIBarStyleDefault)
        {
            _viewMicrophoneDenied.tintColor = [UIColor darkGrayColor];
        }
        else
        {
            _viewMicrophoneDenied.tintColor = [UIColor whiteColor];
        }
        
        _viewMicrophoneDenied.image = [[UIImage imageNamed:@"microphone_access" inBundle:resourcesBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _viewMicrophoneDenied.title = NSLocalizedString(@"Microphone Access Denied!",nil);
        _viewMicrophoneDenied.message = NSLocalizedString(@"Unable to access microphone. Please enable microphone access in Settings.",nil);
        _viewMicrophoneDenied.buttonTitle = NSLocalizedString(@"Go to Settings",nil);
        [_visualEffectView.contentView addSubview:_viewMicrophoneDenied];
        
    }
    
    {
        _musicFlowView = [[SCSiriWaveformView alloc] initWithFrame:_visualEffectView.contentView.bounds];
        _musicFlowView.alpha = 0.0;
        _musicFlowView.backgroundColor = [UIColor clearColor];
        [_visualEffectView.contentView addSubview:_musicFlowView];
    }
    
    {
        _viewMicrophoneDenied.translatesAutoresizingMaskIntoConstraints = NO;
        _musicFlowView.translatesAutoresizingMaskIntoConstraints = NO;

        NSDictionary *views = @{@"viewMicrophoneDenied":_viewMicrophoneDenied,@"musicFlowView":_musicFlowView};
        
        NSMutableArray<NSLayoutConstraint*> *constraints = [[NSMutableArray alloc] init];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[musicFlowView]-|" options:0 metrics:nil views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[viewMicrophoneDenied]-|" options:0 metrics:nil views:views]];

        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[musicFlowView]-|" options:0 metrics:nil views:views]];

        [constraints addObject:[NSLayoutConstraint constraintWithItem:_viewMicrophoneDenied attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_visualEffectView.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

        [_visualEffectView.contentView addConstraints:constraints];
    }

    {
        _flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        //Recording controls
        _startRecordingButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"audio_record" inBundle:resourcesBundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(recordingButtonAction:)];
        _startRecordingButton.tintColor = [self _normalTintColor];
        _pauseRecordingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pauseRecordingButtonAction:)];
        _pauseRecordingButton.tintColor = [UIColor redColor];
        _continueRecordingButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"audio_record" inBundle:resourcesBundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(continueRecordingButtonAction:)];
        _continueRecordingButton.tintColor = [UIColor redColor];
        _stopRecordingButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"stop_recording" inBundle:resourcesBundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(stopRecordingButtonAction:)];
        
        _stopRecordingButton.tintColor = [UIColor redColor];
        _cancelRecordingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelRecordingAction:)];
        _cancelRecordingButton.tintColor = [self _highlightedTintColor];
        
        //Playing controls
        _stopPlayButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"stop_playing" inBundle:resourcesBundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(stopPlayingButtonAction:)];
        _stopPlayButton.tintColor = [self _normalTintColor];
        _playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
        _playButton.tintColor = [self _normalTintColor];

        _pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pausePlayingAction:)];
        _pauseButton.tintColor = [self _normalTintColor];

        //crop/delete control
        
        if (self.allowCropping)
        {
            _cropOrDeleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"scissor" inBundle:resourcesBundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(cropAction:)];
        }
        else
        {
            _cropOrDeleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
        }
        
        _cropOrDeleteButton.tintColor = [self _normalTintColor];
        
        [self setToolbarItems:@[_playButton,_flexItem, _startRecordingButton,_flexItem, _cropOrDeleteButton] animated:NO];

        _playButton.enabled = NO;
        _cropOrDeleteButton.enabled = NO;
    }
    
    // Define the recorder setting
    {
        NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];

        NSString *globallyUniqueString = [NSProcessInfo processInfo].globallyUniqueString;

        if (self.audioFormat == IQAudioFormatDefault || self.audioFormat == IQAudioFormat_m4a)
        {
            _recordingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",globallyUniqueString]];

            recordSettings[AVFormatIDKey] = @(kAudioFormatMPEG4AAC);
        }
        else if (self.audioFormat == IQAudioFormat_caf)
        {
            _recordingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf",globallyUniqueString]];

            recordSettings[AVFormatIDKey] = @(kAudioFormatAppleLossless);
        }
        
        if (self.sampleRate > 0.0f)
        {
            recordSettings[AVSampleRateKey] = @(self.sampleRate);
        }
        else
        {
            recordSettings[AVSampleRateKey] = @44100.0f;
        }
        
        if (self.numberOfChannels >0)
        {
            recordSettings[AVNumberOfChannelsKey] = @(self.numberOfChannels);
        }
        else
        {
            recordSettings[AVNumberOfChannelsKey] = @1;
        }

        if (self.audioQuality != IQAudioQualityDefault)
        {
            recordSettings[AVEncoderAudioQualityKey] = @(self.audioQuality);
        }

        if (self.bitRate > 0)
        {
            recordSettings[AVEncoderBitRateKey] = @(self.bitRate);
        }
        
        // Initiate and prepare the recorder
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_recordingFilePath] settings:recordSettings error:nil];
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES;
        
        _musicFlowView.primaryWaveLineWidth = 3.0f;
        _musicFlowView.secondaryWaveLineWidth = 1.0;
    }

    //Navigation Bar Settings
    {
        if (self.title.length == 0 && self.navigationItem.title.length == 0)
        {
            self.navigationItem.title = NSLocalizedString(@"Audio Recorder",nil);
        }

        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.leftBarButtonItem = _cancelButton;
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        _doneButton.enabled = NO;
        self.navigationItem.rightBarButtonItem = _doneButton;
    }
    
    //Player Duration View
    {
        _viewPlayerDuration = [[IQPlaybackDurationView alloc] initWithFrame:self.navigationController.navigationBar.bounds];
        _viewPlayerDuration.delegate = self;
        _viewPlayerDuration.tintColor = [self _highlightedTintColor];
        _viewPlayerDuration.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _viewPlayerDuration.backgroundColor = [UIColor clearColor];
    }
}

-(void)setBarStyle:(UIBarStyle)barStyle
{
    _barStyle = barStyle;
    
    if (self.barStyle == UIBarStyleDefault)
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.tintColor = [self _normalTintColor];
        self.navigationController.toolbar.tintColor = [self _normalTintColor];
    }
    else
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    }

    _viewMicrophoneDenied.tintColor = [self _normalTintColor];
    _visualEffectView.tintColor = [self _normalTintColor];
    self.highlightedTintColor = self.highlightedTintColor;
    self.normalTintColor = self.normalTintColor;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startUpdatingMeter];
    
    _wasIdleTimerDisabled = [[UIApplication sharedApplication] isIdleTimerDisabled];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self validateMicrophoneAccess];
    
    if (_isFirstTime)
    {
        _isFirstTime = NO;

        if (self.blurrEnabled)
        {
            __weak typeof(self) weakSelf = self;

            [UIView animateWithDuration:0.3 animations:^{
                if (weakSelf.barStyle == UIBarStyleDefault)
                {
                    weakSelf.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
                }
                else
                {
                    weakSelf.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                }
            }];
        }
        else
        {
            if (self.barStyle == UIBarStyleDefault)
            {
                _visualEffectView.backgroundColor = [UIColor whiteColor];
            }
            else
            {
                _visualEffectView.backgroundColor = [UIColor darkGrayColor];
            }
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    _audioPlayer.delegate = nil;
    [_audioPlayer stop];
    _audioPlayer = nil;
    
    _audioRecorder.delegate = nil;
    [_audioRecorder stop];
    _audioRecorder = nil;
    
    [self stopUpdatingMeter];
    
    [UIApplication sharedApplication].idleTimerDisabled = _wasIdleTimerDisabled;
}

#pragma mark - Update Meters

- (void)updateMeters
{
    if (_audioRecorder.isRecording || _isRecordingPaused)
    {
        [_audioRecorder updateMeters];
        
        CGFloat normalizedValue = pow (10, [_audioRecorder averagePowerForChannel:0] / 20);
        
        _musicFlowView.waveColor = [self _highlightedTintColor];
        [_musicFlowView updateWithLevel:normalizedValue];
        
        self.navigationItem.title = [NSString timeStringForTimeInterval:_audioRecorder.currentTime];
    }
    else if (_audioPlayer)
    {
        if (_audioPlayer.isPlaying)
        {
            [_audioPlayer updateMeters];
            CGFloat normalizedValue = pow (10, [_audioPlayer averagePowerForChannel:0] / 20);
            [_musicFlowView updateWithLevel:normalizedValue];
        }

        _musicFlowView.waveColor = [self _highlightedTintColor];
    }
    else
    {
        _musicFlowView.waveColor = [self _normalTintColor];
        [_musicFlowView updateWithLevel:0];
    }
}

-(void)startUpdatingMeter
{
    [meterUpdateDisplayLink invalidate];
    meterUpdateDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [meterUpdateDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)stopUpdatingMeter
{
    [meterUpdateDisplayLink invalidate];
    meterUpdateDisplayLink = nil;
}

#pragma mark - Audio Play

-(void)updatePlayProgress
{
    [_viewPlayerDuration setCurrentTime:_audioPlayer.currentTime animated:YES];
}

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didStartScrubbingAtTime:(NSTimeInterval)time
{
    _wasPlaying = _audioPlayer.isPlaying;
    
    if (_audioPlayer.isPlaying)
    {
        [_audioPlayer pause];
    }
}
- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didScrubToTime:(NSTimeInterval)time
{
    _audioPlayer.currentTime = time;
}

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didEndScrubbingAtTime:(NSTimeInterval)time
{
    if (_wasPlaying)
    {
        [_audioPlayer play];
    }
}

- (void)playAction:(UIBarButtonItem *)item
{
    _oldSessionCategory = [AVAudioSession sharedInstance].category;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    if (_audioPlayer == nil)
    {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:_recordingFilePath] error:nil];
        _audioPlayer.delegate = self;
        _audioPlayer.meteringEnabled = YES;
    }
    
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
    
    //UI Update
    {
        [self setToolbarItems:@[_pauseButton,_flexItem, _stopPlayButton,_flexItem, _cropOrDeleteButton] animated:YES];
        [self showNavigationButton:NO];
        _cropOrDeleteButton.enabled = NO;
    }
    
    //Start regular update
    {
        _viewPlayerDuration.duration = _audioPlayer.duration;
        _viewPlayerDuration.currentTime = _audioPlayer.currentTime;
        
        self.navigationItem.titleView = _viewPlayerDuration;

        _viewPlayerDuration.translatesAutoresizingMaskIntoConstraints = YES;
        _viewPlayerDuration.frame = self.navigationController.navigationBar.bounds;
        [_viewPlayerDuration setNeedsLayout];
        [_viewPlayerDuration layoutIfNeeded];

        _viewPlayerDuration.alpha = 0.0;
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            weakSelf.viewPlayerDuration.alpha = 1.0;
        } completion:^(BOOL finished) {
        }];
        
        [playProgressDisplayLink invalidate];
        playProgressDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updatePlayProgress)];
        [playProgressDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

-(void)pausePlayingAction:(UIBarButtonItem*)item
{
    //UI Update
    {
        [self setToolbarItems:@[_playButton,_flexItem, _stopPlayButton,_flexItem, _cropOrDeleteButton] animated:YES];
    }
    
    [_audioPlayer pause];
    
    [[AVAudioSession sharedInstance] setCategory:_oldSessionCategory error:nil];
    [UIApplication sharedApplication].idleTimerDisabled = _wasIdleTimerDisabled;
}

-(void)stopPlayingButtonAction:(UIBarButtonItem*)item
{
    //UI Update
    {
        [self setToolbarItems:@[_playButton,_flexItem, _startRecordingButton,_flexItem, _cropOrDeleteButton] animated:YES];
        _cropOrDeleteButton.enabled = YES;
    }
    
    {
        [playProgressDisplayLink invalidate];
        playProgressDisplayLink = nil;
        
        __weak typeof(self) weakSelf = self;

        [UIView animateWithDuration:0.1 animations:^{
            weakSelf.viewPlayerDuration.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.navigationItem.titleView = nil;
            [self showNavigationButton:YES];
        }];
    }
    
    _audioPlayer.delegate = nil;
    [_audioPlayer stop];
    _audioPlayer = nil;
    
    [[AVAudioSession sharedInstance] setCategory:_oldSessionCategory error:nil];
    [UIApplication sharedApplication].idleTimerDisabled = _wasIdleTimerDisabled;
}

#pragma mark - AVAudioPlayerDelegate
/*
 Occurs when the audio player instance completes playback
 */
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //To update UI on stop playing
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_stopPlayButton.target methodSignatureForSelector:_stopPlayButton.action]];
    invocation.target = _stopPlayButton.target;
    invocation.selector = _stopPlayButton.action;
    [invocation invoke];
}

#pragma mark - Audio Record

- (void)recordingButtonAction:(UIBarButtonItem *)item
{
    //UI Update
    {
        [self setToolbarItems:@[_stopRecordingButton,_flexItem, _pauseRecordingButton,_flexItem, _cropOrDeleteButton] animated:YES];
        _cropOrDeleteButton.enabled = NO;
        [self.navigationItem setLeftBarButtonItem:_cancelRecordingButton animated:YES];
        _doneButton.enabled = NO;
    }
    
    /*
     Create the recorder
     */
    if ([[NSFileManager defaultManager] fileExistsAtPath:_recordingFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:_recordingFilePath error:nil];
    }
    
    _oldSessionCategory = [AVAudioSession sharedInstance].category;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [_audioRecorder prepareToRecord];
    
    _isRecordingPaused = YES;
    
    if (self.maximumRecordDuration <=0)
    {
        [_audioRecorder record];
    }
    else
    {
        [_audioRecorder recordForDuration:self.maximumRecordDuration];
    }
}

- (void)continueRecordingButtonAction:(UIBarButtonItem *)item
{
    //UI Update
    {
        [self setToolbarItems:@[_stopRecordingButton,_flexItem, _pauseRecordingButton,_flexItem, _cropOrDeleteButton] animated:YES];
    }

    _isRecordingPaused = NO;
    [_audioRecorder record];
}

-(void)pauseRecordingButtonAction:(UIBarButtonItem*)item
{
    _isRecordingPaused = YES;
    [_audioRecorder pause];
    [self setToolbarItems:@[_stopRecordingButton,_flexItem, _continueRecordingButton,_flexItem, _cropOrDeleteButton] animated:YES];
}

-(void)stopRecordingButtonAction:(UIBarButtonItem*)item
{
    _isRecordingPaused = NO;
    [_audioRecorder stop];
}

-(void)cancelRecordingAction:(UIBarButtonItem*)item
{
    _isRecordingPaused = NO;
    [_audioRecorder stop];
    
    [[NSFileManager defaultManager] removeItemAtPath:_recordingFilePath error:nil];
    self.navigationItem.title = [NSString timeStringForTimeInterval:_audioRecorder.currentTime];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (flag)
    {
        //UI Update
        {
            [self setToolbarItems:@[_playButton,_flexItem, _startRecordingButton,_flexItem, _cropOrDeleteButton] animated:YES];
            [self.navigationItem setLeftBarButtonItem:_cancelButton animated:YES];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:_recordingFilePath])
            {
                _playButton.enabled = YES;
                _cropOrDeleteButton.enabled = YES;
                _doneButton.enabled = YES;
            }
            else
            {
                _playButton.enabled = NO;
                _cropOrDeleteButton.enabled = NO;
                _doneButton.enabled = NO;
            }
        }

        [[AVAudioSession sharedInstance] setCategory:_oldSessionCategory error:nil];
        [UIApplication sharedApplication].idleTimerDisabled = _wasIdleTimerDisabled;
    }
    else
    {
        [[NSFileManager defaultManager] removeItemAtPath:_recordingFilePath error:nil];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    //    NSLog(@"%@: %@",NSStringFromSelector(_cmd),error);
}


#pragma mark - Cancel or Done

-(void)cancelAction:(UIBarButtonItem*)item
{
    [self notifyCancelDelegate];
}

-(void)doneAction:(UIBarButtonItem*)item
{
    [self notifySuccessDelegate];
}

-(void)notifyCancelDelegate
{
    __weak typeof(self) weakSelf = self;

    void (^notifyDelegateBlock)(void) = ^{
        if ([self.delegate respondsToSelector:@selector(audioRecorderControllerDidCancel:)])
        {
            [self.delegate audioRecorderControllerDidCancel:self];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    };
    
    if (self.blurrEnabled)
    {
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.visualEffectView.effect = nil;
            weakSelf.musicFlowView.alpha = 0;
        } completion:^(BOOL finished) {
            notifyDelegateBlock();
        }];
    }
    else
    {
        notifyDelegateBlock();
    }
}

-(void)notifySuccessDelegate
{
    __weak typeof(self) weakSelf = self;

    void (^notifyDelegateBlock)(void) = ^{
        if ([weakSelf.delegate respondsToSelector:@selector(audioRecorderController:didFinishWithAudioAtPath:)])
        {
            [weakSelf.delegate audioRecorderController:weakSelf didFinishWithAudioAtPath:weakSelf.recordingFilePath];
        }
        else
        {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }
    };
    
    if (self.blurrEnabled)
    {
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.visualEffectView.effect = nil;
            weakSelf.musicFlowView.alpha = 0;
        } completion:^(BOOL finished) {
            notifyDelegateBlock();
        }];
    }
    else
    {
        notifyDelegateBlock();
    }
}

#pragma mark - Crop Audio

-(void)cropAction:(UIBarButtonItem*)item
{
    IQAudioCropperViewController *controller = [[IQAudioCropperViewController alloc] initWithFilePath:_recordingFilePath];
    controller.delegate = self;
    controller.barStyle = self.barStyle;
    controller.normalTintColor = self.normalTintColor;
    controller.highlightedTintColor = self.highlightedTintColor;
    
    if (self.blurrEnabled)
    {
        [self presentBlurredAudioCropperViewControllerAnimated:controller];
    }
    else
    {
        [self presentAudioCropperViewControllerAnimated:controller];
    }
    
    [self stopUpdatingMeter];
}

-(void)audioCropperController:(IQAudioCropperViewController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    _recordingFilePath = filePath;
    NSURL *audioFileURL = [NSURL fileURLWithPath:_recordingFilePath];
    
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:audioFileURL options:nil];
    CMTime audioDuration = audioAsset.duration;
    self.navigationItem.title = [NSString timeStringForTimeInterval:CMTimeGetSeconds(audioDuration)];
    
    [controller dismissViewControllerAnimated:YES completion:nil];

    [self startUpdatingMeter];
}

-(void)audioCropperControllerDidCancel:(IQAudioCropperViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];

    [self startUpdatingMeter];
}

#pragma mark - Delete Audio

-(void)deleteAction:(UIBarButtonItem*)item
{
    __weak typeof(self) weakSelf = self;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete Recording",nil)
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *action){

                                                        [[NSFileManager defaultManager] removeItemAtPath:weakSelf.recordingFilePath error:nil];
                                                        
                                                        weakSelf.playButton.enabled = NO;
                                                        weakSelf.cropOrDeleteButton.enabled = NO;
                                                        weakSelf.doneButton.enabled = NO;
                                                        weakSelf.navigationItem.title = weakSelf.navigationTitle;
                                                    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    alertController.popoverPresentationController.barButtonItem = item;
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Message Display View

-(void)messageDisplayViewDidTapOnButton:(IQMessageDisplayView *)displayView
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

#pragma mark - Private helper

-(void)updateUI
{

}

-(void)showNavigationButton:(BOOL)show
{
    if (show)
    {
        [self.navigationItem setLeftBarButtonItem:_cancelButton animated:YES];
        [self.navigationItem setRightBarButtonItem:_doneButton animated:YES];
    }
    else
    {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
}

- (void)validateMicrophoneAccess
{
    __weak typeof(self) weakSelf = self;

    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session requestRecordPermission:^(BOOL granted) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            weakSelf.viewMicrophoneDenied.alpha = !granted;
            weakSelf.musicFlowView.alpha = granted;
            weakSelf.startRecordingButton.enabled = granted;
        });
    }];
}

-(void)didBecomeActiveNotification:(NSNotification*)notification
{
    [self validateMicrophoneAccess];
}


@end


@implementation UIViewController (IQAudioRecorderViewController)

- (void)presentAudioRecorderViewControllerAnimated:(nonnull IQAudioRecorderViewController *)audioRecorderViewController
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:audioRecorderViewController];

    navigationController.toolbarHidden = NO;
    navigationController.toolbar.translucent = YES;
    
    navigationController.navigationBar.translucent = YES;

    audioRecorderViewController.barStyle = audioRecorderViewController.barStyle;        //This line is used to refresh UI of Audio Recorder View Controller
    [self presentViewController:navigationController animated:YES completion:^{
    }];
}

- (void)presentBlurredAudioRecorderViewControllerAnimated:(nonnull IQAudioRecorderViewController *)audioRecorderViewController
{
    audioRecorderViewController.blurrEnabled = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:audioRecorderViewController];
    
    navigationController.toolbarHidden = NO;
    navigationController.toolbar.translucent = YES;
    [navigationController.toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [navigationController.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionAny];
    
    navigationController.navigationBar.translucent = YES;
    [navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [navigationController.navigationBar setShadowImage:[UIImage new]];
    
    navigationController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    audioRecorderViewController.barStyle = audioRecorderViewController.barStyle;        //This line is used to refresh UI of Audio Recorder View Controller
    [self presentViewController:navigationController animated:NO completion:nil];
}

@end
