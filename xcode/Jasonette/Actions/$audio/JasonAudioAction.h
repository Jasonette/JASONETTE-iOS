//
//  Audio.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonAction.h"
#import "JasonHelper.h"
#import <FreeStreamer/FSAudioStream.h>
#import <AVFoundation/AVFoundation.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <IQAudioRecorderController/IQAudioRecorderViewController.h>
@import MediaPlayer;

@interface JasonAudioAction : JasonAction<IQAudioRecorderViewControllerDelegate, UINavigationControllerDelegate>
@end
