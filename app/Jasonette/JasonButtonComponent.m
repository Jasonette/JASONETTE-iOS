//
//  JasonButtonComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonButtonComponent.h"

@implementation JasonButtonComponent
+ (UIView *)build: (UIButton *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if(!component){
        component = [[UIButton alloc] init];
    }
    NSMutableDictionary *mutable_json = [json mutableCopy];
    if(json[@"url"]){
        
        if(options && options[@"indexPath"]){
            NSString *url = (NSString *) [JasonHelper cleanNull:json[@"url"] type:@"string"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setupIndexPathsForImage" object:nil userInfo:@{@"url": url, @"indexPath": options[@"indexPath"]}];
        }
        
        
        UIImage *placeholder_image = [UIImage imageNamed:@"placeholderr"];
        [component setBackgroundImage:placeholder_image forState:UIControlStateNormal];
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
            [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder_image completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if(!error){
                    JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:i.size];
                    [component setBackgroundImage:imageView.image forState:UIControlStateNormal];
                }
            }];
        }
        [component setTitle:@"" forState:UIControlStateNormal];
        
        // Before applying common styles, Update the style attribute based on the fetched image dimension (different from other components)
        if(json[@"style"]){
            NSMutableDictionary *style = [json[@"style"] mutableCopy];
            NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];
            
            if(style[@"color"]){
                // Setting tint color for an image
                UIColor *newColor = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
                UIImage *newImage = [JasonHelper colorize:imageView.image into:newColor];
                imageView.image = newImage;
                [component setBackgroundImage:imageView.image forState:UIControlStateNormal];
            }
            
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
        [component setBackgroundImage:nil forState:UIControlStateNormal];
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
    NSDictionary *style = json[@"style"];
    if(style){
        if(json[@"text"]){
            // text button
            [self stylize:json text:component.titleLabel];
            
            if(!style[@"background"]){
                component.backgroundColor = [JasonHelper colorwithHexString:@"#007AFF" alpha:1.0];
            }
            
            if(style[@"color"]){
                NSString *colorHex = style[@"color"];
                component.tintColor = [JasonHelper colorwithHexString:colorHex alpha:1.0];
                UIColor *c = [JasonHelper colorwithHexString:colorHex alpha:1.0];
                [component setTitleColor:c forState:UIControlStateNormal];
            } else {
                component.tintColor = [UIColor whiteColor];
            }
            
        }
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
