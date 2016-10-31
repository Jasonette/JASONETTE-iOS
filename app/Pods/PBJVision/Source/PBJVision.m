//
//  PBJVision.m
//  PBJVision
//
//  Created by Patrick Piemonte on 4/30/13.
//  Copyright (c) 2013-present, Patrick Piemonte, http://patrickpiemonte.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "PBJVision.h"
#import "PBJVisionUtilities.h"
#import "PBJMediaWriter.h"
#import "PBJGLProgram.h"

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <OpenGLES/EAGL.h>

#define LOG_VISION 1
#ifndef DLog
#if !defined(NDEBUG) && LOG_VISION
#   define DLog(fmt, ...) NSLog((@"VISION: " fmt), ##__VA_ARGS__);
#else
#   define DLog(...)
#endif
#endif

NSString * const PBJVisionErrorDomain = @"PBJVisionErrorDomain";

static uint64_t const PBJVisionRequiredMinimumDiskSpaceInBytes = 49999872; // ~ 47 MB
static CGFloat const PBJVisionThumbnailWidth = 160.0f;

// KVO contexts

static NSString * const PBJVisionFocusObserverContext = @"PBJVisionFocusObserverContext";
static NSString * const PBJVisionExposureObserverContext = @"PBJVisionExposureObserverContext";
static NSString * const PBJVisionWhiteBalanceObserverContext = @"PBJVisionWhiteBalanceObserverContext";
static NSString * const PBJVisionFlashModeObserverContext = @"PBJVisionFlashModeObserverContext";
static NSString * const PBJVisionTorchModeObserverContext = @"PBJVisionTorchModeObserverContext";
static NSString * const PBJVisionFlashAvailabilityObserverContext = @"PBJVisionFlashAvailabilityObserverContext";
static NSString * const PBJVisionTorchAvailabilityObserverContext = @"PBJVisionTorchAvailabilityObserverContext";
static NSString * const PBJVisionCaptureStillImageIsCapturingStillImageObserverContext = @"PBJVisionCaptureStillImageIsCapturingStillImageObserverContext";

// photo dictionary key definitions

NSString * const PBJVisionPhotoMetadataKey = @"PBJVisionPhotoMetadataKey";
NSString * const PBJVisionPhotoJPEGKey = @"PBJVisionPhotoJPEGKey";
NSString * const PBJVisionPhotoImageKey = @"PBJVisionPhotoImageKey";
NSString * const PBJVisionPhotoThumbnailKey = @"PBJVisionPhotoThumbnailKey";

// video dictionary key definitions

NSString * const PBJVisionVideoPathKey = @"PBJVisionVideoPathKey";
NSString * const PBJVisionVideoThumbnailKey = @"PBJVisionVideoThumbnailKey";
NSString * const PBJVisionVideoThumbnailArrayKey = @"PBJVisionVideoThumbnailArrayKey";
NSString * const PBJVisionVideoCapturedDurationKey = @"PBJVisionVideoCapturedDurationKey";

// PBJGLProgram shader uniforms for pixel format conversion on the GPU
typedef NS_ENUM(GLint, PBJVisionUniformLocationTypes)
{
    PBJVisionUniformY,
    PBJVisionUniformUV,
    PBJVisionUniformCount
};

///

@interface PBJVision () <
    AVCaptureAudioDataOutputSampleBufferDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    PBJMediaWriterDelegate>
{
    // AV

    AVCaptureSession *_captureSession;
    
    AVCaptureDevice *_captureDeviceFront;
    AVCaptureDevice *_captureDeviceBack;
    AVCaptureDevice *_captureDeviceAudio;
    
    AVCaptureDeviceInput *_captureDeviceInputFront;
    AVCaptureDeviceInput *_captureDeviceInputBack;
    AVCaptureDeviceInput *_captureDeviceInputAudio;

    AVCaptureStillImageOutput *_captureOutputPhoto;
    AVCaptureAudioDataOutput *_captureOutputAudio;
    AVCaptureVideoDataOutput *_captureOutputVideo;

    // vision core

    PBJMediaWriter *_mediaWriter;

    dispatch_queue_t _captureSessionDispatchQueue;
    dispatch_queue_t _captureCaptureDispatchQueue;

    PBJCameraDevice _cameraDevice;
    PBJCameraMode _cameraMode;
    PBJCameraOrientation _cameraOrientation;

    PBJCameraOrientation _previewOrientation;
    BOOL _autoUpdatePreviewOrientation;
    BOOL _autoFreezePreviewDuringCapture;
    BOOL _usesApplicationAudioSession;

    PBJFocusMode _focusMode;
    PBJExposureMode _exposureMode;
    PBJFlashMode _flashMode;
    PBJMirroringMode _mirroringMode;

    NSString *_captureSessionPreset;
    NSString *_captureDirectory;
    PBJOutputFormat _outputFormat;
    NSMutableSet* _captureThumbnailTimes;
    NSMutableSet* _captureThumbnailFrames;
    
    CGFloat _videoBitRate;
    NSInteger _audioBitRate;
    NSInteger _videoFrameRate;
    NSDictionary *_additionalCompressionProperties;
    
    AVCaptureDevice *_currentDevice;
    AVCaptureDeviceInput *_currentInput;
    AVCaptureOutput *_currentOutput;
    
    AVCaptureVideoPreviewLayer *_previewLayer;
    CGRect _cleanAperture;

    CMTime _startTimestamp;
    CMTime _timeOffset;
    CMTime _maximumCaptureDuration;

    // sample buffer rendering

    PBJCameraDevice _bufferDevice;
    PBJCameraOrientation _bufferOrientation;
    size_t _bufferWidth;
    size_t _bufferHeight;
    CGRect _presentationFrame;

    EAGLContext *_context;
    PBJGLProgram *_program;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    CIContext *_ciContext;
    
    // flags
    
    struct {
        unsigned int previewRunning:1;
        unsigned int changingModes:1;
        unsigned int recording:1;
        unsigned int paused:1;
        unsigned int interrupted:1;
        unsigned int videoWritten:1;
        unsigned int videoRenderingEnabled:1;
        unsigned int audioCaptureEnabled:1;
        unsigned int thumbnailEnabled:1;
        unsigned int defaultVideoThumbnails:1;
        unsigned int videoCaptureFrame:1;
    } __block _flags;
}

@property (nonatomic) AVCaptureDevice *currentDevice;

@end

@implementation PBJVision

@synthesize delegate = _delegate;
@synthesize currentDevice = _currentDevice;
@synthesize previewLayer = _previewLayer;
@synthesize cleanAperture = _cleanAperture;
@synthesize cameraOrientation = _cameraOrientation;
@synthesize previewOrientation = _previewOrientation;
@synthesize autoUpdatePreviewOrientation = _autoUpdatePreviewOrientation;
@synthesize autoFreezePreviewDuringCapture = _autoFreezePreviewDuringCapture;
@synthesize usesApplicationAudioSession = _usesApplicationAudioSession;
@synthesize cameraDevice = _cameraDevice;
@synthesize cameraMode = _cameraMode;
@synthesize focusMode = _focusMode;
@synthesize exposureMode = _exposureMode;
@synthesize flashMode = _flashMode;
@synthesize mirroringMode = _mirroringMode;
@synthesize outputFormat = _outputFormat;
@synthesize context = _context;
@synthesize presentationFrame = _presentationFrame;
@synthesize captureSessionPreset = _captureSessionPreset;
@synthesize captureDirectory = _captureDirectory;
@synthesize audioBitRate = _audioBitRate;
@synthesize videoBitRate = _videoBitRate;
@synthesize additionalCompressionProperties = _additionalCompressionProperties;
@synthesize maximumCaptureDuration = _maximumCaptureDuration;

#pragma mark - singleton

+ (PBJVision *)sharedInstance
{
    static PBJVision *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[PBJVision alloc] init];
    });
    return singleton;
}

#pragma mark - getters/setters

- (BOOL)isCaptureSessionActive
{
    return ([_captureSession isRunning]);
}

- (BOOL)isRecording
{
    return _flags.recording;
}

- (BOOL)isPaused
{
    return _flags.paused;
}

- (void)setVideoRenderingEnabled:(BOOL)videoRenderingEnabled
{
    _flags.videoRenderingEnabled = (unsigned int)videoRenderingEnabled;
}

- (BOOL)isVideoRenderingEnabled
{
    return _flags.videoRenderingEnabled;
}

- (void)setAudioCaptureEnabled:(BOOL)audioCaptureEnabled
{
    _flags.audioCaptureEnabled = (unsigned int)audioCaptureEnabled;
}

- (BOOL)isAudioCaptureEnabled
{
    return _flags.audioCaptureEnabled;
}

- (void)setThumbnailEnabled:(BOOL)thumbnailEnabled
{
    _flags.thumbnailEnabled = (unsigned int)thumbnailEnabled;
}

- (BOOL)thumbnailEnabled
{
    return _flags.thumbnailEnabled;
}

- (void)setDefaultVideoThumbnails:(BOOL)defaultVideoThumbnails
{
    _flags.defaultVideoThumbnails = (unsigned int)defaultVideoThumbnails;
}

- (BOOL)defaultVideoThumbnails
{
    return _flags.defaultVideoThumbnails;
}

- (Float64)capturedAudioSeconds
{
    if (_mediaWriter && CMTIME_IS_VALID(_mediaWriter.audioTimestamp)) {
        return CMTimeGetSeconds(CMTimeSubtract(_mediaWriter.audioTimestamp, _startTimestamp));
    } else {
        return 0.0;
    }
}

- (Float64)capturedVideoSeconds
{
    if (_mediaWriter && CMTIME_IS_VALID(_mediaWriter.videoTimestamp)) {
        return CMTimeGetSeconds(CMTimeSubtract(_mediaWriter.videoTimestamp, _startTimestamp));
    } else {
        return 0.0;
    }
}

- (void)setCameraOrientation:(PBJCameraOrientation)cameraOrientation
{
    if (cameraOrientation == _cameraOrientation)
        return;
    _cameraOrientation = cameraOrientation;

    if (self.autoUpdatePreviewOrientation) {
        [self setPreviewOrientation:cameraOrientation];
    }
}

- (void)setPreviewOrientation:(PBJCameraOrientation)previewOrientation {
    if (previewOrientation == _previewOrientation)
        return;

    if ([_previewLayer.connection isVideoOrientationSupported]) {
        _previewOrientation = previewOrientation;
        [self _setOrientationForConnection:_previewLayer.connection];
    }
}

- (void)_setOrientationForConnection:(AVCaptureConnection *)connection
{
    if (!connection || ![connection isVideoOrientationSupported])
        return;

    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
    switch (_cameraOrientation) {
        case PBJCameraOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case PBJCameraOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case PBJCameraOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case PBJCameraOrientationPortrait:
        default:
            break;
    }

    [connection setVideoOrientation:orientation];
}

