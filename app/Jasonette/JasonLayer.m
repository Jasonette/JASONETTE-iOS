//
//  JasonLayer.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonLayer.h"
#import "NSData+ImageContentType.h"
#import "UIImage+GIF.h"

@implementation JasonLayer
static NSMutableDictionary *_stylesheet = nil;
+ (NSArray *)setupLayers: (NSDictionary *)body withView: (UIView *)rootView{
    NSArray *layer_items = body[@"layers"];
    NSMutableArray *layers = [[NSMutableArray alloc] init];
    
    if(layer_items && layer_items.count > 0){
        for(int i = 0 ; i < layer_items.count ; i++){
            NSDictionary *layer = layer_items[i];
            layer = [self applyStylesheet:layer];
            
            
            if(layer[@"type"] && [layer[@"type"] isEqualToString:@"image"] && layer[@"url"]){
                
                UIImageView *layerChild = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                UIView *layerView = [[UIView alloc] init];
                [self addGestureRecognizersTo:layerView withStyle: layer[@"style"]];
                layerChild.userInteractionEnabled = NO;
                layerChild.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                if ([layerChild.layer respondsToSelector:@selector(setAllowsEdgeAntialiasing:)]) {
                  [layerChild.layer setAllowsEdgeAntialiasing:YES];
                }
                [layerView addSubview:layerChild];
                
                if([layer[@"url"] containsString:@"file://"]){
                    NSString *localImageName = [layer[@"url"] substringFromIndex:7];                
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
                    
                    CGSize size = localImage.size;
                    
                    layerChild.image = localImage;
                    
                    if(size.width > 0 && size.height > 0){
                        
                        if(layer[@"style"]){
                            [self setStyle:layer[@"style"] ForLayerChild:layerChild ofSize:[NSValue valueWithCGSize:size]];
                            
                            
                            if(layer[@"style"][@"color"]){
                                // Setting tint color for an image
                                UIColor *newColor = [JasonHelper colorwithHexString:layer[@"style"][@"color"] alpha:1.0];
                                UIImage *newImage = [JasonHelper colorize:localImage into:newColor];
                                layerChild.image = newImage;
                            }
                        }
                        
                    }

                } else {
                    NSURL *url = [NSURL URLWithString:layer[@"url"]];
                    
                    [layerChild sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                        CGSize size = image.size;
                        
                        if(size.width > 0 && size.height > 0){
                            
                            if(layer[@"style"]){
                                [self setStyle:layer[@"style"] ForLayerChild:layerChild ofSize:[NSValue valueWithCGSize:size]];
                                
                                
                                if(layer[@"style"][@"color"]){
                                    // Setting tint color for an image
                                    UIColor *newColor = [JasonHelper colorwithHexString:layer[@"style"][@"color"] alpha:1.0];
                                    UIImage *newImage = [JasonHelper colorize:image into:newColor];
                                    layerChild.image = newImage;
                                }
                            }
                            
                        }
                    }];
                    
                }
                if(layer[@"action"]){
                    if(layer[@"name"]){
                        layerView.payload = [@{@"type": @"layer", @"action": layer[@"action"], @"name": layer[@"name"]} mutableCopy];
                    } else {
                        layerView.payload = [@{@"type": @"layer", @"action": layer[@"action"]} mutableCopy];
                    }
                }
                [rootView addSubview:layerView];
                [layers addObject:layerView];
            } else if(layer[@"type"] && [layer[@"type"] isEqualToString:@"label"] && layer[@"text"]){
                TTTAttributedLabel *layerChild = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0,0,0,0)];
                if(layer[@"style"]){
                    [JasonComponent stylize:layer component:layerChild];
                }
                layerChild.lineBreakMode = NSLineBreakByWordWrapping;
                layerChild.numberOfLines = 0;
                
                // Must set text after setting style
                
                layerChild.text = layer[@"text"];
                [layerChild sizeToFit];
                
                UIView *layerView = [[UIView alloc] init];
                [self addGestureRecognizersTo:layerView withStyle: layer[@"style"]];
                layerChild.userInteractionEnabled = NO;
                layerChild.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                if ([layerChild.layer respondsToSelector:@selector(setAllowsEdgeAntialiasing:)]) {
                  [layerChild.layer setAllowsEdgeAntialiasing:YES];
                }
                [layerView addSubview:layerChild];
                
                CGSize size = layerChild.bounds.size;
                
                if(layer[@"style"]){
                    [self setStyle:layer[@"style"] ForLayerChild:layerChild ofSize:[NSValue valueWithCGSize:size]];
                }
                
                if(layer[@"action"]){
                    if(layer[@"name"]){
                        layerView.payload = [@{@"type": @"layer", @"action": layer[@"action"], @"name": layer[@"name"]} mutableCopy];
                    } else {
                        layerView.payload = [@{@"type": @"layer", @"action": layer[@"action"]} mutableCopy];
                    }
                }
                [rootView addSubview:layerView];
                [layers addObject:layerView];
            }
        }
    }
    return layers;
}

