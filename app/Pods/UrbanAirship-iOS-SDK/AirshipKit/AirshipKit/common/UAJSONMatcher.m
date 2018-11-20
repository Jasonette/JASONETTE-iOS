/* Copyright 2017 Urban Airship and Contributors */

#import "UAJSONMatcher.h"
#import "UAJSONValueMatcher.h"

@interface UAJSONMatcher()
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSArray *scope;
@property (nonatomic, strong) UAJSONValueMatcher *valueMatcher;
@end

NSString *const UAJSONMatcherKey = @"key";
NSString *const UAJSONMatcherScope = @"scope";
NSString *const UAJSONMatcherValue = @"value";

NSString * const UAJSONMatcherErrorDomain = @"com.urbanairship.json_matcher";

@implementation UAJSONMatcher

- (instancetype)initWithValueMatcher:(UAJSONValueMatcher *)valueMatcher key:(NSString *)key scope:(NSArray<NSString *>*)scope {
    self = [super self];
    if (self) {
        self.valueMatcher = valueMatcher;
        self.key = key;
        self.scope = scope;
    }

    return self;
}

- (NSDictionary *)payload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:self.valueMatcher.payload forKey:UAJSONMatcherValue];
    [payload setValue:self.key forKey:UAJSONMatcherKey];
    [payload setValue:self.scope forKey:UAJSONMatcherScope];
    return payload;
}

- (BOOL)evaluateObject:(id)value {
    id object = value;

    NSMutableArray *paths = [NSMutableArray array];
    if (self.scope) {
        [paths addObjectsFromArray:self.scope];
    }

    if (self.key) {
        [paths addObject:self.key];
    }

    for (NSString *path in paths) {
        if (![object isKindOfClass:[NSDictionary class]]) {
            object = nil;
            break;
        }

        object = object[path];
    }

    return [self.valueMatcher evaluateObject:object];
}

+ (instancetype)matcherWithValueMatcher:(UAJSONValueMatcher *)valueMatcher {
    return [[UAJSONMatcher alloc] initWithValueMatcher:valueMatcher key:nil scope:nil];
}

+ (instancetype)matcherWithValueMatcher:(UAJSONValueMatcher *)valueMatcher key:(NSString *)key {
    return [[UAJSONMatcher alloc] initWithValueMatcher:valueMatcher key:key scope:nil];
}

+ (instancetype)matcherWithValueMatcher:(UAJSONValueMatcher *)valueMatcher key:(NSString *)key scope:(NSArray<NSString *>*)scope {
    return [[UAJSONMatcher alloc] initWithValueMatcher:valueMatcher key:key scope:scope];
}

+ (instancetype)matcherWithJSON:(id)json error:(NSError **)error {
    if (![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid object: %@", json];
            *error =  [NSError errorWithDomain:UAJSONMatcherErrorDomain
                                          code:UAJSONMatcherErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    NSDictionary *info = json;
  
    // Optional scope
    NSArray *scope;
    if (info[UAJSONMatcherScope]) {
        if ([info[UAJSONMatcherScope] isKindOfClass:[NSString class]]) {
            scope = @[info[UAJSONMatcherScope]];
        } else if ([info[UAJSONMatcherScope] isKindOfClass:[NSArray class]]) {
            NSMutableArray *mutableScope = [NSMutableArray array];
            for (id value in info[UAJSONMatcherScope]) {
                if (![value isKindOfClass:[NSString class]]) {
                    if (error) {
                        NSString *msg = [NSString stringWithFormat:@"Scope must be either an array of strings or a string. Invalid value: %@", value];
                        *error =  [NSError errorWithDomain:UAJSONMatcherErrorDomain
                                                      code:UAJSONMatcherErrorCodeInvalidJSON
                                                  userInfo:@{NSLocalizedDescriptionKey:msg}];
                    }

                    return nil;
                }

                [mutableScope addObject:value];
            }

            scope = [mutableScope copy];
        } else {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Scope must be either an array of strings or a string. Invalid value: %@", scope];
                *error =  [NSError errorWithDomain:UAJSONMatcherErrorDomain
                                              code:UAJSONMatcherErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }

            return nil;
        }
    }

    // Optional key
    NSString *key;
    if (info[UAJSONMatcherKey]) {
        if (![info[UAJSONMatcherKey] isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Key must be a string. Invalid value: %@", key];
                *error =  [NSError errorWithDomain:UAJSONMatcherErrorDomain
                                              code:UAJSONMatcherErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }

            return nil;
        }

        key = info[UAJSONMatcherKey];
    }

    // Required value
    UAJSONValueMatcher *valueMatcher = [UAJSONValueMatcher matcherWithJSON:info[UAJSONMatcherValue] error:error];
    if (!valueMatcher) {
        return nil;
    }

    return [[UAJSONMatcher alloc] initWithValueMatcher:valueMatcher key:key scope:scope];
}

@end