- (void)_setCameraMode:(PBJCameraMode)cameraMode cameraDevice:(PBJCameraDevice)cameraDevice outputFormat:(PBJOutputFormat)outputFormat
{
    BOOL changeDevice = (_cameraDevice != cameraDevice);
    BOOL changeMode = (_cameraMode != cameraMode);
    BOOL changeOutputFormat = (_outputFormat != outputFormat);
    
    DLog(@"change device (%d) mode (%d) format (%d)", changeDevice, changeMode, changeOutputFormat);
    
    if (!changeMode && !changeDevice && !changeOutputFormat) {
        return;
    }

    if (changeDevice && [_delegate respondsToSelector:@selector(visionCameraDeviceWillChange:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_delegate performSelector:@selector(visionCameraDeviceWillChange:) withObject:self];
#pragma clang diagnostic pop
    }
    if (changeMode && [_delegate respondsToSelector:@selector(visionCameraModeWillChange:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_delegate performSelector:@selector(visionCameraModeWillChange:) withObject:self];
#pragma clang diagnostic pop
    }
    if (changeOutputFormat && [_delegate respondsToSelector:@selector(visionOutputFormatWillChange:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_delegate performSelector:@selector(visionOutputFormatWillChange:) withObject:self];
#pragma clang diagnostic pop
    }
    
    _flags.changingModes = YES;
    
    _cameraDevice = cameraDevice;
    _cameraMode = cameraMode;
    _outputFormat = outputFormat;

    PBJVisionBlock didChangeBlock = ^{
        _flags.changingModes = NO;
            
        if (changeDevice && [_delegate respondsToSelector:@selector(visionCameraDeviceDidChange:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [_delegate performSelector:@selector(visionCameraDeviceDidChange:) withObject:self];
#pragma clang diagnostic pop
        }
        if (changeMode && [_delegate respondsToSelector:@selector(visionCameraModeDidChange:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [_delegate performSelector:@selector(visionCameraModeDidChange:) withObject:self];
#pragma clang diagnostic pop
        }
        if (changeOutputFormat && [_delegate respondsToSelector:@selector(visionOutputFormatDidChange:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [_delegate performSelector:@selector(visionOutputFormatDidChange:) withObject:self];
#pragma clang diagnostic pop
        }
    };

    // since there is no session in progress, set and bail
    if (!_captureSession) {
        _flags.changingModes = NO;
            
        didChangeBlock();
        
        return;
    }
    
    [self _enqueueBlockOnCaptureSessionQueue:^{
        // camera is already setup, no need to call _setupCamera
        [self _setupSession];

        [self setMirroringMode:_mirroringMode];
        
        [self _enqueueBlockOnMainQueue:didChangeBlock];
    }];
}

- (void)setCameraDevice:(PBJCameraDevice)cameraDevice
{
    [self _setCameraMode:_cameraMode cameraDevice:cameraDevice outputFormat:_outputFormat];
}

- (void)setCaptureSessionPreset:(NSString *)captureSessionPreset
{
    _captureSessionPreset = captureSessionPreset;
    if ([_captureSession canSetSessionPreset:captureSessionPreset]){
        [self _commitBlock:^{
            [_captureSession setSessionPreset:captureSessionPreset];
        }];
    }
}

- (void)setCameraMode:(PBJCameraMode)cameraMode
{
    [self _setCameraMode:cameraMode cameraDevice:_cameraDevice outputFormat:_outputFormat];
}

- (void)setOutputFormat:(PBJOutputFormat)outputFormat
{
    [self _setCameraMode:_cameraMode cameraDevice:_cameraDevice outputFormat:outputFormat];
}

- (BOOL)isCameraDeviceAvailable:(PBJCameraDevice)cameraDevice
{
    return [UIImagePickerController isCameraDeviceAvailable:(UIImagePickerControllerCameraDevice)cameraDevice];
}

- (BOOL)isFocusPointOfInterestSupported
{
    return [_currentDevice isFocusPointOfInterestSupported];
}

- (BOOL)isFocusLockSupported
{
    return [_currentDevice isFocusModeSupported:AVCaptureFocusModeLocked];
}

- (void)setFocusMode:(PBJFocusMode)focusMode
{
    BOOL shouldChangeFocusMode = (_focusMode != focusMode);
    if (![_currentDevice isFocusModeSupported:(AVCaptureFocusMode)focusMode] || !shouldChangeFocusMode)
        return;
    
    _focusMode = focusMode;
    
    NSError *error = nil;
    if (_currentDevice && [_currentDevice lockForConfiguration:&error]) {
        [_currentDevice setFocusMode:(AVCaptureFocusMode)focusMode];
        [_currentDevice unlockForConfiguration];
    } else if (error) {
        DLog(@"error locking device for focus mode change (%@)", error);
    }
}

- (BOOL)isExposureLockSupported
{
    return [_currentDevice isExposureModeSupported:AVCaptureExposureModeLocked];
}

- (void)setExposureMode:(PBJExposureMode)exposureMode
{
    BOOL shouldChangeExposureMode = (_exposureMode != exposureMode);
    if (![_currentDevice isExposureModeSupported:(AVCaptureExposureMode)exposureMode] || !shouldChangeExposureMode)
        return;
    
    _exposureMode = exposureMode;
    
    NSError *error = nil;
    if (_currentDevice && [_currentDevice lockForConfiguration:&error]) {
        [_currentDevice setExposureMode:(AVCaptureExposureMode)exposureMode];
        [_currentDevice unlockForConfiguration];
    } else if (error) {
        DLog(@"error locking device for exposure mode change (%@)", error);
    }

}

- (void) _setCurrentDevice:(AVCaptureDevice *)device
{
    _currentDevice  = device;
    _exposureMode   = (PBJExposureMode)device.exposureMode;
    _focusMode      = (PBJFocusMode)device.focusMode;
}

- (BOOL)isFlashAvailable
{
    return (_currentDevice && [_currentDevice hasFlash]);
}

- (void)setFlashMode:(PBJFlashMode)flashMode
{
    BOOL shouldChangeFlashMode = (_flashMode != flashMode);
    if (![_currentDevice hasFlash] || !shouldChangeFlashMode)
        return;

    _flashMode = flashMode;
    
    NSError *error = nil;
    if (_currentDevice && [_currentDevice lockForConfiguration:&error]) {
        
        switch (_cameraMode) {
          case PBJCameraModePhoto:
          {
            if ([_currentDevice isFlashModeSupported:(AVCaptureFlashMode)_flashMode]) {
                [_currentDevice setFlashMode:(AVCaptureFlashMode)_flashMode];
            }
            break;
          }
          case PBJCameraModeVideo:
          {
            if ([_currentDevice isFlashModeSupported:(AVCaptureFlashMode)_flashMode]) {
                [_currentDevice setFlashMode:AVCaptureFlashModeOff];
            }
            
            if ([_currentDevice isTorchModeSupported:(AVCaptureTorchMode)_flashMode]) {
                [_currentDevice setTorchMode:(AVCaptureTorchMode)_flashMode];
            }
            break;
          }
          default:
            break;
        }
    
        [_currentDevice unlockForConfiguration];
    
    } else if (error) {
        DLog(@"error locking device for flash mode change (%@)", error);
    }
}

// framerate

- (void)setVideoFrameRate:(NSInteger)videoFrameRate
{
    if (![self supportsVideoFrameRate:videoFrameRate]) {
        DLog(@"frame rate range not supported for current device format");
        return;
    }
    
    BOOL isRecording = _flags.recording;
    if (isRecording) {
        [self pauseVideoCapture];
    }

    CMTime fps = CMTimeMake(1, (int32_t)videoFrameRate);

    AVCaptureDevice *videoDevice = _currentDevice;
    AVCaptureDeviceFormat *supportingFormat = nil;
    int32_t maxWidth = 0;

    NSArray *formats = [videoDevice formats];
    for (AVCaptureDeviceFormat *format in formats) {
        NSArray *videoSupportedFrameRateRanges = format.videoSupportedFrameRateRanges;
        for (AVFrameRateRange *range in videoSupportedFrameRateRanges) {

            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            if (range.minFrameRate <= videoFrameRate && videoFrameRate <= range.maxFrameRate && width >= maxWidth) {
                supportingFormat = format;
                maxWidth = width;
            }
            
        }
    }
    
    if (supportingFormat) {
        NSError *error = nil;
        [_captureSession beginConfiguration];  // the session to which the receiver's AVCaptureDeviceInput is added.
        if ([_currentDevice lockForConfiguration:&error]) {
            [_currentDevice setActiveFormat:supportingFormat];
            _currentDevice.activeVideoMinFrameDuration = fps;
            _currentDevice.activeVideoMaxFrameDuration = fps;
            _videoFrameRate = videoFrameRate;
            [_currentDevice unlockForConfiguration];
        } else if (error) {
            DLog(@"error locking device for frame rate change (%@)", error);
        }
    }
    [_captureSession commitConfiguration];
    [self _enqueueBlockOnMainQueue:^{
        if ([_delegate respondsToSelector:@selector(visionDidChangeVideoFormatAndFrameRate:)])
            [_delegate visionDidChangeVideoFormatAndFrameRate:self];
    }];

    if (isRecording) {
        [self resumeVideoCapture];
    }
}

- (NSInteger)videoFrameRate
{
    if (!_currentDevice)
        return 0;

	return _currentDevice.activeVideoMaxFrameDuration.timescale;
}

- (BOOL)supportsVideoFrameRate:(NSInteger)videoFrameRate
{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        AVCaptureDevice *videoDevice = nil;
        NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        NSPredicate *predicate = nil;
        if (self.cameraDevice == PBJCameraDeviceBack) {
            predicate = [NSPredicate predicateWithFormat:@"position == %i", AVCaptureDevicePositionBack];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"position == %i", AVCaptureDevicePositionFront];
        }
        NSArray *filteredDevices = [videoDevices filteredArrayUsingPredicate:predicate];
        if (filteredDevices.count > 0) {
            videoDevice = filteredDevices.firstObject;
        } else {
            return NO;
        }
        NSArray *formats = [videoDevice formats];
        for (AVCaptureDeviceFormat *format in formats) {
            NSArray *videoSupportedFrameRateRanges = [format videoSupportedFrameRateRanges];
            for (AVFrameRateRange *frameRateRange in videoSupportedFrameRateRanges) {
                if ( (frameRateRange.minFrameRate <= videoFrameRate) && (videoFrameRate <= frameRateRange.maxFrameRate) ) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

#pragma mark - init

- (id)init
{
    self = [super init];
    if (self) {
        
        // setup GLES
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!_context) {
            DLog(@"failed to create GL context");
        }
        [self _setupGL];
        
        _captureSessionPreset = AVCaptureSessionPresetMedium;
        _captureDirectory = nil;

        _autoUpdatePreviewOrientation = YES;
        _autoFreezePreviewDuringCapture = YES;
        _usesApplicationAudioSession = NO;

        // Average bytes per second based on video dimensions
        // lower the bitRate, higher the compression
        _videoBitRate = PBJVideoBitRate640x480;

        // default audio/video configuration
        _audioBitRate = 64000;
        
        // default flags
        _flags.thumbnailEnabled = YES;
        _flags.defaultVideoThumbnails = YES;
        _flags.audioCaptureEnabled = YES;

        // setup queues
        _captureSessionDispatchQueue = dispatch_queue_create("PBJVisionSession", DISPATCH_QUEUE_SERIAL); // protects session
        _captureCaptureDispatchQueue = dispatch_queue_create("PBJVisionCapture", DISPATCH_QUEUE_SERIAL); // protects capture
        
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:nil];
        
        _maximumCaptureDuration = kCMTimeInvalid;

        [self setMirroringMode:PBJMirroringAuto];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _delegate = nil;

    [self _cleanUpTextures];
    
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    
    [self _destroyGL];
    [self _destroyCamera];
}

#pragma mark - queue helper methods

typedef void (^PBJVisionBlock)();

- (void)_enqueueBlockOnCaptureSessionQueue:(PBJVisionBlock)block
{
    dispatch_async(_captureSessionDispatchQueue, ^{
        block();
    });
}

- (void)_enqueueBlockOnCaptureVideoQueue:(PBJVisionBlock)block
{
    dispatch_async(_captureCaptureDispatchQueue, ^{
        block();
    });
}

- (void)_enqueueBlockOnMainQueue:(PBJVisionBlock)block
{
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

- (void)_executeBlockOnMainQueue:(PBJVisionBlock)block
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        block();
    });
}

- (void)_commitBlock:(PBJVisionBlock)block
{
    [_captureSession beginConfiguration];
    block();
    [_captureSession commitConfiguration];
}

#pragma mark - camera

// only call from the session queue
- (void)_setupCamera
{
    if (_captureSession)
        return;
    
#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
    CVReturn cvError = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
#else
    CVReturn cvError = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)_context, NULL, &_videoTextureCache);
#endif
    if (cvError) {
        NSLog(@"error CVOpenGLESTextureCacheCreate (%d)", cvError);
    }

    // create session
    _captureSession = [[AVCaptureSession alloc] init];

    if (_usesApplicationAudioSession) {
        _captureSession.usesApplicationAudioSession = YES;
    }

    // capture devices
    _captureDeviceFront = [PBJVisionUtilities captureDeviceForPosition:AVCaptureDevicePositionFront];
    _captureDeviceBack = [PBJVisionUtilities captureDeviceForPosition:AVCaptureDevicePositionBack];

    // capture device inputs
    NSError *error = nil;
    _captureDeviceInputFront = [AVCaptureDeviceInput deviceInputWithDevice:_captureDeviceFront error:&error];
    if (error) {
        DLog(@"error setting up front camera input (%@)", error);
        error = nil;
    }
    
    _captureDeviceInputBack = [AVCaptureDeviceInput deviceInputWithDevice:_captureDeviceBack error:&error];
    if (error) {
        DLog(@"error setting up back camera input (%@)", error);
        error = nil;
    }
    
    if (_cameraMode != PBJCameraModePhoto && _flags.audioCaptureEnabled) {
        _captureDeviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        _captureDeviceInputAudio = [AVCaptureDeviceInput deviceInputWithDevice:_captureDeviceAudio error:&error];

        if (error) {
            DLog(@"error setting up audio input (%@)", error);
        }
    }
    
    // capture device ouputs
    _captureOutputPhoto = [[AVCaptureStillImageOutput alloc] init];
    if (_cameraMode != PBJCameraModePhoto && _flags.audioCaptureEnabled) {
    	_captureOutputAudio = [[AVCaptureAudioDataOutput alloc] init];
    }
    _captureOutputVideo = [[AVCaptureVideoDataOutput alloc] init];
    
    if (_cameraMode != PBJCameraModePhoto && _flags.audioCaptureEnabled) {
    	[_captureOutputAudio setSampleBufferDelegate:self queue:_captureCaptureDispatchQueue];
    }
    [_captureOutputVideo setSampleBufferDelegate:self queue:_captureCaptureDispatchQueue];

    // capture device initial settings
    _videoFrameRate = 30;

    // add notification observers
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // session notifications
    [notificationCenter addObserver:self selector:@selector(_sessionRuntimeErrored:) name:AVCaptureSessionRuntimeErrorNotification object:_captureSession];
    [notificationCenter addObserver:self selector:@selector(_sessionStarted:) name:AVCaptureSessionDidStartRunningNotification object:_captureSession];
    [notificationCenter addObserver:self selector:@selector(_sessionStopped:) name:AVCaptureSessionDidStopRunningNotification object:_captureSession];
    [notificationCenter addObserver:self selector:@selector(_sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:_captureSession];
    [notificationCenter addObserver:self selector:@selector(_sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:_captureSession];
    
    // capture input notifications
    [notificationCenter addObserver:self selector:@selector(_inputPortFormatDescriptionDidChange:) name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
    
    // capture device notifications
    [notificationCenter addObserver:self selector:@selector(_deviceSubjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];

    // current device KVO notifications
    [self addObserver:self forKeyPath:@"currentDevice.adjustingFocus" options:NSKeyValueObservingOptionNew context:(__bridge void *)PBJVisionFocusObserverContext];
    [self addObserver:self forKeyPath:@"currentDevice.adjustingExposure" options:NSKeyValueObservingOptionNew context:(__bridge void *)PBJVisionExposureObserverContext];
    [self addObserver:self forKeyPath:@"currentDevice.adjustingWhiteBalance" options:NSKeyValueObservingOptionNew context:(__bridge void *)PBJVisionWhiteBalanceObserverContext];
    [self addObserver:self forKeyPath:@"currentDevice.flashMode" options:NSKeyValueObservingOptionNew context:(__bridge void *)PBJVisionFlashModeObserverContext];
    [self addObserver:self forKeyPath:@"currentDevice.torchMode" options:NSKeyValueObservingOptionNew context:(__bridge void *)PBJVisionTorchModeObserverContext];
    [self addObserver:self forKeyPath:@"currentDevice.flashAvailable" options:NSKeyValueObservingOptionNew context:(__bridge void *)PBJVisionFlashAvailabilityObserverContext];
    [self addObserver:self forKeyPath:@"currentDevice.torchAvailable" options:NSKeyValueObservingOptionNew context:(__bridge void *)PBJVisionTorchAvailabilityObserverContext];

    // KVO is only used to monitor focus and capture events
    [_captureOutputPhoto addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(PBJVisionCaptureStillImageIsCapturingStillImageObserverContext)];
    
    DLog(@"camera setup");
}

// only call from the session queue
- (void)_destroyCamera
{
    if (!_captureSession)
        return;
    
    // current device KVO notifications
    [self removeObserver:self forKeyPath:@"currentDevice.adjustingFocus"];
    [self removeObserver:self forKeyPath:@"currentDevice.adjustingExposure"];
    [self removeObserver:self forKeyPath:@"currentDevice.adjustingWhiteBalance"];
    [self removeObserver:self forKeyPath:@"currentDevice.flashMode"];
    [self removeObserver:self forKeyPath:@"currentDevice.torchMode"];
    [self removeObserver:self forKeyPath:@"currentDevice.flashAvailable"];
    [self removeObserver:self forKeyPath:@"currentDevice.torchAvailable"];
    
    // capture events KVO notifications
    [_captureOutputPhoto removeObserver:self forKeyPath:@"capturingStillImage"];

    // remove notification observers (we don't want to just 'remove all' because we're also observing background notifications
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    // session notifications
    [notificationCenter removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:_captureSession];
    [notificationCenter removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:_captureSession];
    [notificationCenter removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:_captureSession];
    [notificationCenter removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:_captureSession];
    [notificationCenter removeObserver:self name:AVCaptureSessionInterruptionEndedNotification object:_captureSession];
    
    // capture input notifications
    [notificationCenter removeObserver:self name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
    
    // capture device notifications
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];

    _captureOutputPhoto = nil;
    _captureOutputAudio = nil;
    _captureOutputVideo = nil;
    
    _captureDeviceAudio = nil;
    _captureDeviceInputAudio = nil;
    _captureDeviceInputFront = nil;
    _captureDeviceInputBack = nil;
    _captureDeviceFront = nil;
    _captureDeviceBack = nil;

    _captureSession = nil;
    _currentDevice = nil;
    _currentInput = nil;
    _currentOutput = nil;
    
    DLog(@"camera destroyed");
}

#pragma mark - AVCaptureSession

- (BOOL)_canSessionCaptureWithOutput:(AVCaptureOutput *)captureOutput
{
    BOOL sessionContainsOutput = [[_captureSession outputs] containsObject:captureOutput];
    BOOL outputHasConnection = ([captureOutput connectionWithMediaType:AVMediaTypeVideo] != nil);
    return (sessionContainsOutput && outputHasConnection);
}

// _setupSession is always called from the captureSession queue
- (void)_setupSession
{
    if (!_captureSession) {
        DLog(@"error, no session running to setup");
        return;
    }
    
    BOOL shouldSwitchDevice = (_currentDevice == nil) ||
                              ((_currentDevice == _captureDeviceFront) && (_cameraDevice != PBJCameraDeviceFront)) ||
                              ((_currentDevice == _captureDeviceBack) && (_cameraDevice != PBJCameraDeviceBack));
    
    BOOL shouldSwitchMode = (_currentOutput == nil) ||
                            ((_currentOutput == _captureOutputPhoto) && (_cameraMode != PBJCameraModePhoto)) ||
                            ((_currentOutput == _captureOutputVideo) && (_cameraMode != PBJCameraModeVideo));
    
    DLog(@"switchDevice %d switchMode %d", shouldSwitchDevice, shouldSwitchMode);

    if (!shouldSwitchDevice && !shouldSwitchMode)
        return;
    
    AVCaptureDeviceInput *newDeviceInput = nil;
    AVCaptureOutput *newCaptureOutput = nil;
    AVCaptureDevice *newCaptureDevice = nil;
    
    [_captureSession beginConfiguration];
    
    // setup session device
    
    if (shouldSwitchDevice) {
        switch (_cameraDevice) {
          case PBJCameraDeviceFront:
          {
            if (_captureDeviceInputBack)
                [_captureSession removeInput:_captureDeviceInputBack];
            
            if (_captureDeviceInputFront && [_captureSession canAddInput:_captureDeviceInputFront]) {
                [_captureSession addInput:_captureDeviceInputFront];
                newDeviceInput = _captureDeviceInputFront;
                newCaptureDevice = _captureDeviceFront;
            }
            break;
          }
          case PBJCameraDeviceBack:
          {
            if (_captureDeviceInputFront)
                [_captureSession removeInput:_captureDeviceInputFront];
            
            if (_captureDeviceInputBack && [_captureSession canAddInput:_captureDeviceInputBack]) {
                [_captureSession addInput:_captureDeviceInputBack];
                newDeviceInput = _captureDeviceInputBack;
                newCaptureDevice = _captureDeviceBack;
            }
            break;
          }
          default:
            break;
        }
        
    } // shouldSwitchDevice
    
    // setup session input/output
    
    if (shouldSwitchMode) {
    
        // disable audio when in use for photos, otherwise enable it
        
    	if (self.cameraMode == PBJCameraModePhoto) {
            if (_captureDeviceInputAudio)
                [_captureSession removeInput:_captureDeviceInputAudio];
            
            if (_captureOutputAudio)
                [_captureSession removeOutput:_captureOutputAudio];
    	
        } else if (!_captureDeviceAudio && !_captureDeviceInputAudio && !_captureOutputAudio &&  _flags.audioCaptureEnabled) {
        
            NSError *error = nil;
            _captureDeviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            _captureDeviceInputAudio = [AVCaptureDeviceInput deviceInputWithDevice:_captureDeviceAudio error:&error];
            if (error) {
                DLog(@"error setting up audio input (%@)", error);
            }

            _captureOutputAudio = [[AVCaptureAudioDataOutput alloc] init];
            [_captureOutputAudio setSampleBufferDelegate:self queue:_captureCaptureDispatchQueue];
            
        }
        
        [_captureSession removeOutput:_captureOutputVideo];
        [_captureSession removeOutput:_captureOutputPhoto];
        
        switch (_cameraMode) {
            case PBJCameraModeVideo:
            {
                // audio input
                if ([_captureSession canAddInput:_captureDeviceInputAudio]) {
                    [_captureSession addInput:_captureDeviceInputAudio];
                }
                // audio output
                if ([_captureSession canAddOutput:_captureOutputAudio]) {
                    [_captureSession addOutput:_captureOutputAudio];
                }
                // vidja output
                if ([_captureSession canAddOutput:_captureOutputVideo]) {
                    [_captureSession addOutput:_captureOutputVideo];
                    newCaptureOutput = _captureOutputVideo;
                }
                break;
            }
            case PBJCameraModePhoto:
            {
                // photo output
                if ([_captureSession canAddOutput:_captureOutputPhoto]) {
                    [_captureSession addOutput:_captureOutputPhoto];
                    newCaptureOutput = _captureOutputPhoto;
                }
                break;
            }
            default:
                break;
        }
        
    } // shouldSwitchMode
    
    if (!newCaptureDevice)
        newCaptureDevice = _currentDevice;

    if (!newCaptureOutput)
        newCaptureOutput = _currentOutput;

    // setup video connection
    AVCaptureConnection *videoConnection = [_captureOutputVideo connectionWithMediaType:AVMediaTypeVideo];
    
    // setup input/output
    
    NSString *sessionPreset = _captureSessionPreset;

    if ( newCaptureOutput && (newCaptureOutput == _captureOutputVideo) && videoConnection ) {
        
        // setup video orientation
        [self _setOrientationForConnection:videoConnection];
        
        // setup video stabilization, if available
        if ([videoConnection isVideoStabilizationSupported]) {
            if ([videoConnection respondsToSelector:@selector(setPreferredVideoStabilizationMode:)]) {
                [videoConnection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
            } else {
                [videoConnection setEnablesVideoStabilizationWhenAvailable:YES];
            }
        }
        
        // discard late frames
        [_captureOutputVideo setAlwaysDiscardsLateVideoFrames:YES];
        
        // specify video preset
        sessionPreset = _captureSessionPreset;

        // setup video settings
        // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range (luma=[0,255] chroma=[1,255])
        // baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct
        BOOL supportsFullRangeYUV = NO;
        BOOL supportsVideoRangeYUV = NO;
        NSArray *supportedPixelFormats = _captureOutputVideo.availableVideoCVPixelFormatTypes;
        for (NSNumber *currentPixelFormat in supportedPixelFormats) {
            if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
                supportsFullRangeYUV = YES;
            }
            if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
                supportsVideoRangeYUV = YES;
            }
        }

        NSDictionary *videoSettings = nil;
        if (supportsFullRangeYUV) {
            videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) };
        } else if (supportsVideoRangeYUV) {
            videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) };
        }
        if (videoSettings) {
            [_captureOutputVideo setVideoSettings:videoSettings];
        }
        
        // setup video device configuration
        NSError *error = nil;
        if ([newCaptureDevice lockForConfiguration:&error]) {
        
            // smooth autofocus for videos
            if ([newCaptureDevice isSmoothAutoFocusSupported])
                [newCaptureDevice setSmoothAutoFocusEnabled:YES];
            
            [newCaptureDevice unlockForConfiguration];
    
        } else if (error) {
            DLog(@"error locking device for video device configuration (%@)", error);
        }
        
    } else if ( newCaptureOutput && (newCaptureOutput == _captureOutputPhoto) ) {
    
        // specify photo preset
        sessionPreset = AVCaptureSessionPresetPhoto;
    
        // setup photo settings
        NSDictionary *photoSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
        [_captureOutputPhoto setOutputSettings:photoSettings];
        
        // setup photo device configuration
        NSError *error = nil;
        if ([newCaptureDevice lockForConfiguration:&error]) {
            
            if ([newCaptureDevice isLowLightBoostSupported])
                [newCaptureDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
            
            [newCaptureDevice unlockForConfiguration];
        
        } else if (error) {
            DLog(@"error locking device for photo device configuration (%@)", error);
        }
            
    }

    // apply presets
    if ([_captureSession canSetSessionPreset:sessionPreset])
        [_captureSession setSessionPreset:sessionPreset];

    if (newDeviceInput)
        _currentInput = newDeviceInput;
    
    if (newCaptureOutput)
        _currentOutput = newCaptureOutput;

    // ensure there is a capture device setup
    if (_currentInput) {
        AVCaptureDevice *device = [_currentInput device];
        if (device) {
            [self willChangeValueForKey:@"currentDevice"];
            [self _setCurrentDevice:device];
            [self didChangeValueForKey:@"currentDevice"];
        }
    }

    [_captureSession commitConfiguration];
    
    DLog(@"capture session setup");
}

#pragma mark - preview

- (void)startPreview
{
    [self _enqueueBlockOnCaptureSessionQueue:^{
        if (!_captureSession) {
            [self _setupCamera];
            [self _setupSession];
        }

        [self setMirroringMode:_mirroringMode];
    
        if (_previewLayer && _previewLayer.session != _captureSession) {
            _previewLayer.session = _captureSession;
            [self _setOrientationForConnection:_previewLayer.connection];
        }
        
        if (_previewLayer)
            _previewLayer.connection.enabled = YES;
        
        if (![_captureSession isRunning]) {
            [_captureSession startRunning];
            
            [self _enqueueBlockOnMainQueue:^{
                if ([_delegate respondsToSelector:@selector(visionSessionDidStartPreview:)]) {
                    [_delegate visionSessionDidStartPreview:self];
                }
            }];
            DLog(@"capture session running");
        }
        _flags.previewRunning = YES;
    }];
}

- (void)stopPreview
{    
    [self _enqueueBlockOnCaptureSessionQueue:^{
        if (!_flags.previewRunning)
            return;

        if (_previewLayer)
            _previewLayer.connection.enabled = NO;

        if ([_captureSession isRunning])
            [_captureSession stopRunning];

        [self _executeBlockOnMainQueue:^{
            if ([_delegate respondsToSelector:@selector(visionSessionDidStopPreview:)]) {
                [_delegate visionSessionDidStopPreview:self];
            }
        }];
        DLog(@"capture session stopped");
        _flags.previewRunning = NO;
    }];
}

- (void)freezePreview
{
    if (_previewLayer)
        _previewLayer.connection.enabled = NO;
}

- (void)unfreezePreview
{
    if (_previewLayer)
        _previewLayer.connection.enabled = YES;
}

#pragma mark - focus, exposure, white balance

- (void)_focusStarted
{
//    DLog(@"focus started");
    if ([_delegate respondsToSelector:@selector(visionWillStartFocus:)])
        [_delegate visionWillStartFocus:self];
}

- (void)_focusEnded
{
    AVCaptureFocusMode focusMode = [_currentDevice focusMode];
    BOOL isFocusing = [_currentDevice isAdjustingFocus];
    BOOL isAutoFocusEnabled = (focusMode == AVCaptureFocusModeAutoFocus ||
                               focusMode == AVCaptureFocusModeContinuousAutoFocus);
    if (!isFocusing && isAutoFocusEnabled) {
        NSError *error = nil;
        if ([_currentDevice lockForConfiguration:&error]) {
        
            [_currentDevice setSubjectAreaChangeMonitoringEnabled:YES];
            [_currentDevice unlockForConfiguration];
            
        } else if (error) {
            DLog(@"error locking device post exposure for subject area change monitoring (%@)", error);
        }
    }

    if ([_delegate respondsToSelector:@selector(visionDidStopFocus:)])
        [_delegate visionDidStopFocus:self];
//    DLog(@"focus ended");
}

- (void)_exposureChangeStarted
{
    //    DLog(@"exposure change started");
    if ([_delegate respondsToSelector:@selector(visionWillChangeExposure:)])
        [_delegate visionWillChangeExposure:self];
}

- (void)_exposureChangeEnded
{
    BOOL isContinuousAutoExposureEnabled = [_currentDevice exposureMode] == AVCaptureExposureModeContinuousAutoExposure;
    BOOL isExposing = [_currentDevice isAdjustingExposure];
    BOOL isFocusSupported = [_currentDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];

    if (isContinuousAutoExposureEnabled && !isExposing && !isFocusSupported) {

        NSError *error = nil;
        if ([_currentDevice lockForConfiguration:&error]) {
            
            [_currentDevice setSubjectAreaChangeMonitoringEnabled:YES];
            [_currentDevice unlockForConfiguration];
            
        } else if (error) {
            DLog(@"error locking device post exposure for subject area change monitoring (%@)", error);
        }

    }

    if ([_delegate respondsToSelector:@selector(visionDidChangeExposure:)])
        [_delegate visionDidChangeExposure:self];
    //    DLog(@"exposure change ended");
}

- (void)_whiteBalanceChangeStarted
{
}

- (void)_whiteBalanceChangeEnded
{
}

- (void)focusAtAdjustedPointOfInterest:(CGPoint)adjustedPoint
{
    if ([_currentDevice isAdjustingFocus] || [_currentDevice isAdjustingExposure])
        return;

    NSError *error = nil;
    if ([_currentDevice lockForConfiguration:&error]) {
    
        BOOL isFocusAtPointSupported = [_currentDevice isFocusPointOfInterestSupported];
    
        if (isFocusAtPointSupported && [_currentDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            AVCaptureFocusMode fm = [_currentDevice focusMode];
            [_currentDevice setFocusPointOfInterest:adjustedPoint];
            [_currentDevice setFocusMode:fm];
        }
        [_currentDevice unlockForConfiguration];
        
    } else if (error) {
        DLog(@"error locking device for focus adjustment (%@)", error);
    }
}

- (BOOL)isAdjustingFocus
{
    return [_currentDevice isAdjustingFocus];
}

- (void)exposeAtAdjustedPointOfInterest:(CGPoint)adjustedPoint
{
    if ([_currentDevice isAdjustingExposure])
        return;

    NSError *error = nil;
    if ([_currentDevice lockForConfiguration:&error]) {
    
        BOOL isExposureAtPointSupported = [_currentDevice isExposurePointOfInterestSupported];
        if (isExposureAtPointSupported && [_currentDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            AVCaptureExposureMode em = [_currentDevice exposureMode];
            [_currentDevice setExposurePointOfInterest:adjustedPoint];
            [_currentDevice setExposureMode:em];
        }
        [_currentDevice unlockForConfiguration];
        
    } else if (error) {
        DLog(@"error locking device for exposure adjustment (%@)", error);
    }
}

- (BOOL)isAdjustingExposure
{
    return [_currentDevice isAdjustingExposure];
}

- (void)_adjustFocusExposureAndWhiteBalance
{
    if ([_currentDevice isAdjustingFocus] || [_currentDevice isAdjustingExposure])
        return;

    // only notify clients when focus is triggered from an event
    if ([_delegate respondsToSelector:@selector(visionWillStartFocus:)])
        [_delegate visionWillStartFocus:self];

    CGPoint focusPoint = CGPointMake(0.5f, 0.5f);
    [self focusAtAdjustedPointOfInterest:focusPoint];
}

// focusExposeAndAdjustWhiteBalanceAtAdjustedPoint: will put focus and exposure into auto
- (void)focusExposeAndAdjustWhiteBalanceAtAdjustedPoint:(CGPoint)adjustedPoint
{
    if ([_currentDevice isAdjustingFocus] || [_currentDevice isAdjustingExposure])
        return;

    NSError *error = nil;
    if ([_currentDevice lockForConfiguration:&error]) {
    
        BOOL isFocusAtPointSupported = [_currentDevice isFocusPointOfInterestSupported];
        BOOL isExposureAtPointSupported = [_currentDevice isExposurePointOfInterestSupported];
        BOOL isWhiteBalanceModeSupported = [_currentDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    
        if (isFocusAtPointSupported && [_currentDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [_currentDevice setFocusPointOfInterest:adjustedPoint];
            [_currentDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        if (isExposureAtPointSupported && [_currentDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [_currentDevice setExposurePointOfInterest:adjustedPoint];
            [_currentDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        if (isWhiteBalanceModeSupported) {
            [_currentDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        
        [_currentDevice setSubjectAreaChangeMonitoringEnabled:NO];
        
        [_currentDevice unlockForConfiguration];
        
    } else if (error) {
        DLog(@"error locking device for focus / exposure / white-balance adjustment (%@)", error);
    }
}

#pragma mark - mirroring

- (void)setMirroringMode:(PBJMirroringMode)mirroringMode
{
	_mirroringMode = mirroringMode;
    
    AVCaptureConnection *videoConnection = [_currentOutput connectionWithMediaType:AVMediaTypeVideo];
	AVCaptureConnection *previewConnection = [_previewLayer connection];
	
    switch (_mirroringMode) {
		case PBJMirroringOff:
        {
			if ([videoConnection isVideoMirroringSupported]) {
				[videoConnection setVideoMirrored:NO];
			}
			if ([previewConnection isVideoMirroringSupported]) {
				[previewConnection setAutomaticallyAdjustsVideoMirroring:NO];
				[previewConnection setVideoMirrored:NO];
			}			
			break;
		}
        case PBJMirroringOn:
        {
			if ([videoConnection isVideoMirroringSupported]) {
				[videoConnection setVideoMirrored:YES];
			}
			if ([previewConnection isVideoMirroringSupported]) {
				[previewConnection setAutomaticallyAdjustsVideoMirroring:NO];
				[previewConnection setVideoMirrored:YES];
			}			
			break;
		}
        case PBJMirroringAuto:
        default:
		{
			if ([videoConnection isVideoMirroringSupported]) {
                BOOL mirror = (_cameraDevice == PBJCameraDeviceFront);
				[videoConnection setVideoMirrored:mirror];
			}
			if ([previewConnection isVideoMirroringSupported]) {
				[previewConnection setAutomaticallyAdjustsVideoMirroring:YES];
			}

			break;
		}
	}
}

#pragma mark - photo

- (BOOL)canCapturePhoto
{
    BOOL isDiskSpaceAvailable = [PBJVisionUtilities availableDiskSpaceInBytes] > PBJVisionRequiredMinimumDiskSpaceInBytes;
    return [self isCaptureSessionActive] && !_flags.changingModes && isDiskSpaceAvailable;
}

- (UIImage *)_uiimageFromJPEGData:(NSData *)jpegData
{
    CGImageRef jpegCGImage = NULL;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)jpegData);
    
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    
    if (provider) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(provider, NULL);
        if (imageSource) {
            if (CGImageSourceGetCount(imageSource) > 0) {
                jpegCGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
                
                // extract the cgImage properties
                CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
                if (properties) {
                    // set orientation
                    CFNumberRef orientationProperty = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
                    if (orientationProperty) {
                        NSInteger exifOrientation = 1;
                        CFNumberGetValue(orientationProperty, kCFNumberIntType, &exifOrientation);
                        imageOrientation = [self _imageOrientationFromExifOrientation:exifOrientation];
                    }
                    
                    CFRelease(properties);
                }
                
            }
            CFRelease(imageSource);
        }
        CGDataProviderRelease(provider);
    }
    
    UIImage *image = nil;
    if (jpegCGImage) {
        image = [[UIImage alloc] initWithCGImage:jpegCGImage scale:1.0 orientation:imageOrientation];
        CGImageRelease(jpegCGImage);
    }
    return image;
}

- (UIImage *)_thumbnailJPEGData:(NSData *)jpegData
{
    CGImageRef thumbnailCGImage = NULL;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)jpegData);
    
    if (provider) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(provider, NULL);
        if (imageSource) {
            if (CGImageSourceGetCount(imageSource) > 0) {
                NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithCapacity:3];
                options[(id)kCGImageSourceCreateThumbnailFromImageAlways] = @(YES);
                options[(id)kCGImageSourceThumbnailMaxPixelSize] = @(PBJVisionThumbnailWidth);
                options[(id)kCGImageSourceCreateThumbnailWithTransform] = @(YES);
                thumbnailCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
            }
            CFRelease(imageSource);
        }
        CGDataProviderRelease(provider);
    }
    
    UIImage *thumbnail = nil;
    if (thumbnailCGImage) {
        thumbnail = [[UIImage alloc] initWithCGImage:thumbnailCGImage];
        CGImageRelease(thumbnailCGImage);
    }
    return thumbnail;
}

// http://sylvana.net/jpegcrop/exif_orientation.html
- (UIImageOrientation)_imageOrientationFromExifOrientation:(NSInteger)exifOrientation
{
    UIImageOrientation imageOrientation = UIImageOrientationUp;

    switch (exifOrientation) {
        case 2:
            imageOrientation = UIImageOrientationUpMirrored;
            break;
        case 3:
            imageOrientation = UIImageOrientationDown;
            break;
        case 4:
            imageOrientation = UIImageOrientationDownMirrored;
            break;
        case 5:
            imageOrientation = UIImageOrientationLeftMirrored;
            break;
        case 6:
           imageOrientation = UIImageOrientationRight;
           break;
        case 7:
            imageOrientation = UIImageOrientationRightMirrored;
            break;
        case 8:
            imageOrientation = UIImageOrientationLeft;
            break;
        case 1:
        default:
            // UIImageOrientationUp;
            break;
    }
    
    return imageOrientation;
}

- (void)_willCapturePhoto
{
    DLog(@"will capture photo");
    if ([_delegate respondsToSelector:@selector(visionWillCapturePhoto:)]) {
        [_delegate visionWillCapturePhoto:self];
    }
    if (_autoFreezePreviewDuringCapture) {
        [self freezePreview];
    }
}

- (void)_didCapturePhoto
{
    if ([_delegate respondsToSelector:@selector(visionDidCapturePhoto:)]) {
        [_delegate visionDidCapturePhoto:self];
    }
    DLog(@"did capture photo");
}

- (void)_capturePhotoFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!sampleBuffer) {
        return;
    }
    DLog(@"capturing photo from sample buffer");

    // create associated data
    NSMutableDictionary *photoDict = [[NSMutableDictionary alloc] init];
    NSDictionary *metadata = nil;
    NSError *error = nil;

    // add any attachments to propagate
    NSDictionary *tiffDict = @{ (NSString *)kCGImagePropertyTIFFSoftware : @"PBJVision",
                                    (NSString *)kCGImagePropertyTIFFDateTime : [NSString PBJformattedTimestampStringFromDate:[NSDate date]] };
    CMSetAttachment(sampleBuffer, kCGImagePropertyTIFFDictionary, (__bridge CFTypeRef)(tiffDict), kCMAttachmentMode_ShouldPropagate);

    // add photo metadata (ie EXIF: Aperture, Brightness, Exposure, FocalLength, etc)
    metadata = (__bridge NSDictionary *)CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    if (metadata) {
        photoDict[PBJVisionPhotoMetadataKey] = metadata;
        CFRelease((__bridge CFTypeRef)(metadata));
    } else {
        DLog(@"failed to generate metadata for photo");
    }
    
    if (!_ciContext) {
        _ciContext = [CIContext contextWithEAGLContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    }

    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CGImageRef cgImage = [_ciContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];

    // add UIImage
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    
    if (cgImage) {
        CFRelease(cgImage);
    }
    
    if (uiImage) {
        photoDict[PBJVisionPhotoImageKey] = uiImage;
        
        // add JPEG, thumbnail
        NSData *jpegData = UIImageJPEGRepresentation(uiImage, 0);
        if (jpegData) {
            // add JPEG
            photoDict[PBJVisionPhotoJPEGKey] = jpegData;
            
            // add thumbnail
            if (_flags.thumbnailEnabled) {
                UIImage *thumbnail = [self _thumbnailJPEGData:jpegData];
                if (thumbnail) {
                    photoDict[PBJVisionPhotoThumbnailKey] = thumbnail;
                }
            }
        }
    } else {
        DLog(@"failed to create image from JPEG");
        error = [NSError errorWithDomain:PBJVisionErrorDomain code:PBJVisionErrorCaptureFailed userInfo:nil];
    }
    
    [self _enqueueBlockOnMainQueue:^{
        if ([_delegate respondsToSelector:@selector(vision:capturedPhoto:error:)]) {
            [_delegate vision:self capturedPhoto:photoDict error:error];
        }
    }];
}

- (void)capturePhoto
{
    if (![self _canSessionCaptureWithOutput:_currentOutput] || _cameraMode != PBJCameraModePhoto) {
        DLog(@"session is not setup properly for capture");
        return;
    }

    AVCaptureConnection *connection = [_currentOutput connectionWithMediaType:AVMediaTypeVideo];
    [self _setOrientationForConnection:connection];
    
    [_captureOutputPhoto captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (!imageDataSampleBuffer) {
            DLog(@"failed to obtain image data sample buffer");
            return;
        }
    
        if (error) {
            if ([_delegate respondsToSelector:@selector(vision:capturedPhoto:error:)]) {
                [_delegate vision:self capturedPhoto:nil error:error];
            }
            return;
        }
        
        // add any attachments to propagate
        NSDictionary *tiffDict = @{ (NSString *)kCGImagePropertyTIFFSoftware : @"PBJVision",
                                    (NSString *)kCGImagePropertyTIFFDateTime : [NSString PBJformattedTimestampStringFromDate:[NSDate date]] };
        CMSetAttachment(imageDataSampleBuffer, kCGImagePropertyTIFFDictionary, (__bridge CFTypeRef)(tiffDict), kCMAttachmentMode_ShouldPropagate);
    
        NSMutableDictionary *photoDict = [[NSMutableDictionary alloc] init];
        NSDictionary *metadata = nil;

        // add photo metadata (ie EXIF: Aperture, Brightness, Exposure, FocalLength, etc)
        metadata = (__bridge NSDictionary *)CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
        if (metadata) {
            photoDict[PBJVisionPhotoMetadataKey] = metadata;
            CFRelease((__bridge CFTypeRef)(metadata));
        } else {
            DLog(@"failed to generate metadata for photo");
        }
        
        // add JPEG, UIImage, thumbnail
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        if (jpegData) {
            // add JPEG
            photoDict[PBJVisionPhotoJPEGKey] = jpegData;
            
            // add image
            UIImage *image = [self _uiimageFromJPEGData:jpegData];
            if (image) {
                photoDict[PBJVisionPhotoImageKey] = image;
            } else {
                DLog(@"failed to create image from JPEG");
                error = [NSError errorWithDomain:PBJVisionErrorDomain code:PBJVisionErrorCaptureFailed userInfo:nil];
            }
            
            // add thumbnail
            if (_flags.thumbnailEnabled) {
                UIImage *thumbnail = [self _thumbnailJPEGData:jpegData];
                if (thumbnail) {
                    photoDict[PBJVisionPhotoThumbnailKey] = thumbnail;
                }
            }
            
        }
        
        if ([_delegate respondsToSelector:@selector(vision:capturedPhoto:error:)]) {
            [_delegate vision:self capturedPhoto:photoDict error:error];
        }
        
        // run a post shot focus
        [self performSelector:@selector(_adjustFocusExposureAndWhiteBalance) withObject:nil afterDelay:0.5f];
    }];
}

#pragma mark - video

- (BOOL)supportsVideoCapture
{
    return ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0);
}

- (BOOL)canCaptureVideo
{
    BOOL isDiskSpaceAvailable = [PBJVisionUtilities availableDiskSpaceInBytes] > PBJVisionRequiredMinimumDiskSpaceInBytes;
    return [self supportsVideoCapture] && [self isCaptureSessionActive] && !_flags.changingModes && isDiskSpaceAvailable;
}

- (void)startVideoCapture
{
    if (![self _canSessionCaptureWithOutput:_currentOutput]) {
        [self _failVideoCaptureWithErrorCode:PBJVisionErrorSessionFailed];
        DLog(@"session is not setup properly for capture");
        return;
    }
    
    DLog(@"starting video capture");
        
    [self _enqueueBlockOnCaptureVideoQueue:^{

        if (_flags.recording || _flags.paused)
            return;
	
        NSString *guid = [[NSUUID new] UUIDString];
        NSString *outputFile = [NSString stringWithFormat:@"video_%@.mp4", guid];
        
        if ([_delegate respondsToSelector:@selector(vision:willStartVideoCaptureToFile:)]) {
            outputFile = [_delegate vision:self willStartVideoCaptureToFile:outputFile];
            
            if (!outputFile) {
                [self _failVideoCaptureWithErrorCode:PBJVisionErrorBadOutputFile];
                return;
            }
        }
        
        NSString *outputDirectory = (_captureDirectory == nil ? NSTemporaryDirectory() : _captureDirectory);
        NSString *outputPath = [outputDirectory stringByAppendingPathComponent:outputFile];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:outputPath error:&error]) {
                [self _failVideoCaptureWithErrorCode:PBJVisionErrorOutputFileExists];

                DLog(@"could not setup an output file (file exists)");
                return;
            }
        }

        if (!outputPath || [outputPath length] == 0) {
            [self _failVideoCaptureWithErrorCode:PBJVisionErrorBadOutputFile];
            
            DLog(@"could not setup an output file");
            return;
        }
        
        if (_mediaWriter) {
            _mediaWriter.delegate = nil;
            _mediaWriter = nil;
        }
        _mediaWriter = [[PBJMediaWriter alloc] initWithOutputURL:outputURL];
        _mediaWriter.delegate = self;

        AVCaptureConnection *videoConnection = [_captureOutputVideo connectionWithMediaType:AVMediaTypeVideo];
        [self _setOrientationForConnection:videoConnection];

        _startTimestamp = CMClockGetTime(CMClockGetHostTimeClock());
        _timeOffset = kCMTimeInvalid;
        
        _flags.recording = YES;
        _flags.paused = NO;
        _flags.interrupted = NO;
        _flags.videoWritten = NO;
        
        _captureThumbnailTimes = [NSMutableSet set];
        _captureThumbnailFrames = [NSMutableSet set];
        
        if (_flags.thumbnailEnabled && _flags.defaultVideoThumbnails) {
            [self captureVideoThumbnailAtFrame:0];
        }
        
        [self _enqueueBlockOnMainQueue:^{                
            if ([_delegate respondsToSelector:@selector(visionDidStartVideoCapture:)])
                [_delegate visionDidStartVideoCapture:self];
        }];
    }];
}

- (void)pauseVideoCapture
{
    [self _enqueueBlockOnCaptureVideoQueue:^{
        if (!_flags.recording)
            return;

        if (!_mediaWriter) {
            DLog(@"media writer unavailable to stop");
            return;
        }

        DLog(@"pausing video capture");

        _flags.paused = YES;
        _flags.interrupted = YES;
        
        [self _enqueueBlockOnMainQueue:^{
            if ([_delegate respondsToSelector:@selector(visionDidPauseVideoCapture:)])
                [_delegate visionDidPauseVideoCapture:self];
        }];
    }];    
}

- (void)resumeVideoCapture
{
    [self _enqueueBlockOnCaptureVideoQueue:^{
        if (!_flags.recording || !_flags.paused)
            return;
 
        if (!_mediaWriter) {
            DLog(@"media writer unavailable to resume");
            return;
        }
 
        DLog(@"resuming video capture");
       
        _flags.paused = NO;

        [self _enqueueBlockOnMainQueue:^{
            if ([_delegate respondsToSelector:@selector(visionDidResumeVideoCapture:)])
                [_delegate visionDidResumeVideoCapture:self];
        }];
    }];    
}

- (void)endVideoCapture
{    
    DLog(@"ending video capture");
    
    [self _enqueueBlockOnCaptureVideoQueue:^{
        if (!_flags.recording)
            return;
        
        if (!_mediaWriter) {
            DLog(@"media writer unavailable to end");
            return;
        }
        
        _flags.recording = NO;
        _flags.paused = NO;
        
        void (^finishWritingCompletionHandler)(void) = ^{
            Float64 capturedDuration = self.capturedVideoSeconds;
            
            _timeOffset = kCMTimeInvalid;
            _startTimestamp = CMClockGetTime(CMClockGetHostTimeClock());
            _flags.interrupted = NO;

            [self _enqueueBlockOnMainQueue:^{
                if ([_delegate respondsToSelector:@selector(visionDidEndVideoCapture:)])
                    [_delegate visionDidEndVideoCapture:self];

                NSMutableDictionary *videoDict = [[NSMutableDictionary alloc] init];
                NSString *path = [_mediaWriter.outputURL path];
                if (path) {
                    videoDict[PBJVisionVideoPathKey] = path;
                    
                    if (_flags.thumbnailEnabled) {
                        if (_flags.defaultVideoThumbnails) {
                            [self captureVideoThumbnailAtTime:capturedDuration];
                        }
                        
                        [self _generateThumbnailsForVideoWithURL:_mediaWriter.outputURL inDictionary:videoDict];
                    }
                }

                videoDict[PBJVisionVideoCapturedDurationKey] = @(capturedDuration);

                NSError *error = [_mediaWriter error];
                if ([_delegate respondsToSelector:@selector(vision:capturedVideo:error:)]) {
                    [_delegate vision:self capturedVideo:videoDict error:error];
                }
            }];
        };
        [_mediaWriter finishWritingWithCompletionHandler:finishWritingCompletionHandler];
    }];
}

- (void)cancelVideoCapture
{
    DLog(@"cancel video capture");
    
    [self _enqueueBlockOnCaptureVideoQueue:^{
        _flags.recording = NO;
        _flags.paused = NO;
        
        [_captureThumbnailTimes removeAllObjects];
        [_captureThumbnailFrames removeAllObjects];
        
        void (^finishWritingCompletionHandler)(void) = ^{
            _timeOffset = kCMTimeInvalid;
            _startTimestamp = CMClockGetTime(CMClockGetHostTimeClock());
            _flags.interrupted = NO;

            [self _enqueueBlockOnMainQueue:^{
                NSError *error = [NSError errorWithDomain:PBJVisionErrorDomain code:PBJVisionErrorCancelled userInfo:nil];
                if ([_delegate respondsToSelector:@selector(vision:capturedVideo:error:)]) {
                    [_delegate vision:self capturedVideo:nil error:error];
                }
            }];
        };

        [_mediaWriter finishWritingWithCompletionHandler:finishWritingCompletionHandler];
    }];
}

- (void)captureVideoFrameAsPhoto
{
    _flags.videoCaptureFrame = YES;
}

- (void)captureCurrentVideoThumbnail
{
    if (_flags.recording) {
        [self captureVideoThumbnailAtTime:self.capturedVideoSeconds];
    }
}

- (void)captureVideoThumbnailAtTime:(Float64)seconds
{
    [_captureThumbnailTimes addObject:@(seconds)];
}

- (void)captureVideoThumbnailAtFrame:(int64_t)frame
{
    [_captureThumbnailFrames addObject:@(frame)];
}

- (void)_generateThumbnailsForVideoWithURL:(NSURL*)url inDictionary:(NSMutableDictionary*)videoDict
{
    if (_captureThumbnailFrames.count == 0 && _captureThumbnailTimes == 0)
        return;
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generate.appliesPreferredTrackTransform = YES;
    
    int32_t timescale = [@([self videoFrameRate]) intValue];
    
    for (NSNumber *frameNumber in [_captureThumbnailFrames allObjects]) {
        CMTime time = CMTimeMake([frameNumber longLongValue], timescale);
        Float64 timeInSeconds = CMTimeGetSeconds(time);
        [self captureVideoThumbnailAtTime:timeInSeconds];
    }
    
    NSMutableArray *captureTimes = [NSMutableArray array];
    NSArray *thumbnailTimes = [_captureThumbnailTimes allObjects];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
    NSArray *sortedThumbnailTimes = [thumbnailTimes sortedArrayUsingSelector:@selector(compare:)];
#pragma clang diagnostic pop
    
    for (NSNumber *seconds in sortedThumbnailTimes) {
        CMTime time = CMTimeMakeWithSeconds([seconds doubleValue], timescale);
        [captureTimes addObject:[NSValue valueWithCMTime:time]];
    }
    
    NSMutableArray *thumbnails = [NSMutableArray array];
    
    for (NSValue *time in captureTimes) {
        CGImageRef imgRef = [generate copyCGImageAtTime:[time CMTimeValue] actualTime:NULL error:NULL];
        if (imgRef) {
            UIImage *image = [[UIImage alloc] initWithCGImage:imgRef];
            if (image) {
                [thumbnails addObject:image];
            }
            
            CGImageRelease(imgRef);
        }
    }
    
    UIImage *defaultThumbnail = [thumbnails firstObject];
    if (defaultThumbnail) {
        [videoDict setObject:defaultThumbnail forKey:PBJVisionVideoThumbnailKey];
    }
    
    if (thumbnails.count) {
        [videoDict setObject:thumbnails forKey:PBJVisionVideoThumbnailArrayKey];
    }
}

- (void)_failVideoCaptureWithErrorCode:(NSInteger)errorCode
{
    if (errorCode && [_delegate respondsToSelector:@selector(vision:capturedVideo:error:)]) {
        NSError *error = [NSError errorWithDomain:PBJVisionErrorDomain code:errorCode userInfo:nil];
        [_delegate vision:self capturedVideo:nil error:error];
    }
}

#pragma mark - media writer setup

- (BOOL)_setupMediaWriterAudioInputWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

	const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
    if (!asbd) {
        DLog(@"audio stream description used with non-audio format description");
        return NO;
    }
    
	unsigned int channels = asbd->mChannelsPerFrame;
    double sampleRate = asbd->mSampleRate;

    DLog(@"audio stream setup, channels (%d) sampleRate (%f)", channels, sampleRate);
    
    size_t aclSize = 0;
	const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &aclSize);
	NSData *currentChannelLayoutData = ( currentChannelLayout && aclSize > 0 ) ? [NSData dataWithBytes:currentChannelLayout length:aclSize] : [NSData data];
    
    NSDictionary *audioCompressionSettings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                                AVNumberOfChannelsKey : @(channels),
                                                AVSampleRateKey :  @(sampleRate),
                                                AVEncoderBitRateKey : @(_audioBitRate),
                                                AVChannelLayoutKey : currentChannelLayoutData };

    return [_mediaWriter setupAudioWithSettings:audioCompressionSettings];
}

- (BOOL)_setupMediaWriterVideoInputWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
    
    CMVideoDimensions videoDimensions = dimensions;
    switch (_outputFormat) {
        case PBJOutputFormatSquare:
        {
            int32_t min = MIN(dimensions.width, dimensions.height);
            videoDimensions.width = min;
            videoDimensions.height = min;
            break;
        }
        case PBJOutputFormatWidescreen:
        {
            videoDimensions.width = dimensions.width;
            videoDimensions.height = (int32_t)(dimensions.width * 9 / 16.0f);
            break;
        }
        case PBJOutputFormatStandard:
        {
            videoDimensions.width = dimensions.width;
            videoDimensions.height = (int32_t)(dimensions.width * 3 / 4.0f);
            break;
        }
        case PBJOutputFormatPreset:
        default:
            break;
    }
    
    NSDictionary *compressionSettings = nil;
    
    if (_additionalCompressionProperties && [_additionalCompressionProperties count] > 0) {
        NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:_additionalCompressionProperties];
        mutableDictionary[AVVideoAverageBitRateKey] = @(_videoBitRate);
        mutableDictionary[AVVideoMaxKeyFrameIntervalKey] = @(_videoFrameRate);
        compressionSettings = mutableDictionary;
    } else {
        compressionSettings = @{ AVVideoAverageBitRateKey : @(_videoBitRate),
                                 AVVideoMaxKeyFrameIntervalKey : @(_videoFrameRate) };
    }
    
	NSDictionary *videoSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                     AVVideoWidthKey : @(videoDimensions.width),
                                     AVVideoHeightKey : @(videoDimensions.height),
                                     AVVideoCompressionPropertiesKey : compressionSettings };
    
    return [_mediaWriter setupVideoWithSettings:videoSettings];
}

