//
//  PBJVision.h
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// support for swift compiler
#ifndef NS_ASSUME_NONNULL_BEGIN
# define NS_ASSUME_NONNULL_BEGIN
# define nullable
# define NS_ASSUME_NONNULL_END
#endif

NS_ASSUME_NONNULL_BEGIN

// vision types

typedef NS_ENUM(NSInteger, PBJCameraDevice) {
    PBJCameraDeviceBack = 0,
    PBJCameraDeviceFront
};

typedef NS_ENUM(NSInteger, PBJCameraMode) {
    PBJCameraModePhoto = 0,
    PBJCameraModeVideo
};

typedef NS_ENUM(NSInteger, PBJCameraOrientation) {
    PBJCameraOrientationPortrait = AVCaptureVideoOrientationPortrait,
    PBJCameraOrientationPortraitUpsideDown = AVCaptureVideoOrientationPortraitUpsideDown,
    PBJCameraOrientationLandscapeRight = AVCaptureVideoOrientationLandscapeRight,
    PBJCameraOrientationLandscapeLeft = AVCaptureVideoOrientationLandscapeLeft,
};

typedef NS_ENUM(NSInteger, PBJFocusMode) {
    PBJFocusModeLocked = AVCaptureFocusModeLocked,
    PBJFocusModeAutoFocus = AVCaptureFocusModeAutoFocus,
    PBJFocusModeContinuousAutoFocus = AVCaptureFocusModeContinuousAutoFocus
};

typedef NS_ENUM(NSInteger, PBJExposureMode) {
    PBJExposureModeLocked = AVCaptureExposureModeLocked,
    PBJExposureModeAutoExpose = AVCaptureExposureModeAutoExpose,
    PBJExposureModeContinuousAutoExposure = AVCaptureExposureModeContinuousAutoExposure
};

typedef NS_ENUM(NSInteger, PBJFlashMode) {
    PBJFlashModeOff = AVCaptureFlashModeOff,
    PBJFlashModeOn = AVCaptureFlashModeOn,
    PBJFlashModeAuto = AVCaptureFlashModeAuto
};

typedef NS_ENUM(NSInteger, PBJMirroringMode) {
	PBJMirroringAuto = 0,
	PBJMirroringOn,
	PBJMirroringOff
};

typedef NS_ENUM(NSInteger, PBJAuthorizationStatus) {
    PBJAuthorizationStatusNotDetermined = 0,
    PBJAuthorizationStatusAuthorized,
    PBJAuthorizationStatusAudioDenied
};

typedef NS_ENUM(NSInteger, PBJOutputFormat) {
    PBJOutputFormatPreset = 0,
    PBJOutputFormatSquare, // 1:1
    PBJOutputFormatWidescreen, // 16:9
    PBJOutputFormatStandard // 4:3
};

// PBJError

extern NSString * const PBJVisionErrorDomain;

typedef NS_ENUM(NSInteger, PBJVisionErrorType)
{
    PBJVisionErrorUnknown = -1,
    PBJVisionErrorCancelled = 100,
    PBJVisionErrorSessionFailed = 101,
    PBJVisionErrorBadOutputFile = 102,
    PBJVisionErrorOutputFileExists = 103,
    PBJVisionErrorCaptureFailed = 104,
};

// photo dictionary keys

extern NSString * const PBJVisionPhotoMetadataKey;
extern NSString * const PBJVisionPhotoJPEGKey;
extern NSString * const PBJVisionPhotoImageKey;
extern NSString * const PBJVisionPhotoThumbnailKey; // 160x120

// video dictionary keys

extern NSString * const PBJVisionVideoPathKey;
extern NSString * const PBJVisionVideoThumbnailKey;
extern NSString * const PBJVisionVideoThumbnailArrayKey;
extern NSString * const PBJVisionVideoCapturedDurationKey; // Captured duration in seconds

// suggested videoBitRate constants

