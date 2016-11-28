//
//  JasonComponentFactory.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonComponentFactory.h"

@implementation JasonComponentFactory

static NSMutableDictionary *_imageLoaded = nil;
static NSMutableDictionary *_stylesheet = nil;

+ (UIView *)build:(UIView *)component withJSON:(NSDictionary *)child withOptions:(NSMutableDictionary *)options{
    
    NSString *capitalizedType = [child[@"type"] capitalizedString];
    NSString *componentClassName = [NSString stringWithFormat:@"Jason%@Component", capitalizedType];
    if(componentClassName){
        Class<JasonComponentProtocol> ComponentClass = NSClassFromString(componentClassName);
        child = [self applyStylesheet:child];
        UIView *generated_component = [ComponentClass build:component withJSON:child withOptions:options];
        [generated_component setNeedsLayout];
        [generated_component layoutIfNeeded];
        return generated_component;
    } else {
        return [[UIView alloc] init];
    }
}

+ (NSMutableDictionary *)imageLoaded{
    if (_imageLoaded == nil) {
        _imageLoaded = [[NSMutableDictionary alloc] init];
    }
    return _imageLoaded;
}
+ (void)setImageLoaded:(NSMutableDictionary *)imageLoaded{
    if (imageLoaded != _imageLoaded) {
        _imageLoaded = [imageLoaded mutableCopy];
    }
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

// Common
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
