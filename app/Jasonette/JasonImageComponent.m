//
//  JasonImageComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonImageComponent.h"

@implementation JasonImageComponent
+ (UIView *)build:(NSDictionary *)json withOptions:(NSDictionary *)options{
    UIImage *placeholder = [UIImage imageNamed:@"placeholder"];
    UIImageView *component = [[UIImageView alloc] initWithImage:placeholder];
    if(options && options[@"indexPath"]){
        NSString *url = (NSString *) [JasonHelper cleanNull:json[@"url"] type:@"string"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setupIndexPathsForImage" object:nil userInfo:@{@"url": url, @"indexPath": options[@"indexPath"]}];
    }
    UIImage *placeholder_image = [UIImage imageNamed:@"placeholderr"];
    NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];
    if(![url containsString:@"{{"] && ![url containsString:@"}}"]){
        [component setIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [component setShowActivityIndicatorView:YES];
        [component sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder_image completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if(!error){
                JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:i.size];
            }
        }];
    }
    
    
    // Apply Common Style
    [self stylize:json component:component];
    
    // Apply Custom Style
    NSDictionary *style = json[@"style"];
    if(style){
        NSString *url = (NSString *)[JasonHelper cleanNull: json[@"url"] type:@"string"];
        UIImageView *imageView = (UIImageView *)component;
        
        if(style[@"color"]){
            // Setting tint color for an image
            UIColor *newColor = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
            UIImage *newImage = [JasonHelper colorize:imageView.image into:newColor];
            imageView.image = newImage;
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
            
            
            // Constrain the desired aspect ratio
            NSLayoutConstraint *c =
             [NSLayoutConstraint constraintWithItem:imageView
                                          attribute:NSLayoutAttributeHeight
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:imageView
                                          attribute:NSLayoutAttributeWidth
                                         multiplier:aspectRatioMult
                                           constant:0];
            [c setPriority:UILayoutPriorityRequired];
            [imageView addConstraint:c];
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
            
            NSLayoutConstraint *c =
             [NSLayoutConstraint constraintWithItem:imageView
                                          attribute:NSLayoutAttributeWidth
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:imageView
                                          attribute:NSLayoutAttributeHeight
                                         multiplier:aspectRatioMult
                                           constant:0];
            [c setPriority:UILayoutPriorityRequired];
            [imageView addConstraint:c];
        }
    }
    
    return component;
}
@end