- (void)_automaticallyEndCaptureIfMaximumDurationReachedWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CMTime currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

    if (!_flags.interrupted && CMTIME_IS_VALID(currentTimestamp) && CMTIME_IS_VALID(_startTimestamp) && CMTIME_IS_VALID(_maximumCaptureDuration)) {
        if (CMTIME_IS_VALID(_timeOffset)) {
            // Current time stamp is actually timstamp with data from globalClock
            // In case, if we had interruption, then _timeOffset
            // will have information about the time diff between globalClock and assetWriterClock
            // So in case if we had interruption we need to remove that offset from "currentTimestamp"
            currentTimestamp = CMTimeSubtract(currentTimestamp, _timeOffset);
        }
        CMTime currentCaptureDuration = CMTimeSubtract(currentTimestamp, _startTimestamp);
        if (CMTIME_IS_VALID(currentCaptureDuration)) {
            if (CMTIME_COMPARE_INLINE(currentCaptureDuration, >=, _maximumCaptureDuration)) {
                [self _enqueueBlockOnMainQueue:^{
                    [self endVideoCapture];
                }];
            }
        }
    }
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	CFRetain(sampleBuffer);
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        DLog(@"sample buffer data is not ready");
        CFRelease(sampleBuffer);
        return;
    }

    if (!_flags.recording || _flags.paused) {
        CFRelease(sampleBuffer);
        return;
    }

    if (!_mediaWriter) {
        CFRelease(sampleBuffer);
        return;
    }
    
    // setup media writer
    BOOL isVideo = (captureOutput == _captureOutputVideo);
    if (!isVideo && !_mediaWriter.isAudioReady) {
        [self _setupMediaWriterAudioInputWithSampleBuffer:sampleBuffer];
        DLog(@"ready for audio (%d)", _mediaWriter.isAudioReady);
    }
    if (isVideo && !_mediaWriter.isVideoReady) {
        [self _setupMediaWriterVideoInputWithSampleBuffer:sampleBuffer];
        DLog(@"ready for video (%d)", _mediaWriter.isVideoReady);
    }

    BOOL isReadyToRecord = ((!_flags.audioCaptureEnabled || _mediaWriter.isAudioReady) && _mediaWriter.isVideoReady);
    if (!isReadyToRecord) {
        CFRelease(sampleBuffer);
        return;
    }
    
    CMTime currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

    // calculate the length of the interruption and store the offsets
    if (_flags.interrupted) {
        if (isVideo) {
            CFRelease(sampleBuffer);
            return;
        }
        
        // calculate the appropriate time offset
        if (CMTIME_IS_VALID(currentTimestamp) && CMTIME_IS_VALID(_mediaWriter.audioTimestamp)) {
            if (CMTIME_IS_VALID(_timeOffset)) {
                currentTimestamp = CMTimeSubtract(currentTimestamp, _timeOffset);
            }
            
            CMTime offset = CMTimeSubtract(currentTimestamp, _mediaWriter.audioTimestamp);
            _timeOffset = CMTIME_IS_INVALID(_timeOffset) ? offset : CMTimeAdd(_timeOffset, offset);
            DLog(@"new calculated offset %f valid (%d)", CMTimeGetSeconds(_timeOffset), CMTIME_IS_VALID(_timeOffset));
        }
        _flags.interrupted = NO;
    }
    
    // adjust the sample buffer if there is a time offset
    CMSampleBufferRef bufferToWrite = NULL;
    if (CMTIME_IS_VALID(_timeOffset)) {
        //CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
        bufferToWrite = [PBJVisionUtilities createOffsetSampleBufferWithSampleBuffer:sampleBuffer withTimeOffset:_timeOffset];
        if (!bufferToWrite) {
            DLog(@"error subtracting the timeoffset from the sampleBuffer");
        }
    } else {
        bufferToWrite = sampleBuffer;
        CFRetain(bufferToWrite);
    }
    
    // write the sample buffer
    if (bufferToWrite && !_flags.interrupted) {
    
        if (isVideo) {

            [_mediaWriter writeSampleBuffer:bufferToWrite withMediaTypeVideo:isVideo];

            _flags.videoWritten = YES;
        
            // process the sample buffer for rendering onion layer or capturing video photo
            if ( (_flags.videoRenderingEnabled || _flags.videoCaptureFrame) && _flags.videoWritten) {
                [self _executeBlockOnMainQueue:^{
                    [self _processSampleBuffer:bufferToWrite];
                    
                    if (_flags.videoCaptureFrame) {
                        _flags.videoCaptureFrame = NO;
                        [self _willCapturePhoto];
                        [self _capturePhotoFromSampleBuffer:bufferToWrite];
                        [self _didCapturePhoto];
                    }
                }];
            }
            
            [self _enqueueBlockOnMainQueue:^{
                if ([_delegate respondsToSelector:@selector(vision:didCaptureVideoSampleBuffer:)]) {
                    [_delegate vision:self didCaptureVideoSampleBuffer:bufferToWrite];
                }
            }];
        
        } else if (!isVideo && _flags.videoWritten) {
            
            [_mediaWriter writeSampleBuffer:bufferToWrite withMediaTypeVideo:isVideo];
            
            [self _enqueueBlockOnMainQueue:^{
                if ([_delegate respondsToSelector:@selector(vision:didCaptureAudioSample:)]) {
                    [_delegate vision:self didCaptureAudioSample:bufferToWrite];
                }
            }];
        
        }
    
    }
    
    [self _automaticallyEndCaptureIfMaximumDurationReachedWithSampleBuffer:sampleBuffer];
        
    if (bufferToWrite) {
        CFRelease(bufferToWrite);
    }
    
    CFRelease(sampleBuffer);

}

