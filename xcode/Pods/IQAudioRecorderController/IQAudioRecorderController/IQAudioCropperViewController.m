//
//  IQAudioCropperViewController.m
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

#import "IQAudioCropperViewController.h"
#import "IQ_FDWaveformView.h"
#import "NSString+IQTimeIntervalFormatter.h"
#import "IQCropSelectionBeginView.h"
#import "IQCropSelectionEndView.h"

@interface IQAudioCropperViewController ()<IQ_FDWaveformViewDelegate,AVAudioPlayerDelegate>
{
    //BlurrView
    UIVisualEffectView *visualEffectView;
    BOOL _isFirstTime;

    UIView *middleContainerView;
    
    IQ_FDWaveformView *waveformView;
    UIActivityIndicatorView *waveLoadiingIndicatorView;
    
    //Navigation Bar
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    //Toolbar
    UIBarButtonItem *_flexItem;
    
    //Playing controls
    UIBarButtonItem *_playButton;
    UIBarButtonItem *_pauseButton;
    UIBarButtonItem *_stopPlayButton;

    UIBarButtonItem *_cropButton;
    UIBarButtonItem *_cropActivityBarButton;
    UIActivityIndicatorView *_cropActivityIndicatorView;

    IQCropSelectionView *leftCropView;
    IQCropSelectionView *rightCropView;
    
    //Playing
    AVAudioPlayer *_audioPlayer;
//    BOOL _wasPlaying;
    CADisplayLink *playProgressDisplayLink;
    
    //Private variables
    NSString *_oldSessionCategory;
    BOOL _wasIdleTimerDisabled;
}

@property(nonnull, nonatomic, strong, readwrite) NSString *originalAudioFilePath;
@property(nonnull, nonatomic, strong, readwrite) NSString *currentAudioFilePath;

@property(nonatomic, assign) BOOL blurrEnabled;

@end

@implementation IQAudioCropperViewController
@dynamic title;

-(instancetype)initWithFilePath:(NSString*)audioFilePath
{
    self = [super init];
    
    if (self)
    {
        self.originalAudioFilePath = audioFilePath;
        self.currentAudioFilePath = audioFilePath;
    }

    return self;
}

-(void)setNormalTintColor:(UIColor *)normalTintColor
{
    _normalTintColor = normalTintColor;
    
    _playButton.tintColor = [self _normalTintColor];
    _pauseButton.tintColor = [self _normalTintColor];
    _stopPlayButton.tintColor = [self _normalTintColor];
    _cropButton.tintColor = [self _normalTintColor];
    waveformView.wavesColor = [self _normalTintColor];
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
    waveformView.progressColor = [self _highlightedTintColor];
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

-(void)setBarStyle:(UIBarStyle)barStyle
{
    _barStyle = barStyle;
    
    if (self.barStyle == UIBarStyleDefault)
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.tintColor = [self _normalTintColor];
        self.navigationController.toolbar.tintColor = [self _normalTintColor];
        _cropActivityIndicatorView.color = [UIColor lightGrayColor];
        waveLoadiingIndicatorView.color = [UIColor lightGrayColor];
    }
    else
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
        _cropActivityIndicatorView.color = [UIColor whiteColor];
        waveLoadiingIndicatorView.color = [UIColor whiteColor];
    }
    
    self.view.tintColor = [self _normalTintColor];
    self.highlightedTintColor = self.highlightedTintColor;
    self.normalTintColor = self.normalTintColor;
}