static CGFloat const PBJVideoBitRate480x360 = 87500 * 8;
static CGFloat const PBJVideoBitRate640x480 = 437500 * 8;
static CGFloat const PBJVideoBitRate1280x720 = 1312500 * 8;
static CGFloat const PBJVideoBitRate1920x1080 = 2975000 * 8;
static CGFloat const PBJVideoBitRate960x540 = 3750000 * 8;
static CGFloat const PBJVideoBitRate1280x750 = 5000000 * 8;

@class EAGLContext;
@protocol PBJVisionDelegate;
@interface PBJVision : NSObject

+ (PBJVision *)sharedInstance;

@property (nonatomic, weak, nullable) id<PBJVisionDelegate> delegate;

// session

@property (nonatomic, readonly, getter=isCaptureSessionActive) BOOL captureSessionActive;

// setup

@property (nonatomic) PBJCameraOrientation cameraOrientation;
@property (nonatomic) PBJCameraMode cameraMode;
@property (nonatomic) PBJCameraDevice cameraDevice;
// Indicates whether the capture session will make use of the app’s shared audio session. Allows you to
// use a previously configured audios session with a category such as AVAudioSessionCategoryAmbient.
@property (nonatomic) BOOL usesApplicationAudioSession;
- (BOOL)isCameraDeviceAvailable:(PBJCameraDevice)cameraDevice;

@property (nonatomic) PBJFlashMode flashMode; // flash and torch
@property (nonatomic, readonly, getter=isFlashAvailable) BOOL flashAvailable;

@property (nonatomic) PBJMirroringMode mirroringMode;

// video output settings

@property (nonatomic, copy) NSString *captureSessionPreset;
@property (nonatomic, copy) NSString *captureDirectory;
@property (nonatomic) PBJOutputFormat outputFormat;

// video compression settings

@property (nonatomic) CGFloat videoBitRate;
@property (nonatomic) NSInteger audioBitRate;
@property (nonatomic) NSDictionary *additionalCompressionProperties;

// video frame rate (adjustment may change the capture format (AVCaptureDeviceFormat : FoV, zoom factor, etc)

@property (nonatomic) NSInteger videoFrameRate; // desired fps for active cameraDevice
- (BOOL)supportsVideoFrameRate:(NSInteger)videoFrameRate;

// preview

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic) BOOL autoUpdatePreviewOrientation;
@property (nonatomic) PBJCameraOrientation previewOrientation;
@property (nonatomic) BOOL autoFreezePreviewDuringCapture;

@property (nonatomic, readonly) CGRect cleanAperture;

- (void)startPreview;
- (void)stopPreview;

- (void)freezePreview;
- (void)unfreezePreview;

// focus, exposure, white balance

// note: focus and exposure modes change when adjusting on point
- (BOOL)isFocusPointOfInterestSupported;
- (void)focusExposeAndAdjustWhiteBalanceAtAdjustedPoint:(CGPoint)adjustedPoint;

@property (nonatomic) PBJFocusMode focusMode;
@property (nonatomic, readonly, getter=isFocusLockSupported) BOOL focusLockSupported;
- (void)focusAtAdjustedPointOfInterest:(CGPoint)adjustedPoint;
- (BOOL)isAdjustingFocus;

@property (nonatomic) PBJExposureMode exposureMode;
@property (nonatomic, readonly, getter=isExposureLockSupported) BOOL exposureLockSupported;
- (void)exposeAtAdjustedPointOfInterest:(CGPoint)adjustedPoint;
- (BOOL)isAdjustingExposure;

// photo

@property (nonatomic, readonly) BOOL canCapturePhoto;
- (void)capturePhoto;

// video
// use pause/resume if a session is in progress, end finalizes that recording session

@property (nonatomic, readonly) BOOL supportsVideoCapture;
@property (nonatomic, readonly) BOOL canCaptureVideo;
@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly, getter=isPaused) BOOL paused;

@property (nonatomic, getter=isVideoRenderingEnabled) BOOL videoRenderingEnabled;
@property (nonatomic, getter=isAudioCaptureEnabled) BOOL audioCaptureEnabled;