#pragma mark - App NSNotifications

- (void)_applicationWillEnterForeground:(NSNotification *)notification
{
    DLog(@"applicationWillEnterForeground");
    [self _enqueueBlockOnCaptureSessionQueue:^{
        if (!_flags.previewRunning)
            return;
        
        [self _enqueueBlockOnMainQueue:^{
            [self startPreview];
        }];
    }];
}

- (void)_applicationDidEnterBackground:(NSNotification *)notification
{
    DLog(@"applicationDidEnterBackground");
    if (_flags.recording)
        [self pauseVideoCapture];

    if (_flags.previewRunning) {
        [self stopPreview];
        [self _enqueueBlockOnCaptureSessionQueue:^{
            _flags.previewRunning = YES;
        }];
    }
}

#pragma mark - AV NSNotifications

// capture session handlers

- (void)_sessionRuntimeErrored:(NSNotification *)notification
{
    [self _enqueueBlockOnCaptureSessionQueue:^{
        if ([notification object] == _captureSession) {
            NSError *error = [[notification userInfo] objectForKey:AVCaptureSessionErrorKey];
            if (error) {
                switch ([error code]) {
                    case AVErrorMediaServicesWereReset:
                    {
                        DLog(@"error media services were reset");
                        [self _destroyCamera];
                        if (_flags.previewRunning)
                            [self startPreview];
                        break;
                    }
                    case AVErrorDeviceIsNotAvailableInBackground:
                    {
                        DLog(@"error media services not available in background");
                        break;
                    }
                    default:
                    {
                        DLog(@"error media services failed, error (%@)", error);
                        [self _destroyCamera];
                        if (_flags.previewRunning)
                            [self startPreview];
                        break;
                    }
                }
            }
        }
    }];
}