-(void)loadView
{
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:nil];
    visualEffectView.frame = [UIScreen mainScreen].bounds;
    
    self.view = visualEffectView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _isFirstTime = YES;

    {
        if (self.title.length == 0)
        {
            self.navigationItem.title = @"Edit";
        }
    }
    
    NSURL *audioURL = [NSURL fileURLWithPath:self.currentAudioFilePath];
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, 200);
    frame = CGRectInset(frame, 16, 0);
    
    middleContainerView = [[UIView alloc] initWithFrame:frame];
    middleContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    middleContainerView.center = self.view.center;
    [visualEffectView.contentView addSubview:middleContainerView];
    
    {
        waveformView = [[IQ_FDWaveformView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(middleContainerView.frame), 150)];
        waveformView.delegate = self;
        waveformView.center = CGPointMake(CGRectGetMidX(middleContainerView.bounds), CGRectGetMidY(middleContainerView.bounds));
        waveformView.audioURL = audioURL;
        waveformView.wavesColor = [self _normalTintColor];
        waveformView.progressColor = [self _highlightedTintColor];
        waveformView.cropColor = [UIColor yellowColor];
        
        waveformView.doesAllowScroll = NO;
        waveformView.doesAllowScrubbing = NO;
        waveformView.doesAllowStretch = NO;
        
        waveformView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [middleContainerView addSubview:waveformView];
        
        waveLoadiingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        waveLoadiingIndicatorView.center = middleContainerView.center;
        waveLoadiingIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [visualEffectView.contentView addSubview:waveLoadiingIndicatorView];
    }
    
    {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:nil];
        _audioPlayer.delegate = self;
        _audioPlayer.meteringEnabled = YES;
    }

    {
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.leftBarButtonItem = _cancelButton;
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        _doneButton.enabled = NO;
        self.navigationItem.rightBarButtonItem = _doneButton;
    }
    
    {
        NSBundle* bundle = [NSBundle bundleForClass:self.class];

        self.navigationController.toolbarHidden = NO;
        
        _flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

        _stopPlayButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"stop_playing" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(stopPlayingButtonAction:)];
        _stopPlayButton.enabled = NO;
        _stopPlayButton.tintColor = [self _normalTintColor];
        _playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
        _playButton.tintColor = [self _normalTintColor];
        
        _pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pauseAction:)];
        _pauseButton.tintColor = [self _normalTintColor];

        _cropButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"scissor" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(cropAction:)];
        _cropButton.tintColor = [self _normalTintColor];
        _cropButton.enabled = NO;
        
        _cropActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _cropActivityBarButton = [[UIBarButtonItem alloc] initWithCustomView:_cropActivityIndicatorView];
        
        [self setToolbarItems:@[_stopPlayButton,_flexItem, _playButton,_flexItem,_cropButton] animated:NO];
    }
    
    {
        CGFloat margin = 30;
        
        leftCropView = [[IQCropSelectionBeginView alloc] initWithFrame:CGRectMake(CGRectGetMinX(waveformView.frame)-22, CGRectGetMinY(waveformView.frame)-margin, 45, CGRectGetHeight(waveformView.frame)+margin*2)];
        leftCropView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        rightCropView = [[IQCropSelectionEndView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(waveformView.frame)-22, CGRectGetMinY(waveformView.frame)-margin, 45, CGRectGetHeight(waveformView.frame)+margin*2)];
        rightCropView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        leftCropView.cropTime = 0;
        rightCropView.cropTime = _audioPlayer.duration;
        waveformView.cropStartSamples = waveformView.totalSamples*(leftCropView.cropTime/_audioPlayer.duration);
        waveformView.cropEndSamples = waveformView.totalSamples*(rightCropView.cropTime/_audioPlayer.duration);

        [middleContainerView addSubview:leftCropView];
        [middleContainerView addSubview:rightCropView];
        
        UIPanGestureRecognizer *leftCropPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(leftCropPanRecognizer:)];
        UIPanGestureRecognizer *rightCropPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rightCropPanRecognizer:)];
        [leftCropView addGestureRecognizer:leftCropPanRecognizer];
        [rightCropView addGestureRecognizer:rightCropPanRecognizer];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_isFirstTime)
    {
        _isFirstTime = NO;
        
        if (self.blurrEnabled)
        {
            if (self.barStyle == UIBarStyleDefault)
            {
                visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
            }
            else
            {
                visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            }
        }
        else
        {
            if (self.barStyle == UIBarStyleDefault)
            {
                self.view.backgroundColor = [UIColor whiteColor];
            }
            else
            {
                self.view.backgroundColor = [UIColor darkGrayColor];
            }
        }
    }
}

