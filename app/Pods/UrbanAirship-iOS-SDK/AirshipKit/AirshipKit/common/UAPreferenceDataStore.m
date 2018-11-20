/* Copyright 2017 Urban Airship and Contributors */

#import "UAPreferenceDataStore+Internal.h"

@interface UAPreferenceDataStore()
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, copy) NSString *keyPrefix;
@end


@implementation UAPreferenceDataStore

+ (instancetype)preferenceDataStoreWithKeyPrefix:(NSString *)keyPrefix {
    UAPreferenceDataStore *dataStore = [[UAPreferenceDataStore alloc] init];
    dataStore.defaults = [NSUserDefaults standardUserDefaults];
    dataStore.keyPrefix = keyPrefix;
    return dataStore;
}

- (NSString *)prefixKey:(NSString *)key {
    return [self.keyPrefix stringByAppendingString:key];
}

- (id)valueForKey:(NSString *)key {
    return [self.defaults valueForKey:[self prefixKey:key]];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    [self.defaults setValue:value forKey:[self prefixKey:key]];
}

- (void)removeObjectForKey:(NSString *)key {
    [self.defaults removeObjectForKey:[self prefixKey:key]];
}

- (id)objectForKey:(NSString *)key {
    return [self.defaults objectForKey:[self prefixKey:key]];
}

- (NSString *)stringForKey:(NSString *)key {
    return [self.defaults stringForKey:[self prefixKey:key]];
}

- (NSArray *)arrayForKey:(NSString *)key {
    return [self.defaults arrayForKey:[self prefixKey:key]];
}

- (NSDictionary *)dictionaryForKey:(NSString *)key {
    return [self.defaults dictionaryForKey:[self prefixKey:key]];
}

- (NSData *)dataForKey:(NSString *)key {
    return [self.defaults dataForKey:[self prefixKey:key]];
}

- (NSArray *)stringArrayForKey:(NSString *)key {
    return [self.defaults stringArrayForKey:[self prefixKey:key]];
}

- (NSInteger)integerForKey:(NSString *)key {
    return [self.defaults integerForKey:[self prefixKey:key]];
}

- (float)floatForKey:(NSString *)key {
    return [self.defaults floatForKey:[self prefixKey:key]];
}

- (double)doubleForKey:(NSString *)key {
    return [self.defaults doubleForKey:[self prefixKey:key]];
}

- (BOOL)boolForKey:(NSString *)key {
    return [self.defaults boolForKey:[self prefixKey:key]];
}

- (NSURL *)URLForKey:(NSString *)key {
    return [self.defaults URLForKey:[self prefixKey:key]];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    [self.defaults setInteger:value forKey:[self prefixKey:key]];
}

- (void)setFloat:(float)value forKey:(NSString *)key {
    [self.defaults setFloat:value forKey:[self prefixKey:key]];
}

- (void)setDouble:(double)value forKey:(NSString *)key {
    [self.defaults setDouble:value forKey:[self prefixKey:key]];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self.defaults setBool:value forKey:[self prefixKey:key]];
}

- (void)setURL:(NSURL *)value forKey:(NSString *)key {
    [self.defaults setURL:value forKey:[self prefixKey:key]];
}

- (void)setObject:(id)value forKey:(NSString *)key {
    [self.defaults setObject:value forKey:[self prefixKey:key]];
}

- (void)migrateUnprefixedKeys:(NSArray *)keys {
    
    for (NSString *key in keys) {
        id value = [self.defaults objectForKey:key];
        if (value) {
            [self.defaults setValue:value forKey:[self prefixKey:key]];
            [self.defaults removeObjectForKey:key];
        }
    }
}

- (void)removeAll {
    for (NSString *key in [[self.defaults dictionaryRepresentation] allKeys]) {
        if ([key hasPrefix:self.keyPrefix]) {
            [self.defaults removeObjectForKey:key];
        }
    }
}

@end