- (void)_sessionStarted:(NSNotification *)notification
{
    [self _enqueueBlockOnMainQueue:^{
        if ([notification object] != _captureSession)
            return;

        DLog(@"session was started");
        
        // ensure there is a capture device setup
        if (_currentInput) {
            AVCaptureDevice *device = [_currentInput device];
            if (device) {
                [self willChangeValueForKey:@"currentDevice"];
                [self _setCurrentDevice:device];
                [self didChangeValueForKey:@"currentDevice"];
            }
        }
    
        if ([_delegate respondsToSelector:@selector(visionSessionDidStart:)]) {
            [_delegate visionSessionDidStart:self];
        }
    }];
}

- (void)_sessionStopped:(NSNotification *)notification
{
    [self _enqueueBlockOnCaptureSessionQueue:^{
        if ([notification object] != _captureSession)
            return;
    
        DLog(@"session was stopped");
        
        if (_flags.recording)
            [self endVideoCapture];
    
        [self _enqueueBlockOnMainQueue:^{
            if ([_delegate respondsToSelector:@selector(visionSessionDidStop:)]) {
                [_delegate visionSessionDidStop:self];
            }
        }];
    }];
}

- (void)_sessionWasInterrupted:(NSNotification *)notification
{
    [self _enqueueBlockOnMainQueue:^{
        if ([notification object] != _captureSession)
            return;
        
        DLog(@"session was interrupted");
        
        if (_flags.recording) {
            [self _enqueueBlockOnMainQueue:^{
                if ([_delegate respondsToSelector:@selector(visionSessionDidStop:)]) {
                    [_delegate visionSessionDidStop:self];
                }
            }];
        }
        
        [self _enqueueBlockOnMainQueue:^{
            if ([_delegate respondsToSelector:@selector(visionSessionWasInterrupted:)]) {
                [_delegate visionSessionWasInterrupted:self];
            }
        }];
    }];
}

