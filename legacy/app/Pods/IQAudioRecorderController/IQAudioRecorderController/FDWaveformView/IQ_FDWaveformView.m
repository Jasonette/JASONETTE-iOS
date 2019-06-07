//
//  FDWaveformView
//
//  Created by William Entriken on 10/6/13.
//  Copyright (c) 2013 William Entriken. All rights reserved.
//


// FROM http://stackoverflow.com/questions/5032775/drawing-waveform-with-avassetreader
// DO SEE http://stackoverflow.com/questions/1191868/uiimageview-scaling-interpolation
// see http://stackoverflow.com/questions/3514066/how-to-tint-a-transparent-png-image-in-iphone

#import "IQ_FDWaveformView.h"
#import <UIKit/UIKit.h>

#define absX(x) ((x)<0?0-(x):(x))
#define minMaxX(x,mn,mx) ((x)<=(mn)?(mn):((x)>=(mx)?(mx):(x)))
#define noiseFloor (-50.0)
#define decibel(amplitude) (20.0 * log10(absX(amplitude)/32767.0))

// Drawing a larger image than needed to have it available for scrolling
#define horizontalMinimumBleed 0.1
#define horizontalMaximumBleed 3
#define horizontalTargetBleed 0.5
// Drawing more pixels than shown to get antialiasing
#define horizontalMinimumOverdraw 2
#define horizontalMaximumOverdraw 5
#define horizontalTargetOverdraw 3
#define verticalMinimumOverdraw 1
#define verticalMaximumOverdraw 3
#define verticalTargetOverdraw 2


@interface IQ_FDWaveformView() <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIImageView *image;
@property (nonatomic, strong) UIImageView *highlightedImage;
@property (nonatomic, strong) UIImageView *croppedImage;

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVAssetTrack *assetTrack;
@property (nonatomic, assign) long int totalSamples;
@property (nonatomic, assign) long int cachedStartSamples;
@property (nonatomic, assign) long int cachedEndSamples;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property BOOL renderingInProgress;
@property BOOL loadingInProgress;
@end

@implementation IQ_FDWaveformView

- (void)initialize
{
    {
        self.image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.image.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.image];
    }
    
    {
        self.highlightedImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.highlightedImage.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.highlightedImage];
    }

    {
        self.croppedImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.croppedImage.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.croppedImage];
    }
    
    self.clipsToBounds = YES;
    
    self.wavesColor = [UIColor blackColor];
    self.progressColor = [UIColor blueColor];
    
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    self.pinchRecognizer.delegate = self;
    [self addGestureRecognizer:self.pinchRecognizer];

    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panRecognizer.delegate = self;
    [self addGestureRecognizer:self.panRecognizer];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:self.tapRecognizer];
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    if (self = [super initWithCoder:aCoder])
        [self initialize];
    return self;
}

- (instancetype)initWithFrame:(CGRect)rect
{
    if (self = [super initWithFrame:rect])
        [self initialize];
    return self;
}

- (void)setAudioURL:(NSURL *)audioURL
{
    _audioURL = audioURL;
    self.loadingInProgress = YES;
    if ([self.delegate respondsToSelector:@selector(waveformViewWillLoad:)])
        [self.delegate waveformViewWillLoad:self];
    self.asset = [AVURLAsset URLAssetWithURL:audioURL options:nil];
    self.assetTrack = [[self.asset tracksWithMediaType:AVMediaTypeAudio] firstObject];

    [self.asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^() {
        self.loadingInProgress = NO;
        if ([self.delegate respondsToSelector:@selector(waveformViewDidLoad:)])
            [self.delegate waveformViewDidLoad:self];
        
        NSError *error = nil;
        AVKeyValueStatus durationStatus = [self.asset statusOfValueForKey:@"duration" error:&error];
        switch (durationStatus) {
            case AVKeyValueStatusLoaded:{
                self.image.image = nil;
                self.highlightedImage.image = nil;
                self.croppedImage.image = nil;
                
                NSArray *formatDesc = self.assetTrack.formatDescriptions;
                CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)formatDesc[0];
                const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(item);
                unsigned long int samples = asbd->mSampleRate * (float)self.asset.duration.value/self.asset.duration.timescale;
                self.totalSamples = self.zoomEndSamples = self.cropEndSamples = samples;
                self.progressSamples = self.zoomStartSamples = self.cropStartSamples = 0;

                [self setNeedsDisplay];
                [self performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
                break;
            }
            case AVKeyValueStatusUnknown:
            case AVKeyValueStatusLoading:
            case AVKeyValueStatusFailed:
            case AVKeyValueStatusCancelled:
                NSLog(@"IQ_FDWaveformView could not load asset: %@", error.localizedDescription);
                break;
            default:
                break;
        }
    }];
}