-(void)leftCropPanRecognizer:(UIPanGestureRecognizer*)panRecognizer
{
    static CGPoint beginPoint;
    static CGPoint beginCenter;
    
    if (panRecognizer.state == UIGestureRecognizerStateBegan)
    {
        beginPoint = [panRecognizer translationInView:middleContainerView];
        beginCenter = leftCropView.center;

        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_stopPlayButton.target methodSignatureForSelector:_stopPlayButton.action]];
        invocation.target = _stopPlayButton.target;
        invocation.selector = _stopPlayButton.action;
        [invocation invoke];
    }
    else if (panRecognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint newPoint = [panRecognizer translationInView:middleContainerView];
        
        //Left Margin
        CGFloat pointX = MAX(CGRectGetMinX(waveformView.frame), beginCenter.x+(newPoint.x-beginPoint.x));
        
        //Right Margin from right cropper
        pointX = MIN(CGRectGetMinX(rightCropView.frame), pointX);
        
        leftCropView.center = CGPointMake(pointX, beginCenter.y);
        
        {
            leftCropView.cropTime = (leftCropView.center.x/waveformView.frame.size.width)*_audioPlayer.duration;
            _audioPlayer.currentTime = leftCropView.cropTime;
            waveformView.progressSamples = waveformView.totalSamples*(_audioPlayer.currentTime/_audioPlayer.duration);
            waveformView.cropStartSamples = waveformView.totalSamples*(leftCropView.cropTime/_audioPlayer.duration);
        }
    }
    else if (panRecognizer.state == UIGestureRecognizerStateEnded|| panRecognizer.state == UIGestureRecognizerStateFailed)
    {
        beginPoint = CGPointZero;
        beginCenter = CGPointZero;
        
        if (leftCropView.cropTime == 0 && rightCropView.cropTime == _audioPlayer.duration)
        {
            _cropButton.enabled = NO;
        }
        else
        {
            _cropButton.enabled = YES;
        }
    }
}

-(void)rightCropPanRecognizer:(UIPanGestureRecognizer*)panRecognizer
{
    static CGPoint beginPoint;
    static CGPoint beginCenter;
    
    if (panRecognizer.state == UIGestureRecognizerStateBegan)
    {
        beginPoint = [panRecognizer translationInView:middleContainerView];
        beginCenter = rightCropView.center;
        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_stopPlayButton.target methodSignatureForSelector:_stopPlayButton.action]];
        invocation.target = _stopPlayButton.target;
        invocation.selector = _stopPlayButton.action;
        [invocation invoke];
    }
    else if (panRecognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint newPoint = [panRecognizer translationInView:middleContainerView];
        
        //Right Margin
        CGFloat pointX = MIN(CGRectGetMaxX(waveformView.frame), beginCenter.x+(newPoint.x-beginPoint.x));
        
        //Left Margin from left cropper
        pointX = MAX(CGRectGetMaxX(leftCropView.frame), pointX);

        rightCropView.center = CGPointMake(pointX, beginCenter.y);
        
        {
            rightCropView.cropTime = (rightCropView.center.x/waveformView.frame.size.width)*_audioPlayer.duration;
            waveformView.cropEndSamples = waveformView.totalSamples*(rightCropView.cropTime/_audioPlayer.duration);
        }
    }
    else if (panRecognizer.state == UIGestureRecognizerStateEnded|| panRecognizer.state == UIGestureRecognizerStateFailed)
    {
        beginPoint = CGPointZero;
        beginCenter = CGPointZero;
        
        if (leftCropView.cropTime == 0 && rightCropView.cropTime == _audioPlayer.duration)
        {
            _cropButton.enabled = NO;
        }
        else
        {
            _cropButton.enabled = YES;
        }
    }
}

#pragma mark - Audio Play

-(void)updatePlayProgress
{
    waveformView.progressSamples = waveformView.totalSamples*(_audioPlayer.currentTime/_audioPlayer.duration);
    
    if (_audioPlayer.currentTime >= rightCropView.cropTime)
    {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_stopPlayButton.target methodSignatureForSelector:_stopPlayButton.action]];
        invocation.target = _stopPlayButton.target;
        invocation.selector = _stopPlayButton.action;
        [invocation invoke];
    }
}

