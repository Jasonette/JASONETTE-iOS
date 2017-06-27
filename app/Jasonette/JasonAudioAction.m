//
//  Audio.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonAudioAction.h"

@implementation JasonAudioAction
- (void)record{
    IQAudioRecorderViewController *controller = [[IQAudioRecorderViewController alloc] init];
    if(self.options){
        if(self.options[@"color:disabled"]){
            controller.highlightedTintColor = [JasonHelper colorwithHexString:self.options[@"color:disabled"] alpha:1.0];
        }
        if(self.options[@"color"]){
            controller.normalTintColor = [JasonHelper colorwithHexString:self.options[@"color"] alpha:1.0];
        }
        if(self.options[@"theme"] && [self.options[@"theme"] isEqualToString:@"light"]){
            controller.barStyle = UIBarStyleDefault;
        }
    }
    controller.delegate = self;
    [self.VC.navigationController presentBlurredAudioRecorderViewControllerAnimated:controller];
}
- (void)stop{
    if(!self.VC.audios){
        self.VC.audios = [[NSMutableDictionary alloc] init];
    }
    NSString *url = NULL;
    if(self.options && (url = self.options[@"url"])){
            if(self.VC.audios[url]){
                [self.VC.audios[url] stop];
                [self.VC.audios removeObjectForKey:url];
            }
    } else {
        for(NSString *audio_name in self.VC.audios){
            FSAudioStream *audioStream = self.VC.audios[audio_name];
            [audioStream stop];
            [self.VC.audios removeObjectForKey:audio_name];
        }
    }
    [[Jason client] success];
    
}
- (void)position{
    if(self.options){
        NSString *url = self.options[@"url"];
        if(url){
            if(self.VC.audios[url]){
                FSAudioStream *audioStream = self.VC.audios[url];
                FSStreamPosition cur = audioStream.currentTimePlayed;
                [[Jason client] success:@{@"value": [NSString stringWithFormat:@"%f", cur.position]}];
                return;
            }
        } else {
            for(NSString *audio_name in self.VC.audios){
                FSAudioStream *audioStream = self.VC.audios[audio_name];
                FSStreamPosition cur = audioStream.currentTimePlayed;
                [[Jason client] success:@{@"value": [NSString stringWithFormat:@"%f", cur.position]}];
                return;
            }
        }
    }
    [[Jason client] error];
}
- (void)duration{
    if(self.options){
        NSString *url = self.options[@"url"];
        if(url){
            if(self.VC.audios[url]){
                FSAudioStream *audioStream = self.VC.audios[url];
                FSStreamPosition end = audioStream.duration;
                [[Jason client] success:@{@"value": [NSString stringWithFormat:@"%f", end.position]}];
                return;
            }
        } else {
            for(NSString *audio_name in self.VC.audios){
                FSAudioStream *audioStream = self.VC.audios[audio_name];
                FSStreamPosition end = audioStream.duration;
                [[Jason client] success:@{@"value": [NSString stringWithFormat:@"%f", end.position]}];
                return;
            }
        }
    }
}
- (void)seek{
    if(!self.VC.audios){
        self.VC.audios = [[NSMutableDictionary alloc] init];
    }
    
    if(self.options){
        NSString *url = self.options[@"url"];
        if(self.options[@"position"]){
            if(url){
                if(self.VC.audios[url]){
                    FSStreamPosition pos = {0};
                    pos.position = [self.options[@"position"] doubleValue];
                    [self.VC.audios[url] seekToPosition:pos];
                }
            } else {
                for(NSString *audio_name in self.VC.audios){
                    FSAudioStream *audioStream = self.VC.audios[audio_name];
                    FSStreamPosition pos = {0};
                    pos.position = [self.options[@"position"] doubleValue];
                    [audioStream seekToPosition:pos];
                }
            }
        }
    }
    [[Jason client] success];
}
- (void)pause{
    if(!self.VC.audios){
        self.VC.audios = [[NSMutableDictionary alloc] init];
    }
    NSString *url = NULL;
    if(self.options && (url = self.options[@"url"])){
        if(self.VC.audios[url]){
                FSAudioStream *audioStream = self.VC.audios[url];
                [audioStream pause];
            }
    } else {
        for(NSString *audio_name in self.VC.audios){
            FSAudioStream *audioStream = self.VC.audios[audio_name];
            [audioStream pause];
        }
    }
    [[Jason client] success];
    
}

