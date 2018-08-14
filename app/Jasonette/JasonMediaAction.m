//
//  JasonMediaAction.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonMediaAction.h"
@implementation JasonMediaAction
- (void)play{
    NSString *url = self.options[@"url"];
    BOOL exists = NO;
    for(AVPlayer *player in self.VC.playing){
        if([[[player.currentItem.asset valueForKey:@"URL"] absoluteString] isEqualToString:url]){
            exists = YES;
        }
    }
    if(!exists){
        NSURL *videoURL = [NSURL URLWithString:url];
        AVPlayer *player = [AVPlayer playerWithURL:videoURL];
        AVPlayerViewController *controller = [[AVPlayerViewController alloc]init];
        controller.showsPlaybackControls = YES;
        controller.player = player;
        
        if(self.options[@"muted"]){
            player.muted = YES;
        } else {
            player.muted = NO;
        }
        
        [self.VC.playing addObject:player];
        
        if(self.options[@"inline"] && self.options[@"frame"]){
            NSDictionary *frameDict = self.options[@"frame"];
            CGRect frame = CGRectMake([frameDict[@"left"] floatValue], [frameDict[@"top"] floatValue], [frameDict[@"width"] floatValue], [frameDict[@"height"] floatValue]);
            controller.view.frame = frame;
            self.VC.view.autoresizesSubviews = YES;
            [self.VC addChildViewController:controller];
            [self.VC.view addSubview:controller.view];
            
            self.VC.view.userInteractionEnabled = YES;
            controller.view.userInteractionEnabled = YES;
            
            [controller didMoveToParentViewController:self.VC];
            [player play];

        } else {
            [self.VC.navigationController presentViewController:controller animated:YES completion:^{
                [player play];
            }];
        }
    

        
    } else {
        
    }

}

