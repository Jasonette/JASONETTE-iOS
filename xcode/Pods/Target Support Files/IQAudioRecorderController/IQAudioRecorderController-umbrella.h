#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "IQ_FDWaveformView.h"
#import "IQAudioCropperViewController.h"
#import "IQAudioRecorderConstraints.h"
#import "IQAudioRecorderViewController.h"
#import "IQCropSelectionBeginView.h"
#import "IQCropSelectionEndView.h"
#import "IQCropSelectionView.h"
#import "IQMessageDisplayView.h"
#import "IQPlaybackDurationView.h"
#import "NSString+IQTimeIntervalFormatter.h"

FOUNDATION_EXPORT double IQAudioRecorderControllerVersionNumber;
FOUNDATION_EXPORT const unsigned char IQAudioRecorderControllerVersionString[];

