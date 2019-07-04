//
//  JasonComponentFactory.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein.
//  Copyright © 2019 Jasonelle Team.
#import "JasonComponentFactory.h"
#import <DTFoundation/DTLog.h>

@implementation JasonComponentFactory

static NSMutableDictionary * _imageLoaded = nil;
static NSMutableDictionary * _stylesheet = nil;

+ (UIView *) build: (UIView *) component
          withJSON:(NSDictionary *) child
       withOptions:(NSMutableDictionary *) options
{
    
    UIView * empty = [UIView new];
    NSString * type = [child[@"type"]
                       stringByTrimmingCharactersInSet:
                       [NSCharacterSet
                        whitespaceAndNewlineCharacterSet]];
    
    DTLogDebug(@"Start to Create Component %@ With JSON %@ and Options %@", type, child, options);
    
    if(!type || [type isEqualToString:@""])
    {
        DTLogWarning(@"No type for component provided. %@", child);
        return empty;
    }
    
    NSString * capitalizedType = [child[@"type"] capitalizedString];
    NSString * componentClassName = [NSString stringWithFormat:@"Jason%@Component", capitalizedType];
    
    if(componentClassName)
    {
        Class<JasonComponentProtocol> ComponentClass = NSClassFromString(componentClassName);
        
        if(!ComponentClass)
        {
            /**
             
             Maybe is a Swift Component. NSClassFromString return nil on these.
             see https://stackoverflow.com/questions/28706602/nsclassfromstring-using-a-swift-file
             and https://github.com/Jasonette/JASONETTE-iOS/issues/363#event-2459148079
             
             If you are using Swift for an Extension then try including the @objc() annotation.
             
             @objc(MySwiftClass)
             class MySwiftClass {
             ...
             }
             
             */
            NSString * prefix = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
            componentClassName = [NSString stringWithFormat:@"%@.%@", prefix, componentClassName];
            ComponentClass = NSClassFromString(componentClassName);
        }
        
        if(!ComponentClass)
        {
            // Ok if we reach this point and no ComponentClass is found then return empty view.
            // but log a warning
            DTLogWarning(@"Component Not Found %@ %@", componentClassName, child);
            return empty;
        }
        
        DTLogDebug(@"Begin Preparing Styles for Component");
        
        child = [self applyStylesheet:child];
        
        UIView * styledComponent = [ComponentClass
                                    build:component
                                    withJSON:child
                                    withOptions:options];
        
        if (child[@"focus"])
        {
            DTLogDebug(@"%@ contain focus", child);
            [[Jason client] getVC].focusField = styledComponent;
        }
        
        [styledComponent setNeedsLayout];
        [styledComponent layoutIfNeeded];
        return styledComponent;
    }
    
    DTLogWarning(@"Component Type Not Found %@ %@", type, child);
    return empty;
}


+ (NSMutableDictionary *) applyStylesheet: (NSDictionary *) json
{
    // This function pre process the style of a component and returns a
    // new dictionary that would be processed by the component class.
    
    NSMutableDictionary * styles = [NSMutableDictionary new];
    
    if(json[@"class"])
    {
        DTLogDebug(@"Component contains class option. Obtaining corresponding stylesheets");
        
        NSString * classValue = json[@"class"];
        NSMutableArray * classes = [[classValue componentsSeparatedByString:@" "] mutableCopy];
        [classes removeObject:@""];
        
        for(NSString * classSelector in classes)
        {
            NSDictionary * classStyle = self.stylesheet[classSelector];
            
            for(NSString * key in [classStyle allKeys])
            {
                styles[key] = classStyle[key];
            }
        }
        
    }
    
    if(json[@"style"])
    {
        for(NSString * key in json[@"style"])
        {
            styles[key] = json[@"style"][key];
        }
    }
    
    NSMutableDictionary * stylizedComponent = [json mutableCopy];
    stylizedComponent[@"style"] = styles;
    
    DTLogDebug(@"Styles Successfully Obtained %@", stylizedComponent);
    
    return stylizedComponent;
}


+ (NSMutableDictionary *) imageLoaded
{
    if (!_imageLoaded)
    {
        _imageLoaded = [NSMutableDictionary new];
    }
    
    return _imageLoaded;
}

+ (void) setImageLoaded: (NSMutableDictionary *) imageLoaded
{
    if (imageLoaded != _imageLoaded)
    {
        _imageLoaded = [imageLoaded mutableCopy];
    }
}

+ (NSMutableDictionary *) stylesheet
{
    if(!_stylesheet)
    {
        _stylesheet = [NSMutableDictionary new];
    }
    
    return _stylesheet;
}

+ (void) setStylesheet: (NSMutableDictionary *) stylesheet
{
    if (stylesheet != _stylesheet)
    {
        _stylesheet = [stylesheet mutableCopy];
    }
}

@end
