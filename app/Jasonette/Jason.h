//
//  Jason.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RussianDollView.h"
#import "REMenu.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "JasonHelper.h"
#import "JasonMemory.h"
#import "JasonParser.h"
#import "JasonViewController.h"
#import "BBBadgeBarButtonItem.h"
#import "AFNetworking.h"
#import <SafariServices/SafariServices.h>
#import <NSHash/NSString+NSHash.h>
#import <FreeStreamer/FSAudioStream.h>
#import <PBJVision/PBJVision.h>
@import MediaPlayer;

@interface Jason : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITabBarControllerDelegate, PBJVisionDelegate>
                                                                                                                                 
@property (strong, nonatomic) NSDictionary *parser;
@property (strong, nonatomic) NSDictionary *data;
@property (strong, nonatomic) NSDictionary *options;
@property (strong, nonatomic) NSDictionary *rendered;
@property (strong, nonatomic) NSMutableArray *playing;
@property (nonatomic, assign) BOOL touching;
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) BOOL oauth_in_process;


+ (Jason*)client;
- (Jason*)attach:(UIViewController<RussianDollView>*)viewController;
- (Jason*)detach:(UIViewController<RussianDollView>*)viewController;

- (void)cancel;
- (void)ok;
- (void)ok:(NSDictionary *)result;
- (void)finish;
- (void)error:(id)result;
- (void)error;

- (void)success:(id)result;
- (void)success;

- (void)go:(NSDictionary *)href;
- (void)call: (NSDictionary*)action;
- (void)call: (NSDictionary*)action with: (NSDictionary *)data;

- (void)loading:(BOOL)turnon;
- (void)search;
- (void)snapshot;

- (void)reload;

- (void)start;

@end
