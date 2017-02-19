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

- (id) safeGet:(NSString *) key
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

- (id) safeGetKeys:(NSArray<NSString *> *) keys
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

- (nullable NSString *) getStringWithKeyNames:(nonnull NSArray<NSString *> *) keys
{
    return (NSString *) [self safeGetKeys:keys];
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
@end
