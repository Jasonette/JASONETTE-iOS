//
//  IQAudioCropperViewController.h
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

@class IQAudioCropperViewController;

@protocol IQAudioCropperViewControllerDelegate <NSObject>

@required
/**
 Returns the temporary audio filePath, you need to copy the audio file to your own location and don't rely on the filePath anymore. You need to dismiss controller from yourself.
 */
-(void)audioCropperController:(nonnull IQAudioCropperViewController*)controller didFinishWithAudioAtPath:(nonnull NSString*)filePath;

@optional
/**
 Optional method to determine if user taps on Cancel button. If you implement this delegate then you need to dismiss controller yourself.
 */
-(void)audioCropperControllerDidCancel:(nonnull IQAudioCropperViewController*)controller;

@end


@interface IQAudioCropperViewController : UIViewController

/**
 Initialise with audio file path
 */
-(nonnull instancetype)initWithFilePath:(nonnull NSString*)audioFilePath;

/**
 Original audio file path
 */
@property(nonnull, nonatomic, strong, readonly) NSString *originalAudioFilePath;

/**
 Original audio file path
 */
@property(nonnull, nonatomic, strong, readonly) NSString *currentAudioFilePath;

/**
 Title to show on navigationBar
 */
@property(nullable, nonatomic,copy) NSString *title;

///--------------------------
/// @name Delegate callback
///--------------------------

/**
 IQAudioCropperViewController delegate.
 */
@property(nullable, nonatomic, weak) id<IQAudioCropperViewControllerDelegate> delegate;


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

@end


@interface UIViewController (IQAudioCropperViewController)

- (void)presentAudioCropperViewControllerAnimated:(nonnull IQAudioCropperViewController *)audioCropperViewController;
- (void)presentBlurredAudioCropperViewControllerAnimated:(nonnull IQAudioCropperViewController *)audioCropperViewController;

@end
