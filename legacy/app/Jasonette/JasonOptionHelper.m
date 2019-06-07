//
//  JasonOptionHelper.m
//  Jasonette
//
//  Created by Camilo Castro <camilo@ninjas.cl> on 18-02-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonOptionHelper.h"

@implementation JasonOptionHelper

#pragma mark - Private

- (nullable id) safeGet:(nonnull NSString *) key
{
    if (self.options)
    {
        if (self.options[key])
        {
            return self.options[key];
        }
    }
    
    return nil;
}

- (nullable id) safeGetKeys:(nonnull NSArray<NSString *> *) keys
{
    id result = nil;
    
    for (NSString * key in keys)
    {
        if([self safeGet:key])
        {
            result = [self safeGet:key];
        }
    }
    
    return result;
}

- (nullable NSString *) emptyAsNil:(nullable NSString *) string
{
    NSString  * result = @"";
    
    if(string)
    {
        
        result = [string
                  stringByTrimmingCharactersInSet:[NSCharacterSet
                                                   whitespaceAndNewlineCharacterSet]];
    }
    
    return ([result isEqualToString:@""] ? nil : string);
}

#pragma mark - Public

- (nonnull instancetype) initWithOptions:(nonnull NSDictionary *) options
{
    self = [super init];
    
    if (self)
    {
        self.options = options;
    }
    
    return self;
}

- (BOOL) hasParams:(nonnull NSArray<NSString *> *) params
{
    for (NSString * param in params)
    {
        if (!self.options || !self.options[param])
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL) hasParam:(nonnull NSString *) param
{
    return [self hasParams:@[param]];
}

- (nullable id) get: (nonnull NSString *) key
{
    return [self safeGet:key];
}

- (nullable id) getWithKeys: (nonnull NSArray <NSString *> *) keys
{
    return [self safeGetKeys:keys];
}

- (nullable NSString *) getString:(nonnull NSString *) key
{
    return (NSString *) [self safeGet:key];
}

- (nullable NSString *) getStringWithEmptyAsNil:(nonnull NSString *) key
{
    return [self emptyAsNil:[self getString:key]];
}


- (nullable NSString *) getStringWithKeyNames:(nonnull NSArray<NSString *> *) keys
{
    return (NSString *) [self safeGetKeys:keys];
}

- (nullable NSString *) getStringWithKeyNamesWithEmptyAsNil:(nonnull NSArray<NSString *> *) keys
{
    return [self emptyAsNil:[self getStringWithKeyNames:keys]];
}

- (nullable NSDictionary *) getDict: (nonnull NSString *) key
{
    return (NSDictionary *) [self safeGet:key];
}

- (nullable NSDictionary *) getDictWithKeyNames:(nonnull NSArray<NSString *> *) keys
{
    return (NSDictionary *) [self safeGetKeys:keys];
}

- (nullable NSNumber *) getNumber: (nonnull NSString *) key
{
    return (NSNumber *) [self safeGet:key];
}

- (nullable NSNumber *) getNumberWithKeyNames:(nonnull NSArray<NSString *> *) keys
{
    return (NSNumber *) [self safeGetKeys:keys];
}

- (BOOL) getBoolean: (nonnull NSString *) key
{
    return [[self getNumber:key] boolValue];
}

- (BOOL) getBooleanWithKeyNames:(nonnull NSArray<NSString *> *) keys
{
    return [[self getNumberWithKeyNames:keys] boolValue];
}

@end
