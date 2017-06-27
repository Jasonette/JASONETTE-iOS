//
//  JasonButtonComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonButtonComponent.h"
#import "NSData+ImageContentType.h"
#import "UIImage+GIF.h"

@implementation JasonButtonComponent
+ (UIView *)build: (UIButton *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if(!component){
        component = [[NoPaddingButton alloc] init];
    }
    NSMutableDictionary *mutable_json = [json mutableCopy];
    
    NSMutableDictionary *style;
    if(json[@"style"]){
        style = [json[@"style"] mutableCopy];
    }
    
    if(json[@"url"]){
        
        if(options && options[@"indexPath"]){
            NSString *url = (NSString *) [JasonHelper cleanNull:json[@"url"] type:@"string"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setupIndexPathsForImage" object:nil userInfo:@{@"url": url, @"indexPath": options[@"indexPath"]}];
        }
        
        component.imageView.contentMode = UIViewContentModeScaleAspectFit;

        UIImage *placeholder_image = [UIImage imageNamed:@"placeholderr"];
        [component setImage:placeholder_image forState:UIControlStateNormal];
        NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];
        
        
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
        
        UIImageView * imageView = [[UIImageView alloc] init];
        
        if(![url containsString:@"{{"] && ![url containsString:@"}}"]){
            
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

                if(style[@"color"]){
                    // Setting tint color for an image
                    UIColor *newColor = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
                    UIImage *newImage = [JasonHelper colorize:localImage into:newColor];
                    [component setImage:newImage forState:UIControlStateNormal];

                } else {
                    [component setImage:localImage forState:UIControlStateNormal];
                }
                                
                JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:localImage.size];
            } else{
                [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder_image completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    if(!error){
                        JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:i.size];
                        if(style[@"color"]){
                            NSString *colorHex = style[@"color"];
                            UIColor *c = [JasonHelper colorwithHexString:colorHex alpha:1.0];
                            UIImage *image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                            [component setTintColor:c];
                            [component setImage: image forState:UIControlStateNormal];
                        } else {
                            [component setImage:imageView.image forState:UIControlStateNormal];
                        }
                    }
                }];
            }
        }
        [component setTitle:@"" forState:UIControlStateNormal];
        
        // Before applying common styles, Update the style attribute based on the fetched image dimension (different from other components)

        if(style){
            NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];
   
                    
            if(style[@"width"] && !style[@"height"]){
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
            if(style[@"height"] && !style[@"width"]){
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
            mutable_json[@"style"] = style;
        }
        
    }
    else{
        [component setImage:nil forState:UIControlStateNormal];
        if(json[@"text"]){
            [component setTitle:json[@"text"] forState:UIControlStateNormal];
        }

    }

    
    

    
    
    if(json[@"action"]){
        component.payload = [@{@"action": json[@"action"]} mutableCopy];
    }
    [component removeTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [component addTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    // 1. Apply Common Style
    [self stylize:mutable_json component:component];


    // 2. Custom Style
    [component setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    if(style){
        if(json[@"text"]){
            // text button
            [self stylize:json text:component.titleLabel];
            
        }
        if(style[@"color"]){
            NSString *colorHex = style[@"color"];
            UIColor *c = [JasonHelper colorwithHexString:colorHex alpha:1.0];
            component.tintColor = c;
            [component setTitleColor:c forState:UIControlStateNormal];
        }

    }
    
    
    if(style){
        // Padding Override
        NSString *padding_left = @"0";
        NSString *padding_right = @"0";
        NSString *padding_top = @"0";
        NSString *padding_bottom = @"0";

        if(json[@"text"]){
            // padding 5 in case of text button
            padding_left = @"5";
            padding_right = @"5";
            padding_top = @"5";
            padding_bottom = @"5";
        }
        
        if(style[@"padding"]){
            NSString *padding = style[@"padding"];
            padding_left = padding;
            padding_top = padding;
            padding_right = padding;
            padding_bottom = padding;
        }
        
        if(style[@"padding_left"]) padding_left = style[@"padding_left"];
        if(style[@"padding_right"]) padding_right = style[@"padding_right"];
        if(style[@"padding_top"]) padding_top = style[@"padding_top"];
        if(style[@"padding_bottom"]) padding_bottom = style[@"padding_bottom"];
        component.contentEdgeInsets = UIEdgeInsetsMake([JasonHelper pixelsInDirection:@"vertical" fromExpression:padding_top], [JasonHelper pixelsInDirection:@"horizontal" fromExpression:padding_left], [JasonHelper pixelsInDirection:@"vertical" fromExpression:padding_bottom], [JasonHelper pixelsInDirection:@"horizontal" fromExpression:padding_right]);
        
        
        
        // align
        if(style[@"align"]){
            if([style[@"align"] isEqualToString:@"left"]){
                component.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            } else if([style[@"align"] isEqualToString:@"right"]){
                component.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            } else {
                if(json[@"url"]){
                    // image buttons fill horizontally
                    component.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
                } else {
                    // text buttons center horizontally
                    component.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;

                }
            }
        }
        component.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        

    }
    
    [component setSelected:NO];
    return component;
}
+ (void)actionButtonClicked:(UIButton *)sender{
    if(sender.payload && sender.payload[@"action"]){
        [[Jason client] call: sender.payload[@"action"]];
    }
}

@end