- (void)setProgressSamples:(long)progressSamples
{
    _progressSamples = progressSamples;
    if (self.totalSamples) {
        float progress = (float)self.progressSamples / self.totalSamples;
        
        CALayer *layer = [[CALayer alloc] init];
        layer.frame = CGRectMake(0,0,self.frame.size.width*progress,self.frame.size.height);
        layer.backgroundColor = [[UIColor blackColor] CGColor];
        self.highlightedImage.layer.mask = layer;
        [self setNeedsLayout];
    }
}

-(void)setCropStartSamples:(long)cropStartSamples
{
    _cropStartSamples = cropStartSamples;

    if (self.totalSamples) {
        float startProgress = (float)self.cropStartSamples / self.totalSamples;
        float endProgress = (float)self.cropEndSamples / self.totalSamples;

        CGRect visibleRect = CGRectMake(self.frame.size.width*startProgress,0,self.frame.size.width*(endProgress-startProgress),self.frame.size.height);;
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:self.croppedImage.bounds];
        [bezierPath appendPath:[UIBezierPath bezierPathWithRect:visibleRect]];
        
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        layer.frame = self.croppedImage.bounds;
        layer.fillRule = kCAFillRuleEvenOdd;
        layer.fillColor = [UIColor blackColor].CGColor;
        layer.path = bezierPath.CGPath;

        self.croppedImage.layer.mask = layer;
        [self setNeedsLayout];
    }
}

-(void)setCropEndSamples:(long)cropEndSamples
{
    _cropEndSamples = cropEndSamples;

    if (self.totalSamples) {
        float startProgress = (float)self.cropStartSamples / self.totalSamples;
        float endProgress = (float)self.cropEndSamples / self.totalSamples;
        
        CGRect visibleRect = CGRectMake(self.frame.size.width*startProgress,0,self.frame.size.width*(endProgress-startProgress),self.frame.size.height);;
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:self.croppedImage.bounds];
        [bezierPath appendPath:[UIBezierPath bezierPathWithRect:visibleRect]];
        
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        layer.frame = self.croppedImage.bounds;
        layer.fillRule = kCAFillRuleEvenOdd;
        layer.fillColor = [UIColor blackColor].CGColor;
        layer.path = bezierPath.CGPath;
        
        self.croppedImage.layer.mask = layer;
        [self setNeedsLayout];
    }
}

