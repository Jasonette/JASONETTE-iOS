//
//  JasonImageComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonImageComponent.h"
#import "NSData+ImageContentType.h"
#import "UIImage+GIF.h"

@implementation JasonImageComponent
+ (UIView *)build: (UIImageView *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if(!component){
        UIImage *placeholder = [UIImage imageNamed:@"placeholder"];
        component = [[UIImageView alloc] initWithImage:placeholder];
    }
    if(options && options[@"indexPath"]){
        NSString *url = (NSString *) [JasonHelper cleanNull:json[@"url"] type:@"string"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setupIndexPathsForImage" object:nil userInfo:@{@"url": url, @"indexPath": options[@"indexPath"]}];
    }
    UIImage *placeholder_image = [UIImage imageNamed:@"placeholderr"];
    NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];
    
    NSMutableDictionary *style;
    if(json[@"style"]){
        style = [json[@"style"] mutableCopy];
    }

    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *session = [JasonHelper sessionForUrl:url];
    if(session && session.count > 0 && session[@"header"]){
        for(NSString *key in session[@"header"]){
            [manager setValue:session[@"header"][key] forHTTPHeaderField:key];
        }
    }
    if(json[@"header"] && [json[@"header"] count] > 0){
        for(NSString *key in json[@"header"]){
            [manager setValue:json[@"header"][key] forHTTPHeaderField:key];
        }
    }
    
    if(![url containsString:@"{{"] && ![url containsString:@"}}"]){
        [component setIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [component setShowActivityIndicatorView:YES];
        
        if([url containsString:@"file://"]){
            NSString *localImageName = [url substringFromIndex:7];
            UIImage *localImage;
            
            // Get data for local file
            NSString *filePath = [[NSBundle mainBundle] pathForResource:localImageName ofType:nil];
            NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
            
            // Check for animated GIF
            NSString *imageContentType = [NSData sd_contentTypeForImageData:data];
            if ([imageContentType isEqualToString:@"image/gif"]) {
                localImage = [UIImage sd_animatedGIFWithData:data];
            } else {
                localImage = [UIImage imageNamed:localImageName];
            }

            if(json[@"style"] && json[@"style"][@"color"]){
                // Setting tint color for an image
                UIColor *newColor = [JasonHelper colorwithHexString:json[@"style"][@"color"] alpha:1.0];
                UIImage *newImage = [JasonHelper colorize:localImage into:newColor];
                [component setImage:newImage];
            } else {
                [component setImage:localImage];
            }

            
            JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:localImage.size];
        } else{
            [component sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder_image completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if(!error){
                    JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:i.size];
                    if(style[@"color"]){
                        NSString *colorHex = style[@"color"];
                        UIColor *c = [JasonHelper colorwithHexString:colorHex alpha:1.0];
                        UIImage *image = [i imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                        [component setTintColor:c];
                        [component setImage: image];;
                    }
                }
            }];
        }
        
    }
    
    // Before applying common styles, Update the style attribute based on the fetched image dimension (different from other components)
    NSMutableDictionary *mutable_json = [json mutableCopy];
    if(json[@"style"]){
        NSMutableDictionary *style = [json[@"style"] mutableCopy];
        NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];
        UIImageView *imageView = (UIImageView *)component;
        
        if(style[@"width"]) {
            if(style[@"ratio"]){
                // don't do anything about the height, it will be handled in JasonComponent
            } else {
                if (!style[@"height"]){
                    // Width is set but height is not
                    CGFloat aspectRatioMult;
                    if(JasonComponentFactory.imageLoaded[url]){
                        @try{
                            CGSize size = [JasonComponentFactory.imageLoaded[url] CGSizeValue];
                            if(size.width > 0 && size.height > 0){
                                aspectRatioMult = (size.height / size.width);
                            } else {
                                aspectRatioMult = (imageView.image.size.height / imageView.image.size.width);
                            }
                        }
                        @catch (NSException *e){
                            aspectRatioMult = (imageView.image.size.height / imageView.image.size.width);
                        }
                    } else {
                        aspectRatioMult = (imageView.image.size.height / imageView.image.size.width);
                    }
                    NSString *widthStr = style[@"width"];
                    CGFloat width = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:widthStr];
                    style[@"height"] = [NSString stringWithFormat:@"%d", (int)(width * aspectRatioMult)];
                }
            }
        }
        if(style[@"height"]){
            if(style[@"ratio"]){
                // don't do anything about the width, it will be handled in JasonComponent
            } else {
                if(!style[@"width"]) {
                    // Height is set but width is not
                    CGFloat aspectRatioMult;
                    if(JasonComponentFactory.imageLoaded[url]){
                        @try {
                            CGSize size = [JasonComponentFactory.imageLoaded[url] CGSizeValue];
                            if(size.width > 0 && size.height > 0){
                                aspectRatioMult = (size.width / size.height);
                            } else {
                                aspectRatioMult = (imageView.image.size.width / imageView.image.size.height);
                            }
                        }
                        @catch (NSException *e){
                            aspectRatioMult = (imageView.image.size.width / imageView.image.size.height);
                        }
                    } else {
                        aspectRatioMult = (imageView.image.size.width / imageView.image.size.height);
                    }
                    NSString *heightStr = style[@"height"];
                    CGFloat height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:heightStr];
                    style[@"width"] = [NSString stringWithFormat:@"%d", (int)(height * aspectRatioMult)];
                }
            }
        }
        mutable_json[@"style"] = style;
    }
    // Apply Common Style
    [self stylize:mutable_json component:component];
    return component;
}
@end