- (void)_sessionInterruptionEnded:(NSNotification *)notification
{
    [self _enqueueBlockOnMainQueue:^{
        
        if ([notification object] != _captureSession)
            return;
        
        DLog(@"session interruption ended");
        
        [self _enqueueBlockOnMainQueue:^{
            if ([_delegate respondsToSelector:@selector(visionSessionInterruptionEnded:)]) {
                [_delegate visionSessionInterruptionEnded:self];
            }
        }];
        
    }];
}

// capture input handler

- (void)_inputPortFormatDescriptionDidChange:(NSNotification *)notification
{
    // when the input format changes, store the clean aperture
    // (clean aperture is the rect that represents the valid image data for this display)
    AVCaptureInputPort *inputPort = (AVCaptureInputPort *)[notification object];
    if (inputPort) {
        CMFormatDescriptionRef formatDescription = [inputPort formatDescription];
        if (formatDescription) {
            _cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription, YES);
            if ([_delegate respondsToSelector:@selector(vision:didChangeCleanAperture:)]) {
                [_delegate vision:self didChangeCleanAperture:_cleanAperture];
            }
        }
    }
}

// capture device handler

- (void)_deviceSubjectAreaDidChange:(NSNotification *)notification
{
    [self _adjustFocusExposureAndWhiteBalance];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == (__bridge void *)PBJVisionFocusObserverContext ) {
    
        BOOL isFocusing = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isFocusing) {
            [self _focusStarted];
        } else {
            [self _focusEnded];
        }
    
    }
    else if ( context == (__bridge void *)PBJVisionExposureObserverContext ) {
        
        BOOL isChangingExposure = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isChangingExposure) {
            [self _exposureChangeStarted];
        } else {
            [self _exposureChangeEnded];
        }
        
    }
    else if ( context == (__bridge void *)PBJVisionWhiteBalanceObserverContext ) {
        
        BOOL isWhiteBalanceChanging = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isWhiteBalanceChanging) {
            [self _whiteBalanceChangeStarted];
        } else {
            [self _whiteBalanceChangeEnded];
        }
        
    }
    else if ( context == (__bridge void *)PBJVisionFlashAvailabilityObserverContext ||
              context == (__bridge void *)PBJVisionTorchAvailabilityObserverContext ) {
        
        //        DLog(@"flash/torch availability did change");
        [self _enqueueBlockOnMainQueue:^{
            if ([_delegate respondsToSelector:@selector(visionDidChangeFlashAvailablility:)])
                [_delegate visionDidChangeFlashAvailablility:self];
        }];
        
	}
    else if ( context == (__bridge void *)PBJVisionFlashModeObserverContext ||
              context == (__bridge void *)PBJVisionTorchModeObserverContext ) {
        
        //        DLog(@"flash/torch mode did change");
        [self _enqueueBlockOnMainQueue:^{
            if ([_delegate respondsToSelector:@selector(visionDidChangeFlashMode:)])
                [_delegate visionDidChangeFlashMode:self];
        }];
        
	}
    else if ( context == (__bridge void *)PBJVisionCaptureStillImageIsCapturingStillImageObserverContext ) {
    
		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if ( isCapturingStillImage ) {
            [self _willCapturePhoto];
		} else {
            [self _didCapturePhoto];
        }
        
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - PBJMediaWriterDelegate

- (void)mediaWriterDidObserveAudioAuthorizationStatusDenied:(PBJMediaWriter *)mediaWriter
{
    [self _enqueueBlockOnMainQueue:^{
        [_delegate visionDidChangeAuthorizationStatus:PBJAuthorizationStatusAudioDenied];
    }];
}

- (void)mediaWriterDidObserveVideoAuthorizationStatusDenied:(PBJMediaWriter *)mediaWriter
{
}

#pragma mark - sample buffer processing

// convert CoreVideo YUV pixel buffer (Y luminance and Cb Cr chroma) into RGB
// processing is done on the GPU, operation WAY more efficient than converting on the CPU
- (void)_processSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!_context)
        return;

    if (!_videoTextureCache)
        return;

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    if (CVPixelBufferLockBaseAddress(imageBuffer, 0) != kCVReturnSuccess)
        return;

    [EAGLContext setCurrentContext:_context];

    [self _cleanUpTextures];

    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    // only bind the vertices once or if parameters change
    
    if (_bufferWidth != width ||
        _bufferHeight != height ||
        _bufferDevice != _cameraDevice ||
        _bufferOrientation != _cameraOrientation) {
        
        _bufferWidth = width;
        _bufferHeight = height;
        _bufferDevice = _cameraDevice;
        _bufferOrientation = _cameraOrientation;
        [self _setupBuffers];
        
    }
    
    // always upload the texturs since the input may be changing
    
    CVReturn error = 0;
    
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                        _videoTextureCache,
                                                        imageBuffer,
                                                        NULL,
                                                        GL_TEXTURE_2D,
                                                        GL_RED_EXT,
                                                        (GLsizei)_bufferWidth,
                                                        (GLsizei)_bufferHeight,
                                                        GL_RED_EXT,
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &_lumaTexture);
    if (error) {
        DLog(@"error CVOpenGLESTextureCacheCreateTextureFromImage (%d)", error);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); 
    
    // UV-plane
    glActiveTexture(GL_TEXTURE1);
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                         _videoTextureCache,
                                                         imageBuffer,
                                                         NULL,
                                                         GL_TEXTURE_2D,
                                                         GL_RG_EXT,
                                                         (GLsizei)(_bufferWidth * 0.5),
                                                         (GLsizei)(_bufferHeight * 0.5),
                                                         GL_RG_EXT,
                                                         GL_UNSIGNED_BYTE,
                                                         1,
                                                         &_chromaTexture);
    if (error) {
        DLog(@"error CVOpenGLESTextureCacheCreateTextureFromImage (%d)", error);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if (CVPixelBufferUnlockBaseAddress(imageBuffer, 0) != kCVReturnSuccess)
        return;

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)_cleanUpTextures
{
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);

    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;        
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
}