- (void)setZoomStartSamples:(long)startSamples
{
    _zoomStartSamples = startSamples;
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (void)setZoomEndSamples:(long)endSamples
{
    _zoomEndSamples = endSamples;
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.assetTrack || self.renderingInProgress || self.zoomEndSamples == 0)
        return;
    
    unsigned long int displayRange = self.zoomEndSamples - self.zoomStartSamples;
    BOOL needToRender = NO;
    if (!self.image.image)
        needToRender = YES;
    if (self.cachedStartSamples < (unsigned long)minMaxX((float)self.zoomStartSamples - displayRange * horizontalMaximumBleed, 0, self.totalSamples))
        needToRender = YES;
    if (self.cachedStartSamples > (unsigned long)minMaxX((float)self.zoomStartSamples - displayRange * horizontalMinimumBleed, 0, self.totalSamples))
        needToRender = YES;
    if (self.cachedEndSamples < (unsigned long)minMaxX((float)self.zoomEndSamples + displayRange * horizontalMinimumBleed, 0, self.totalSamples))
        needToRender = YES;
    if (self.cachedEndSamples > (unsigned long)minMaxX((float)self.zoomEndSamples + displayRange * horizontalMaximumBleed, 0, self.totalSamples))
        needToRender = YES;
    if (self.image.image.size.width < self.frame.size.width * [UIScreen mainScreen].scale * horizontalMinimumOverdraw)
        needToRender = YES;
    if (self.image.image.size.width > self.frame.size.width * [UIScreen mainScreen].scale * horizontalMaximumOverdraw)
        needToRender = YES;
    if (self.image.image.size.height < self.frame.size.height * [UIScreen mainScreen].scale * verticalMinimumOverdraw)
        needToRender = YES;
    if (self.image.image.size.height > self.frame.size.height * [UIScreen mainScreen].scale * verticalMaximumOverdraw)
        needToRender = YES;
    if (needToRender) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self renderAsset];
        });
        return;
    }
    
    // We need to place the images which have samples from cachedStart..cachedEnd
    // inside our frame which represents startSamples..endSamples
    // all figures are a portion of our frame size
    float scaledStart = 0, scaledEnd = 1, scaledWidth = 1;
    if (self.cachedEndSamples > self.cachedStartSamples) {
        scaledStart = ((float)self.cachedStartSamples-self.zoomStartSamples)/(self.zoomEndSamples-self.zoomStartSamples);
        scaledEnd = ((float)self.cachedEndSamples-self.zoomStartSamples)/(self.zoomEndSamples-self.zoomStartSamples);
        scaledWidth = scaledEnd - scaledStart;
    }
    
    CGRect frame = CGRectMake(self.frame.size.width*scaledStart, 0, self.frame.size.width*scaledWidth, self.frame.size.height);
    self.image.frame = self.highlightedImage.frame = self.croppedImage.frame = frame;
}

- (void)renderAsset
{
    if (self.renderingInProgress)
        return;
    self.renderingInProgress = YES;
    if ([self.delegate respondsToSelector:@selector(waveformViewWillRender:)])
        [self.delegate waveformViewWillRender:self];
    unsigned long int displayRange = self.zoomEndSamples - self.zoomStartSamples;
    unsigned long int renderStartSamples = minMaxX((long)self.zoomStartSamples - displayRange * horizontalTargetBleed, 0, self.totalSamples);
    unsigned long int renderEndSamples = minMaxX((long)self.zoomEndSamples + displayRange * horizontalTargetBleed, 0, self.totalSamples);
    
    CGFloat widthInPixels = self.frame.size.width * [UIScreen mainScreen].scale * horizontalTargetOverdraw;
    CGFloat heightInPixels = self.frame.size.height * [UIScreen mainScreen].scale * verticalTargetOverdraw;
    
    [IQ_FDWaveformView sliceAndDownsampleAsset:self.asset track:self.assetTrack startSamples:renderStartSamples endSamples:renderEndSamples targetSamples:widthInPixels done:^(NSData *samples, NSInteger sampleCount, Float32 sampleMax) {
        
        [self plotLogGraph:samples
              maximumValue:sampleMax
              mimimumValue:noiseFloor
               sampleCount:sampleCount
               imageHeight:heightInPixels
                      done:^(UIImage *image,
                             UIImage *selectedImage,
                             UIImage *cropImage) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              self.image.image = image;
                              self.highlightedImage.image = selectedImage;
                              self.croppedImage.image = cropImage;
                              self.cachedStartSamples = renderStartSamples;
                              self.cachedEndSamples = renderEndSamples;
                              self.renderingInProgress = NO;
                              [self layoutSubviews]; // warning
                              if ([self.delegate respondsToSelector:@selector(waveformViewDidRender:)])
                                  [self.delegate waveformViewDidRender:self];
                          });
                      }
         ];
    }];
}

