//
//  FDWaveformView
//
//  Created by William Entriken on 10/6/13.
//  Copyright (c) 2013 William Entriken. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@protocol IQ_FDWaveformViewDelegate;

/// A view for rendering audio waveforms
@interface IQ_FDWaveformView : UIView

/// A delegate to accept progress reporting
@property (nonatomic, weak) id<IQ_FDWaveformViewDelegate> delegate;

/// The audio file to render
@property (nonatomic, strong) NSURL *audioURL;

/****************************************************************/

/// The total number of audio samples in the file
@property (nonatomic, assign, readonly) long int totalSamples;

/// The color of the waveform
@property (nonatomic, copy) UIColor *wavesColor;

/****************************************************************/

/// A portion of the waveform rendering to be highlighted
@property (nonatomic, assign) long int progressSamples;

/// The color of the highlighted waveform (see `progressSamples`
@property (nonatomic, copy) UIColor *progressColor;

/****************************************************************/

/// The color of the cropped waveform
@property (nonatomic, copy) UIColor *cropColor;

/// crop start samples
@property (nonatomic, assign) long int cropStartSamples;

/// crop end samples
@property (nonatomic, assign) long int cropEndSamples;

/****************************************************************/

/// The first sample to render
@property (nonatomic, assign) long int zoomStartSamples;

/// The last sample to render
@property (nonatomic, assign) long int zoomEndSamples;

/// Whether to all the scrub gesture
@property (nonatomic) BOOL doesAllowScrubbing;

/// Whether to allow the stretch gesture
@property (nonatomic) BOOL doesAllowStretch;

/// Whether to allow the scroll gesture
@property (nonatomic) BOOL doesAllowScroll;

@end

/// To receive progress updates from FDWaveformView
@protocol IQ_FDWaveformViewDelegate <NSObject>
@optional

/// Rendering will begin
- (void)waveformViewWillRender:(IQ_FDWaveformView *)waveformView;

/// Rendering did complete
- (void)waveformViewDidRender:(IQ_FDWaveformView *)waveformView;

/// An audio file will be loaded
- (void)waveformViewWillLoad:(IQ_FDWaveformView *)waveformView;

/// An audio file was loaded
- (void)waveformViewDidLoad:(IQ_FDWaveformView *)waveformView;

/// The panning gesture did begin
- (void)waveformDidBeginPanning:(IQ_FDWaveformView *)waveformView;

/// The panning gesture did end
- (void)waveformDidEndPanning:(IQ_FDWaveformView *)waveformView;
@end