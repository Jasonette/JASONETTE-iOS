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
    if(json[@"url"]){
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
        
        UIImageView * btnImage = [[UIImageView alloc] init];
        
        if(![url containsString:@"{{"] && ![url containsString:@"}}"]){
            [btnImage sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder_image completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if(!error){
                    JasonComponentFactory.imageLoaded[url] = [NSValue valueWithCGSize:i.size];
                    [component setBackgroundImage:btnImage.image forState:UIControlStateNormal];
                }
            }];
        }
        [component setTitle:@"" forState:UIControlStateNormal];
        
    }
    else{
        [component setBackgroundImage:nil forState:UIControlStateNormal];
        [component setTitle:json[@"text"] forState:UIControlStateNormal];
    }
    [self stylize:json component:component];
    
    if(json[@"action"]){
        component.payload = [@{@"action": json[@"action"]} mutableCopy];
    }
    [component removeTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [component addTarget:self.class action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    // 1. Apply Common Style
    [self stylize:json component:component];
    
    // 2. Custom Style
    NSDictionary *style = json[@"style"];
    if(style){
        [self stylize:json text:component.titleLabel];
        
        if(style[@"color"]){
            NSString *colorHex = style[@"color"];
            component.tintColor = [JasonHelper colorwithHexString:colorHex alpha:1.0];
            UIColor *c = [JasonHelper colorwithHexString:colorHex alpha:1.0];
            [component setTitleColor:c forState:UIControlStateNormal];
        } else {
            component.tintColor = [UIColor whiteColor];
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