#pragma mark - OpenGLES context support

- (void)_setupBuffers
{

// unit square for testing
//    static const GLfloat unitSquareVertices[] = {
//        -1.0f, -1.0f,
//        1.0f, -1.0f,
//        -1.0f,  1.0f,
//        1.0f,  1.0f,
//    };
    
    CGSize inputSize = CGSizeMake(_bufferWidth, _bufferHeight);
    CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(inputSize, _presentationFrame);
    
    CGFloat widthScale = CGRectGetHeight(_presentationFrame) / CGRectGetHeight(insetRect);
    CGFloat heightScale = CGRectGetWidth(_presentationFrame) / CGRectGetWidth(insetRect);

    static GLfloat vertices[8];

    vertices[0] = (GLfloat) -widthScale;
    vertices[1] = (GLfloat) -heightScale;
    vertices[2] = (GLfloat) widthScale;
    vertices[3] = (GLfloat) -heightScale;
    vertices[4] = (GLfloat) -widthScale;
    vertices[5] = (GLfloat) heightScale;
    vertices[6] = (GLfloat) widthScale;
    vertices[7] = (GLfloat) heightScale;

    static const GLfloat textureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat textureCoordinatesVerticalFlip[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    GLuint vertexAttributeLocation = [_program attributeLocation:PBJGLProgramAttributeVertex];
    GLuint textureAttributeLocation = [_program attributeLocation:PBJGLProgramAttributeTextureCoord];
    
    glEnableVertexAttribArray(vertexAttributeLocation);
    glVertexAttribPointer(vertexAttributeLocation, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    
    if (_cameraDevice == PBJCameraDeviceFront) {
        glEnableVertexAttribArray(textureAttributeLocation);
        glVertexAttribPointer(textureAttributeLocation, 2, GL_FLOAT, GL_FALSE, 0, textureCoordinatesVerticalFlip);
    } else {
        glEnableVertexAttribArray(textureAttributeLocation);
        glVertexAttribPointer(textureAttributeLocation, 2, GL_FLOAT, GL_FALSE, 0, textureCoordinates);
    }
}

- (void)_setupGL
{
    static GLint uniforms[PBJVisionUniformCount];

    [EAGLContext setCurrentContext:_context];
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *vertShaderName = [bundle pathForResource:@"Shader" ofType:@"vsh"];
    NSString *fragShaderName = [bundle pathForResource:@"Shader" ofType:@"fsh"];
    _program = [[PBJGLProgram alloc] initWithVertexShaderName:vertShaderName fragmentShaderName:fragShaderName];
    [_program addAttribute:PBJGLProgramAttributeVertex];
    [_program addAttribute:PBJGLProgramAttributeTextureCoord];
    [_program link];
    
    uniforms[PBJVisionUniformY] = [_program uniformLocation:@"u_samplerY"];
    uniforms[PBJVisionUniformUV] = [_program uniformLocation:@"u_samplerUV"];
    [_program use];
            
    glUniform1i(uniforms[PBJVisionUniformY], 0);
    glUniform1i(uniforms[PBJVisionUniformUV], 1);
}

- (void)_destroyGL
{
    [EAGLContext setCurrentContext:_context];

    _program = nil;
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
}

@end