+ (void)sliceAndDownsampleAsset:(AVAsset *)songAsset
                          track:(AVAssetTrack *)songTrack
                   startSamples:(unsigned long int)start
                     endSamples:(unsigned long int)end
                  targetSamples:(unsigned long int)targetSamples
                           done:(void(^)(NSData *samples, NSInteger sampleCount, Float32 sampleMax))done
{
    NSError *error = nil;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    reader.timeRange = CMTimeRangeMake(CMTimeMake(start, songAsset.duration.timescale), CMTimeMake((end-start), songAsset.duration.timescale));
    NSDictionary *outputSettingsDict = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
                                         AVLinearPCMBitDepthKey: @16,
                                         AVLinearPCMIsBigEndianKey: @NO,
                                         AVLinearPCMIsFloatKey: @NO,
                                         AVLinearPCMIsNonInterleaved: @NO};
    AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:songTrack outputSettings:outputSettingsDict];
    output.alwaysCopiesSampleData = NO;
    [reader addOutput:output];
    UInt32 channelCount = 0;
    NSArray *formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)formatDesc[i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item);
        if (!fmtDesc) return; //!
        channelCount = fmtDesc->mChannelsPerFrame;
    }
    
    UInt32 bytesPerInputSample = 2 * channelCount;
    Float32 sampleMax = noiseFloor;
    Float64 tally = 0;
    Float32 tallyCount = 0;
    
    NSInteger downsampleFactor = (end-start) / targetSamples;
    downsampleFactor = downsampleFactor<1 ? 1 : downsampleFactor;
    NSMutableData *fullSongData = [NSMutableData dataWithCapacity:(NSUInteger)songAsset.duration.value/downsampleFactor*2]; // 16-bit samples
    [reader startReading];
    
    while (reader.status == AVAssetReaderStatusReading) {
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)(reader.outputs)[0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        if (sampleBufferRef) {
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            size_t bufferLength = CMBlockBufferGetDataLength(blockBufferRef);
            void *data = malloc(bufferLength);
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, bufferLength, data);
            
            SInt16 *samples = (SInt16 *) data;
            int sampleCount = (int) bufferLength / bytesPerInputSample;
            for (int i=0; i<sampleCount; i++) {
                Float32 rawData = (Float32) *samples++;
                Float32 sample = minMaxX(decibel(rawData),noiseFloor,0);
                tally += sample; // Should be RMS?
                for (int j=1; j<channelCount; j++)
                    samples++;
                tallyCount++;
                
                if (tallyCount == downsampleFactor) {
                    sample = tally / tallyCount;
                    sampleMax = sampleMax > sample ? sampleMax : sample;
                    [fullSongData appendBytes:&sample length:sizeof(sample)];
                    tally = 0;
                    tallyCount = 0;
                }
            }
            CMSampleBufferInvalidate(sampleBufferRef);
            CFRelease(sampleBufferRef);
            free(data);
        }
    }
    
    // if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown)
    // Something went wrong. Handle it.
    if (reader.status == AVAssetReaderStatusCompleted){
        done(fullSongData, fullSongData.length/4, sampleMax);
    }
}

