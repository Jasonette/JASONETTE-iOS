//
//  JasonImageComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonImageComponent.h"
#import "NSData+ImageContentType.h"
#import "UIImage+GIF.h"
#import "SDWebImage.h"

@implementation JasonImageComponent
+ (UIView *)build: (UIImageView *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if (!component) {
        UIImage *placeholder = [UIImage imageNamed:@"placeholder"];
        component = [[UIImageView alloc] initWithImage:placeholder];
    }

    if(options && options[@"indexPath"]){
        NSString *url = (NSString *) [JasonHelper cleanNull:json[@"url"] type:@"string"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setupIndexPathsForImage" object:nil userInfo:@{@"url": url, @"indexPath": options[@"indexPath"]}];
    }
    UIImage *placeholder_image = [UIImage imageNamed:@"placeholder"];
    NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];

    NSMutableDictionary *style;
    if(json[@"style"]){
        style = [json[@"style"] mutableCopy];
    }

    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageLoader;
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

        if([url containsString:@"file://"]){
            NSString *localImageName = [url substringFromIndex:7];
            UIImage *localImage;

            // Get data for local file
            NSString *filePath = [[NSBundle mainBundle] pathForResource:localImageName ofType:nil];
            NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];

            // Check for animated GIF
            SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
            if (imageFormat == SDImageFormatGIF) {
                localImage = [UIImage sd_imageWithGIFData:data];
                component.animationImages = localImage.images;
                component.animationDuration = localImage.duration;
                [component startAnimating];
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
            [component sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder_image completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if(!error){
                    JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:image.size];
                    if(style[@"color"]){
                        NSString *colorHex = style[@"color"];
                        UIColor *color = [JasonHelper colorwithHexString:colorHex alpha:1.0];
                        UIImage *templateImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                        [component setTintColor:color];
                        [component setImage: templateImage];
                    }
                    if (component.image.images && [component.image.images count] > 1) {
                        component.animationImages = component.image.images;
                        component.animationDuration = component.image.duration;
                        [component startAnimating];
                    }
                } else {
                    [component setImage: placeholder_image];
                }
            }];
        }
    }
    
    // Before applying common styles, Update the style attribute based on the fetched image dimension (different from other components)
    NSMutableDictionary *mutable_json = [json mutableCopy];
    if(json[@"style"]){
        NSMutableDictionary *style = [json[@"style"] mutableCopy];
        NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];

        if(style[@"width"]) {
            [component setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [component setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
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
                                aspectRatioMult = (component.image.size.height / component.image.size.width);
                            }
                        }
                        @catch (NSException *e){
                            aspectRatioMult = (component.image.size.height / component.image.size.width);
                        }
                    } else {
                        aspectRatioMult = (component.image.size.height / component.image.size.width);
                    }
                    NSString *widthStr = style[@"width"];
                    CGFloat width = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:widthStr];
                    style[@"height"] = [NSString stringWithFormat:@"%d", (int)(width * aspectRatioMult)];
                }
            }
        }
        if(style[@"height"]){
            [component setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [component setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            component.clipsToBounds = YES;
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
                                aspectRatioMult = (component.image.size.width / component.image.size.height);
                            }
                        }
                        @catch (NSException *e){
                            aspectRatioMult = (component.image.size.width / component.image.size.height);
                        }
                    } else {
                        aspectRatioMult = (component.image.size.width / component.image.size.height);
                    }
                    NSString *heightStr = style[@"height"];
                    CGFloat height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:heightStr];
                    style[@"width"] = [NSString stringWithFormat:@"%d", (int)(height * aspectRatioMult)];
                }
            }
        }
        mutable_json[@"style"] = style;

        // resize the image with high interpolation for better quality
        if(style[@"height"] && style[@"width"] && !style[@"center_crop"]) {
            NSString *heightStr = style[@"height"];
            NSString *widthStr = style[@"width"];
            CGFloat height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:heightStr];
            CGFloat width = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:widthStr];
            [component setImage: [self resizeImage:component.image newSize:CGSizeMake(width, height)]];
        }
    }
    // Apply Common Style
    [self stylize:mutable_json component:component];
    return component;
}

+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