- (void)camera{
    JasonPortraitPicker *picker = [[JasonPortraitPicker alloc] init];
    picker.delegate = self;
    if(self.options[@"edit"]){
        picker.allowsEditing = YES;
    } else {
        picker.allowsEditing = NO;
    }
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [picker.view setFrame:CGRectMake(0,0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];

    
    if(self.options){
        NSString *type = self.options[@"type"];
        if(type){
            if([type isEqualToString:@"photo"]){
                
            } else if([type isEqualToString:@"gif"]){
                NSString *quality = self.options[@"quality"];
                if(quality && [quality isEqualToString:@"high"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                } else if(quality && [quality isEqualToString:@"medium"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                } else if(quality && [quality isEqualToString:@"low"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeLow;
                } else {
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                }
                picker.mediaTypes = @[(NSString *)kUTTypeMovie];
            } else if([type isEqualToString:@"video"]){
                NSString *quality = self.options[@"quality"];
                if(quality && [quality isEqualToString:@"high"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                } else if(quality && [quality isEqualToString:@"medium"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                } else if(quality && [quality isEqualToString:@"low"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeLow;
                } else {
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                }
                picker.mediaTypes = @[(NSString *)kUTTypeMovie];
            }
        }
    }
    [self.VC.navigationController presentViewController:picker animated:YES completion:NULL];
    
}
- (void)picker{
    JasonPortraitPicker *picker = [[JasonPortraitPicker alloc] init];
    picker.delegate = self;
    if(self.options[@"edit"]){
        picker.allowsEditing = YES;
    } else {
        picker.allowsEditing = NO;
    }
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    if(self.options){
        NSString *type = self.options[@"type"];
        if(type){
            if([type isEqualToString:@"photo"]){
                
            } else if([type isEqualToString:@"gif"]){
                NSString *quality = self.options[@"quality"];
                if(quality && [quality isEqualToString:@"high"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                } else if(quality && [quality isEqualToString:@"medium"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                } else if(quality && [quality isEqualToString:@"low"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeLow;
                } else {
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                }
                picker.mediaTypes = @[(NSString *)kUTTypeMovie];
            } else if([type isEqualToString:@"video"]){
                NSString *quality = self.options[@"quality"];
                if(quality && [quality isEqualToString:@"high"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                } else if(quality && [quality isEqualToString:@"medium"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                } else if(quality && [quality isEqualToString:@"low"]){
                    picker.videoQuality = UIImagePickerControllerQualityTypeLow;
                } else {
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                }
                picker.mediaTypes = @[(NSString *)kUTTypeMovie];
            }
        }
    }
    [self.VC.navigationController presentViewController:picker animated:YES completion:NULL];
    
}

- (void)toGif{
    if(self.options){
        NSURL *url = self.options[@"url"];
        if (url){
            [[Jason client] loading:YES];
            [NSGIF optimalGIFfromURL:url loopCount:0 completion:^(NSURL *GifURL) {
                NSData *d = [NSData dataWithContentsOfURL:GifURL];
                NSString *base64 = [d base64EncodedStringWithOptions:0];
                NSDictionary *result = @{@"file_url": url.absoluteString, @"data": base64 , @"content_type": @"image/gif"};
                [[Jason client] success: result];
            }];
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.VC.view.userInteractionEnabled = NO;
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self imagePickerCallback: info];
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [[Jason client] finish];
}
- (void)imagePickerCallback: (NSDictionary *)info{
    NSURL *url = info[UIImagePickerControllerMediaURL];
    NSString *nativeMediaType = info[UIImagePickerControllerMediaType];
    BOOL isMovie = UTTypeConformsTo((__bridge CFStringRef)nativeMediaType,
                                    kUTTypeMovie) != 0;
    BOOL isImage = UTTypeConformsTo((__bridge CFStringRef)nativeMediaType,
                                    kUTTypeImage) != 0;

    [[Jason client] loading:YES];
    if(isMovie){
        
        // Generate a tmpfile. The file name to be uploaded
        // will be regenerated again when actually uploading later
        
        NSString *guid = [[NSUUID new] UUIDString];
        NSString *upload_filename = [NSString stringWithFormat:@"%@.mp4", guid];
        NSString *tmpFile = [NSTemporaryDirectory() stringByAppendingPathComponent:upload_filename];
        
        // Exporting video
        NSURL *inputUrl = info[UIImagePickerControllerMediaURL];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputUrl options:nil];
        NSURL *outputUrl = [NSURL fileURLWithPath:tmpFile];
        [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
        exportSession.outputURL = outputUrl;
        exportSession.outputFileType = AVFileTypeMPEG4;
        [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
         {
            NSString *contentType = @"video/mp4";
            NSData *mediaData = [NSData dataWithContentsOfURL:outputUrl];
            NSString *base64 = [mediaData base64EncodedStringWithOptions:0];
             
            NSString *dataFormatString = @"data:video/mp4;base64,%@";
            NSString* dataString = [NSString stringWithFormat:dataFormatString, base64];
            NSURL* dataURI = [NSURL URLWithString:dataString];
             
             
            NSDictionary *result = @{@"file_url": url.absoluteString, @"data_uri": dataURI.absoluteString, @"data": base64 , @"content_type": contentType};
            [[Jason client] success: result];
         }];
    } else if(isImage){
        UIImage *chosenImage;
        if(self.options[@"edit"]){
            chosenImage = info[UIImagePickerControllerEditedImage];
        } else {
            chosenImage = info[UIImagePickerControllerOriginalImage];
        }
        CGSize size = [[UIScreen mainScreen] bounds].size;
        CGFloat width = size.width;
        CGFloat height = chosenImage.size.height / chosenImage.size.width * width;
        UIImage *newImage = [JasonHelper scaleImage:chosenImage ToSize:CGSizeMake(width, height)];
        
        NSData *mediaData = nil;
        NSString *contentType;
        NSString* dataFormatString;
        
        if(self.options[@"quality"]){
            CGFloat quality = [self.options[@"quality"] floatValue];
            if(quality && quality > 0 && quality <= 1.0){
                mediaData = UIImageJPEGRepresentation(newImage, quality);
                contentType = @"image/jpeg";
                dataFormatString = @"data:image/jpeg;base64,%@";
            }
        }
        
        // mediaData is null if 'quality' was not specified.
        if(!mediaData){
            mediaData = UIImagePNGRepresentation(newImage);
            contentType = @"image/png";
            dataFormatString = @"data:image/png;base64,%@";
        }
        
        NSString *base64 = [mediaData base64EncodedStringWithOptions:0];
        
        NSString* dataString = [NSString stringWithFormat:dataFormatString, base64];
        NSURL* dataURI = [NSURL URLWithString:dataString];
        
        NSDictionary *result;
        if(url){
            result = @{@"file_url": url.absoluteString, @"data_uri": dataURI.absoluteString, @"data": base64 , @"content_type": contentType};
        } else {
            result = @{@"data": base64 , @"data_uri": dataURI.absoluteString, @"content_type": contentType};
        }
        [[Jason client] success: result];
    }
}

@end
