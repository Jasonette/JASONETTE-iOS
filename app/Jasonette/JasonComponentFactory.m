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

        if (child[@"focus"]) {
            [[Jason client] getVC].focusField = generated_component;
        }

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
        [_stylesheet addEntriesFromDictionary:stylesheet];
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
    
    if (new_style[@"ratio"] && new_style[@"width"] && !new_style[@"height"]) {
        CGFloat aspectHeight = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:new_style[@"width"]] / [new_style[@"ratio"] floatValue];
        new_style[@"height"] = [[NSNumber numberWithFloat:aspectHeight] stringValue];
    } else if (new_style[@"ratio"] && new_style[@"height"] && !new_style[@"width"]) {
        CGFloat aspectWidth = [JasonHelper pixelsInDirection:@"vertical" fromExpression:new_style[@"height"]] * [new_style[@"ratio"] floatValue];
        new_style[@"width"] = [[NSNumber numberWithFloat:aspectWidth] stringValue];
    }
    
    if (new_style[@"max_width"]) {
        CGFloat maxWidth = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:new_style[@"max_width"]];
        CGFloat width = [new_style[@"width"] floatValue];
        if (width > maxWidth && new_style[@"height"]) {
            CGFloat ratioMult = maxWidth / width;
            new_style[@"height"] = [[NSNumber numberWithFloat:([new_style[@"height"] floatValue] * ratioMult)] stringValue];
            new_style[@"width"] = [[NSNumber numberWithFloat:maxWidth] stringValue];
        }
    }

    if (new_style[@"max_height"]) {
        CGFloat maxHeight = [JasonHelper pixelsInDirection:@"vertical" fromExpression:new_style[@"max_height"]];
        CGFloat height = [new_style[@"height"] floatValue];
        if (height > maxHeight && new_style[@"width"]) {
            CGFloat ratioMult = maxHeight / height;
            new_style[@"width"] = [[NSNumber numberWithFloat:([new_style[@"width"] floatValue] * ratioMult)] stringValue];
            new_style[@"height"] = [[NSNumber numberWithFloat:maxHeight] stringValue];
        }
    }

    NSMutableDictionary *stylized_item = [item mutableCopy];
    stylized_item[@"style"] = new_style;
    return stylized_item;
}

@end
