//
// IQAudioRecorderController.h
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


#import <UIKit/UIKit.h>
#import "IQAudioRecorderConstraints.h"

@class IQAudioRecorderViewController;

@protocol IQAudioRecorderViewControllerDelegate <NSObject>

@required
/**
 Returns the temporary recorded filePath, you need to copy the recorded file to your own location and don't rely on the filePath anymore. You need to dismiss controller yourself.
 */
-(void)audioRecorderController:(nonnull IQAudioRecorderViewController*)controller didFinishWithAudioAtPath:(nonnull NSString*)filePath;

@optional
/**
 Optional method to determine if user taps on Cancel button. If you implement this delegate then you need to dismiss controller yourself.
 */
-(void)audioRecorderControllerDidCancel:(nonnull IQAudioRecorderViewController*)controller;

@end



@interface IQAudioRecorderViewController : UIViewController

/**
 Title to show on navigationBar
 */
@property(nullable, nonatomic,copy) NSString *title;

///--------------------------
/// @name Delegate callback
///--------------------------

/**
 IQAudioRecorderController delegate.
 */
@property(nullable, nonatomic, weak) id<IQAudioRecorderViewControllerDelegate> delegate;


///--------------------------
/// @name User Interface
///--------------------------

/**
 Support light and dark style UI for the user interface. If you would like to present light style then you may need to set barStyle to UIBarStyleDefault, otherwise dark style UI is the default.
 */
@property(nonatomic,assign) UIBarStyle barStyle;

/**
 normalTintColor is used for showing wave tintColor while not recording, it is also used for navigationBar and toolbar tintColor.
 */
@property (nullable, nonatomic, strong) UIColor *normalTintColor;

/**
 Highlighted tintColor is used when playing the recorded audio file or when recording the audio file.
 */
@property (nullable, nonatomic, strong) UIColor *highlightedTintColor;

/**
 Allows to crop audio files.
 */
@property (nonatomic, assign) BOOL allowCropping;


///--------------------------
/// @name Audio Settings
///--------------------------


/**
 Maximum duration of the audio file to be recorded.
 */
@property(nonatomic) NSTimeInterval maximumRecordDuration;

/**
 Audio format. default is IQAudioFormat_m4a.
 */
@property(nonatomic,assign) IQAudioFormat audioFormat;

/**
 sampleRate should be floating point in Hertz.
 */
@property(nonatomic,assign) CGFloat sampleRate;

/**
 Number of channels.
 */
@property(nonatomic,assign) NSInteger numberOfChannels;

/**
 Audio quality.
 */
@property(nonatomic,assign) IQAudioQuality audioQuality;

/**
 bitRate.
 */
@property(nonatomic,assign) NSInteger bitRate;

@end


@interface UIViewController (IQAudioRecorderViewController)

- (void)presentAudioRecorderViewControllerAnimated:(nonnull IQAudioRecorderViewController *)audioRecorderViewController;
- (void)presentBlurredAudioRecorderViewControllerAnimated:(nonnull IQAudioRecorderViewController *)audioRecorderViewController;

@end