- (void)plotLogGraph:(NSData *) samplesData
        maximumValue:(Float32) normalizeMax
        mimimumValue:(Float32) normalizeMin
         sampleCount:(NSInteger) sampleCount
         imageHeight:(float) imageHeight
                done:(void(^)(UIImage *image,
                              UIImage *selectedImage,
                              UIImage *cropImage))done
{
    Float32 *samples = (Float32 *)samplesData.bytes;
    
    // TODO: switch to a synchronous function that paints onto a given context? (for issue #2)
    CGSize imageSize = CGSizeMake(sampleCount, imageHeight);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context, NO);
    CGContextSetAlpha(context,1.0);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, [self.wavesColor CGColor]);
    
    float halfGraphHeight = (imageHeight / 2);
    float centerLeft = halfGraphHeight;
    float sampleAdjustmentFactor;
    if(normalizeMax - noiseFloor == 0){
        sampleAdjustmentFactor = imageHeight / 2;
    }else{
        sampleAdjustmentFactor = imageHeight / (normalizeMax - noiseFloor) / 2;
    }

    for (NSInteger intSample=0; intSample<sampleCount; intSample++) {
        Float32 sample = *samples++;
        float pixels = (sample - noiseFloor) * sampleAdjustmentFactor;
        if (pixels == 0) {
            pixels = 1;
        }
        CGContextMoveToPoint(context, intSample, centerLeft-pixels);
        CGContextAddLineToPoint(context, intSample, centerLeft+pixels);
        CGContextStrokePath(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    CGRect drawRect = CGRectMake(0, 0, image.size.width, image.size.height);
    [self.progressColor set];
    UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop);
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();

    [self.cropColor set];
    UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop);
    UIImage *cropImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    done(image, tintedImage,cropImage);
}

#pragma mark - Interaction

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    if (!self.doesAllowStretch)
        return;
    if (recognizer.scale == 1) return;
    
    unsigned long middleSamples = (self.zoomStartSamples + self.zoomEndSamples) / 2;
    unsigned long rangeSamples = self.zoomEndSamples - self.zoomStartSamples;
    if (middleSamples - 1/recognizer.scale*rangeSamples/2 >= 0)
        _zoomStartSamples = middleSamples - 1/recognizer.scale*rangeSamples/2;
    else
        _zoomStartSamples = 0;
    if (middleSamples + 1/recognizer.scale*rangeSamples/2 <= self.totalSamples)
        _zoomEndSamples = middleSamples + 1/recognizer.scale*rangeSamples/2;
    else
        _zoomEndSamples = self.totalSamples;
    [self setNeedsDisplay];
    [self setNeedsLayout];
    recognizer.scale = 1;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer translationInView:self];
    NSLog(@"translation: %f", point.x);

    if (self.doesAllowScroll) {
        if (recognizer.state == UIGestureRecognizerStateBegan && [self.delegate respondsToSelector:@selector(waveformDidBeginPanning:)])
          [self.delegate waveformDidBeginPanning:self];
      
        long translationSamples = (float)(self.zoomEndSamples-self.zoomStartSamples) * point.x / self.bounds.size.width;
        [recognizer setTranslation:CGPointZero inView:self];
        if ((float)self.zoomStartSamples - translationSamples < 0)
            translationSamples = (float)self.zoomStartSamples;
        if ((float)self.zoomEndSamples - translationSamples > self.totalSamples)
            translationSamples = self.zoomEndSamples - self.totalSamples;
        _zoomStartSamples -= translationSamples;
        _zoomEndSamples -= translationSamples;
      
        if (recognizer.state == UIGestureRecognizerStateEnded && [self.delegate respondsToSelector:@selector(waveformDidEndPanning:)])
          [self.delegate waveformDidEndPanning:self];
      
        [self setNeedsDisplay];
        [self setNeedsLayout];
    } else if (self.doesAllowScrubbing) {
        self.progressSamples = self.zoomStartSamples + (float)(self.zoomEndSamples-self.zoomStartSamples) * [recognizer locationInView:self].x / self.bounds.size.width;
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (self.doesAllowScrubbing) {
        self.progressSamples = self.zoomStartSamples + (float)(self.zoomEndSamples-self.zoomStartSamples) * [recognizer locationInView:self].x / self.bounds.size.width;
    }
}

@end