- (void)playAction:(UIBarButtonItem *)item
{
    _oldSessionCategory = [AVAudioSession sharedInstance].category;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
    
    //UI Update
    {
        [self setToolbarItems:@[_stopPlayButton,_flexItem, _pauseButton,_flexItem,_cropButton] animated:YES];
        _stopPlayButton.enabled = YES;
        _cropButton.enabled = NO;
        _cancelButton.enabled = NO;
        _doneButton.enabled = NO;
    }
    
    {
        [playProgressDisplayLink invalidate];
        playProgressDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updatePlayProgress)];
        [playProgressDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

-(void)pauseAction:(UIBarButtonItem*)item
{
    [[AVAudioSession sharedInstance] setCategory:_oldSessionCategory error:nil];
    [UIApplication sharedApplication].idleTimerDisabled = _wasIdleTimerDisabled;
    
    [_audioPlayer pause];

    //    //UI Update
    {
        [self setToolbarItems:@[_stopPlayButton,_flexItem, _playButton,_flexItem,_cropButton] animated:YES];
    }
}

-(void)stopPlayingButtonAction:(UIBarButtonItem*)item
{
    //UI Update
    {
        [self setToolbarItems:@[_stopPlayButton,_flexItem, _playButton,_flexItem,_cropButton] animated:YES];
        _stopPlayButton.enabled = NO;
        _cancelButton.enabled = YES;

        if ([self.originalAudioFilePath isEqualToString:self.currentAudioFilePath])
        {
            _doneButton.enabled = NO;
        }
        else
        {
            _doneButton.enabled = YES;
        }
        
        if (leftCropView.cropTime == 0 && rightCropView.cropTime == _audioPlayer.duration)
        {
            _cropButton.enabled = NO;
        }
        else
        {
            _cropButton.enabled = YES;
        }
    }
    
    {
        [playProgressDisplayLink invalidate];
        playProgressDisplayLink = nil;
    }

    [_audioPlayer stop];
    
    {
        _audioPlayer.currentTime = leftCropView.cropTime;
        waveformView.progressSamples = waveformView.totalSamples*(_audioPlayer.currentTime/_audioPlayer.duration);
    }

    [[AVAudioSession sharedInstance] setCategory:_oldSessionCategory error:nil];
    [UIApplication sharedApplication].idleTimerDisabled = _wasIdleTimerDisabled;
}

#pragma mark - Crop

-(void)cropAction:(UIBarButtonItem*)item
{
    {
        [_cropActivityIndicatorView startAnimating];
        [self setToolbarItems:@[_stopPlayButton,_flexItem, _playButton,_flexItem,_cropActivityBarButton] animated:YES];
        _stopPlayButton.enabled = NO;
        _playButton.enabled = NO;
        _cancelButton.enabled = NO;
        _doneButton.enabled = NO;
        self.view.userInteractionEnabled = NO;
    }

    [[NSOperationQueue new] addOperationWithBlock:^{

//        [NSThread sleepForTimeInterval:5];
        
        {
            NSURL *audioURL = [NSURL fileURLWithPath:self.currentAudioFilePath];

            AVAsset *asset = [AVAsset assetWithURL:audioURL];
            
            // get the first audio track
            NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            
            AVAssetTrack *track = [tracks firstObject];
            
            // create the export session
            // no need for a retain here, the session will be retained by the
            // completion handler since it is referenced there
            AVAssetExportSession *exportSession = [AVAssetExportSession
                                                   exportSessionWithAsset:asset
                                                   presetName:AVAssetExportPresetAppleM4A];
            
            CMTimeScale scale = [track naturalTimeScale];

            CMTime startTime = CMTimeMake(leftCropView.cropTime*scale, scale);
            CMTime stopTime = CMTimeMake(rightCropView.cropTime*scale, scale);
            CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
            
            // setup audio mix
            AVMutableAudioMix *exportAudioMix = [AVMutableAudioMix audioMix];
            AVMutableAudioMixInputParameters *exportAudioMixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
            
            exportAudioMix.inputParameters = [NSArray arrayWithObject:exportAudioMixInputParameters];
            
            NSString *globallyUniqueString = [NSProcessInfo processInfo].globallyUniqueString;
            
            NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",globallyUniqueString]];

            // configure export session  output with all our parameters
            exportSession.outputURL = [NSURL fileURLWithPath:filePath]; // output path
            exportSession.outputFileType = AVFileTypeAppleM4A; // output file type
            exportSession.timeRange = exportTimeRange; // trim time range
            exportSession.audioMix = exportAudioMix; // fade in audio mix
            
            // perform the export
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                
                switch (exportSession.status)
                {
                    case AVAssetExportSessionStatusCancelled:
                    case AVAssetExportSessionStatusCompleted:
                    case AVAssetExportSessionStatusFailed:
                    {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            
                            if (exportSession.status == AVAssetExportSessionStatusCompleted)
                            {
                                NSString *globallyUniqueString = [NSProcessInfo processInfo].globallyUniqueString;
                                NSString *newFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",globallyUniqueString]];
                                NSURL *audioURL = [NSURL fileURLWithPath:newFilePath];

                                [[NSFileManager defaultManager] moveItemAtURL:exportSession.outputURL toURL:audioURL error:nil];
                                self.currentAudioFilePath = newFilePath;
                                
                                waveformView.audioURL = audioURL;
                                [_audioPlayer stop];
                                _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:nil];
                                _audioPlayer.delegate = self;
                                _audioPlayer.meteringEnabled = YES;

                                CGFloat margin = 30;

                                [UIView animateWithDuration:0.1 animations:^{

                                    leftCropView.frame = CGRectMake(CGRectGetMinX(waveformView.frame)-22, CGRectGetMinY(waveformView.frame)-margin, 45, CGRectGetHeight(waveformView.frame)+margin*2);
                                    leftCropView.cropTime = 0;
                                    
                                    rightCropView.frame = CGRectMake(CGRectGetMaxX(waveformView.frame)-22, CGRectGetMinY(waveformView.frame)-margin, 45, CGRectGetHeight(waveformView.frame)+margin*2);
                                    rightCropView.cropTime = _audioPlayer.duration;
                                }];
                            }
                            
                            [_cropActivityIndicatorView stopAnimating];
                            [self setToolbarItems:@[_stopPlayButton,_flexItem, _playButton,_flexItem,_cropButton] animated:YES];
                            _stopPlayButton.enabled = YES;
                            _playButton.enabled = YES;
                            _cancelButton.enabled = YES;
                            _doneButton.enabled = YES;
                            _cropButton.enabled = NO;
                            self.view.userInteractionEnabled = YES;
                        }];
                    }
                        break;
                        
                    default:
                        break;
                }
            }];
        }
    }];
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