@property (nonatomic, readonly) EAGLContext *context;
@property (nonatomic) CGRect presentationFrame;

@property (nonatomic) CMTime maximumCaptureDuration; // automatically triggers vision:capturedVideo:error: after exceeding threshold, (kCMTimeInvalid records without threshold)
@property (nonatomic, readonly) Float64 capturedAudioSeconds;
@property (nonatomic, readonly) Float64 capturedVideoSeconds;

- (void)startVideoCapture;
- (void)pauseVideoCapture;
- (void)resumeVideoCapture;
- (void)endVideoCapture;
- (void)cancelVideoCapture;

// thumbnails

@property (nonatomic) BOOL thumbnailEnabled; // thumbnail generation, disabling reduces processing time for a photo or video
@property (nonatomic) BOOL defaultVideoThumbnails; // capture first and last frames of video

- (void)captureCurrentVideoThumbnail;
- (void)captureVideoThumbnailAtFrame:(int64_t)frame;
- (void)captureVideoThumbnailAtTime:(Float64)seconds;

@end

@protocol PBJVisionDelegate <NSObject>
@optional

// session

- (void)visionSessionWillStart:(PBJVision *)vision;
- (void)visionSessionDidStart:(PBJVision *)vision;
- (void)visionSessionDidStop:(PBJVision *)vision;

- (void)visionSessionWasInterrupted:(PBJVision *)vision;
- (void)visionSessionInterruptionEnded:(PBJVision *)vision;

// device / mode / format

- (void)visionCameraDeviceWillChange:(PBJVision *)vision;
- (void)visionCameraDeviceDidChange:(PBJVision *)vision;

- (void)visionCameraModeWillChange:(PBJVision *)vision;
- (void)visionCameraModeDidChange:(PBJVision *)vision;

- (void)visionOutputFormatWillChange:(PBJVision *)vision;
- (void)visionOutputFormatDidChange:(PBJVision *)vision;

- (void)vision:(PBJVision *)vision didChangeCleanAperture:(CGRect)cleanAperture;

- (void)visionDidChangeVideoFormatAndFrameRate:(PBJVision *)vision;

// focus / exposure

- (void)visionWillStartFocus:(PBJVision *)vision;
- (void)visionDidStopFocus:(PBJVision *)vision;

- (void)visionWillChangeExposure:(PBJVision *)vision;
- (void)visionDidChangeExposure:(PBJVision *)vision;

- (void)visionDidChangeFlashMode:(PBJVision *)vision; // flash or torch was changed

// authorization / availability

- (void)visionDidChangeAuthorizationStatus:(PBJAuthorizationStatus)status;
- (void)visionDidChangeFlashAvailablility:(PBJVision *)vision; // flash or torch is available

// preview

- (void)visionSessionDidStartPreview:(PBJVision *)vision;
- (void)visionSessionDidStopPreview:(PBJVision *)vision;

// photo

- (void)visionWillCapturePhoto:(PBJVision *)vision;
- (void)visionDidCapturePhoto:(PBJVision *)vision;
- (void)vision:(PBJVision *)vision capturedPhoto:(nullable NSDictionary *)photoDict error:(nullable NSError *)error;

// video

- (NSString *)vision:(PBJVision *)vision willStartVideoCaptureToFile:(NSString *)fileName;
- (void)visionDidStartVideoCapture:(PBJVision *)vision;
- (void)visionDidPauseVideoCapture:(PBJVision *)vision; // stopped but not ended
- (void)visionDidResumeVideoCapture:(PBJVision *)vision;
- (void)visionDidEndVideoCapture:(PBJVision *)vision;
- (void)vision:(PBJVision *)vision capturedVideo:(nullable NSDictionary *)videoDict error:(nullable NSError *)error;

// video capture progress

- (void)vision:(PBJVision *)vision didCaptureVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)vision:(PBJVision *)vision didCaptureAudioSample:(CMSampleBufferRef)sampleBuffer;

NS_ASSUME_NONNULL_END

@end