+ (void) addGestureRecognizersTo: (UIView *) view withStyle: (NSDictionary *)style{
    if(style[@"move"]){
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(layerMove:)];
        [panRecognizer setMinimumNumberOfTouches:1];
        [panRecognizer setMaximumNumberOfTouches:1];
        [view addGestureRecognizer:panRecognizer];
    }
    if(style[@"rotate"]){
        UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(layerRotate:)];
        view.multipleTouchEnabled = YES;
        [view addGestureRecognizer:rotateRecognizer];
    }
    if(style[@"resize"]){
        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(layerPinch:)];
        [view addGestureRecognizer:pinchRecognizer];
    }
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(layerTap:)];
    [view addGestureRecognizer:singleFingerTap];

}
+ (void) layerMove:(UIPanGestureRecognizer *)recognizer{
    UIView *view = [recognizer.view.window.subviews objectAtIndex:0];
    CGPoint translation = [recognizer translationInView:view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x+translation.x, recognizer.view.center.y+translation.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:view];
}
+ (void) layerRotate:(UIRotationGestureRecognizer *)recognizer{
    recognizer.view.transform = CGAffineTransformRotate( recognizer.view.transform, recognizer.rotation);
    recognizer.rotation = 0;
}
+ (void) layerPinch:(UIPinchGestureRecognizer *)recognizer{
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    recognizer.scale = 1;
}
+ (void) layerTap: (UITapGestureRecognizer *)recognizer{
    NSDictionary *action = recognizer.view.payload[@"action"];
    if(action){
        [[Jason client] call:action];
    }
    
}
+ (void)setStyle: (NSDictionary *)style ForLayerChild: (UIView *)layerChild ofSize: (NSValue *)sizeValue{
    CGSize size = [sizeValue CGSizeValue];
    
    CGFloat left = -1;
    CGFloat top = -1;
    CGFloat width = -1;
    CGFloat height = -1;
    CGFloat aspectRatioMult;
    if(style[@"ratio"]) {
        aspectRatioMult = 1/[JasonHelper parseRatio:style[@"ratio"]];
    } else {
        aspectRatioMult = (size.height / size.width);
    }
    
    if(style[@"width"]){
        width = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:style[@"width"]];
    }
    if(style[@"height"]){
        height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:style[@"height"]];
    }
    
    if([layerChild isKindOfClass:[UIImageView class]]){
        if(width && width > 0){
            if(height && height > 0){
            } else {
                height = width * aspectRatioMult;
            }
        }else if(height && height > 0){
            if(width && width > 0){
            } else {
                width = height / aspectRatioMult;
            }
        }
    }
    
    if(width < 0){
        width = layerChild.bounds.size.width;
    }
    if(height < 0){
        height = layerChild.bounds.size.height;
    }
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if(style[@"left"]){
        left = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:style[@"left"]];
    } else if(style[@"right"]){
        CGFloat screenWidth = screenRect.size.width;
        left = screenWidth - [JasonHelper pixelsInDirection:@"horizontal" fromExpression:style[@"right"]] - width;
    } else {
        left = 100.0f;
        
    }
    if(style[@"top"]){
        top = [JasonHelper pixelsInDirection:@"vertical" fromExpression:style[@"top"]];
    } else if(style[@"bottom"]){
        CGFloat screenHeight = screenRect.size.height;
        top = screenHeight - [JasonHelper pixelsInDirection:@"vertical" fromExpression:style[@"bottom"]] - height;
    } else {
        top = 100.0f;
    }
    
    UIView *layerView = (UIView *)layerChild.superview;
    
    if(style[@"padding"]){
        CGFloat padding = [style[@"padding"] floatValue];
        layerView.frame = CGRectMake(left, top, width + padding*2 , height + padding*2);
        layerView.layoutMargins = UIEdgeInsetsMake(padding, padding, padding, padding);
    } else {
        layerView.frame = CGRectMake(left, top, width, height);
    }
    
    if(style[@"corner_radius"]){
        layerChild.layer.cornerRadius = [style[@"corner_radius"] floatValue];
        layerChild.clipsToBounds = YES;
    } else {
        layerChild.layer.cornerRadius = 0;
    }
    
    layerChild.frame = CGRectMake(0,0,width, height);
}



+ (NSMutableDictionary *)stylesheet{
    if(_stylesheet == nil){
        _stylesheet = [[NSMutableDictionary alloc] init];
    }
    return _stylesheet;
}
+ (void)setStylesheet:(NSMutableDictionary *)stylesheet{
    if (stylesheet != _stylesheet){
        _stylesheet = [stylesheet mutableCopy];
    }
}

+ (NSMutableDictionary *)applyStylesheet:(NSDictionary *)item{
    NSMutableDictionary *new_style = [[NSMutableDictionary alloc] init];
    if(item[@"class"]){
        NSString *class_string = item[@"class"];
        NSMutableArray *classes = [[class_string componentsSeparatedByString:@" "] mutableCopy];
        [classes removeObject:@""];
        for(NSString *c in classes){
            NSString *class_selector = c;
            NSDictionary *class_style = self.stylesheet[class_selector];
            for(NSString *key in [class_style allKeys]){
                new_style[key] = class_style[key];
            }
        }
        
    }
    if(item[@"style"]){
        for(NSString *key in item[@"style"]){
            new_style[key] = item[@"style"][key];
        }
    }
    
    NSMutableDictionary *stylized_item = [item mutableCopy];
    stylized_item[@"style"] = new_style;
    return stylized_item;
}
@end