#pragma mark - IQ_FDWaveformView delegate

- (void)waveformViewWillRender:(IQ_FDWaveformView *)waveformView
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [UIView animateWithDuration:0.1 animations:^{
            middleContainerView.alpha = 0.0;
            [waveLoadiingIndicatorView startAnimating];
        }];
    }];
}

- (void)waveformViewDidRender:(IQ_FDWaveformView *)waveformView
{
    [UIView animateWithDuration:0.1 animations:^{
        middleContainerView.alpha = 1.0;
        [waveLoadiingIndicatorView stopAnimating];
    }];
}

- (void)waveformViewWillLoad:(IQ_FDWaveformView *)waveformView
{
//    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)waveformViewDidLoad:(IQ_FDWaveformView *)waveformView
{
//    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)waveformDidBeginPanning:(IQ_FDWaveformView *)waveformView
{
//    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)waveformDidEndPanning:(IQ_FDWaveformView *)waveformView
{
//    NSLog(@"%@",NSStringFromSelector(_cmd));
}



#pragma mark - Cancel or Done

-(void)cancelAction:(UIBarButtonItem*)item
{
    if ([self.originalAudioFilePath isEqualToString:self.currentAudioFilePath] == NO)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Discard changes?" message:@"You have some unsaved changes. Audio will not be saved. Are you sure you want to discard?" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Discard" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            if ([self.delegate respondsToSelector:@selector(audioCropperControllerDidCancel:)])
            {
                [self.delegate audioCropperControllerDidCancel:self];
            }
            else
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(audioCropperControllerDidCancel:)])
        {
            [self.delegate audioCropperControllerDidCancel:self];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

-(void)doneAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioCropperController:didFinishWithAudioAtPath:)])
    {
        [self.delegate audioCropperController:self didFinishWithAudioAtPath:_currentAudioFilePath];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Orientation

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

        leftCropView.center = CGPointMake((leftCropView.cropTime/_audioPlayer.duration)*CGRectGetWidth(middleContainerView.frame),leftCropView.center.y);
        rightCropView.center = CGPointMake((rightCropView.cropTime/_audioPlayer.duration)*CGRectGetWidth(middleContainerView.frame),rightCropView.center.y);
        
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
         
     }];
}

@end


@implementation UIViewController (IQAudioCropperViewController)

- (void)presentAudioCropperViewControllerAnimated:(nonnull IQAudioCropperViewController *)audioCropperViewController
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:audioCropperViewController];
    
    navigationController.toolbarHidden = NO;
    navigationController.toolbar.translucent = YES;
    
    navigationController.navigationBar.translucent = YES;
    
    audioCropperViewController.barStyle = audioCropperViewController.barStyle;        //This line is used to refresh UI of Audio Recorder View Controller
    [self presentViewController:navigationController animated:YES completion:^{
    }];
}

- (void)presentBlurredAudioCropperViewControllerAnimated:(nonnull IQAudioCropperViewController *)audioCropperViewController
{
    audioCropperViewController.blurrEnabled = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:audioCropperViewController];
    
    navigationController.toolbarHidden = NO;
    navigationController.toolbar.translucent = YES;
    [navigationController.toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [navigationController.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionAny];
    
    navigationController.navigationBar.translucent = YES;
    [navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [navigationController.navigationBar setShadowImage:[UIImage new]];
    
    navigationController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    audioCropperViewController.barStyle = audioCropperViewController.barStyle;        //This line is used to refresh UI of Audio Recorder View Controller
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end