- (void)play{
    if(!self.VC.audios){
        self.VC.audios = [[NSMutableDictionary alloc] init];
    }

    if(self.options){
        NSString *url = self.options[@"url"];
        if(url){
            if(self.VC.audios[url]){
                if([self.VC.audios[url] isPlaying]){
                    FSAudioStream *audioStream = (FSAudioStream *)self.VC.audios[url];
                    [audioStream pause];
                } else {
                    FSAudioStream *audioStream = (FSAudioStream *)self.VC.audios[url];
                    [audioStream pause];
                    [audioStream play];
                }
            } else {
            
                FSAudioStream *audioStream = [[FSAudioStream alloc] init];
                audioStream.strictContentTypeChecking = NO;
                audioStream.defaultContentType = @"audio/mpeg";

                [audioStream playFromURL:[NSURL URLWithString:url]];
                
                MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
                commandCenter.togglePlayPauseCommand.enabled = NO;
                commandCenter.stopCommand.enabled = NO;
                commandCenter.playCommand.enabled = YES;
                commandCenter.pauseCommand.enabled = YES;
                commandCenter.previousTrackCommand.enabled = NO;
                commandCenter.nextTrackCommand.enabled= NO;

                [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                    [[Jason client] call:@{@"type": @"$audio.pause"}];
                    return MPRemoteCommandHandlerStatusSuccess;
                }];
                [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                    [[Jason client] call:@{@"type": @"$audio.pause"}];
                    return MPRemoteCommandHandlerStatusSuccess;
                }];
    
                
                
                NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
                
                NSString *title = self.options[@"title"];
                if(!title) title = @"Audio stream";
                NSString *author = self.options[@"author"];
                if(!author) author = @"";
                NSString *album = self.options[@"album"];
                if(!album) album = @"";
                NSString *image_url = self.options[@"image"];
                if(!image_url){
                    UIImage *i = [UIImage imageNamed:@"placeholder"];

                    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: i];
                    [songInfo setObject:title forKey:MPMediaItemPropertyTitle];
                    [songInfo setObject:author forKey:MPMediaItemPropertyArtist];
                    [songInfo setObject:album forKey:MPMediaItemPropertyAlbumTitle];
                    [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
                    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
                } else {
                    SDWebImageManager *manager = [SDWebImageManager sharedManager];
                    [manager downloadImageWithURL:[NSURL URLWithString:image_url]
                                          options:0
                                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                             // progression tracking code
                                         }
                                        completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: i];
                                            [songInfo setObject:title forKey:MPMediaItemPropertyTitle];
                                            [songInfo setObject:author forKey:MPMediaItemPropertyArtist];
                                            [songInfo setObject:album forKey:MPMediaItemPropertyAlbumTitle];
                                            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
                                            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
                                        }];
                    
                    
                }
                self.VC.audios[url] = audioStream;
                [[Jason client] success];
            }
        } else {
            [[Jason client] finish];
        }
    }
}

-(void)audioRecorderController:(IQAudioRecorderViewController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    NSURL *fileUrl = [NSURL fileURLWithPath: filePath];
    NSData *d = [NSData dataWithContentsOfURL:fileUrl];
    NSString *base64 = [d base64EncodedStringWithOptions:0];
    NSString *dataFormatString = @"data:audio/m4a;base64,%@";
    NSString* dataString = [NSString stringWithFormat:dataFormatString, base64];
    NSURL* dataURI = [NSURL URLWithString:dataString];

    [[Jason client] success: @{@"file_url": filePath, @"data_uri": dataURI.absoluteString, @"data": base64 , @"content_type": @"audio/m4a"}];
    [self.VC.navigationController dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)audioRecorderControllerDidCancel:(IQAudioRecorderViewController *)controller
{
    //Notifying that user has clicked cancel.
    [[Jason client] success];
}
@end
