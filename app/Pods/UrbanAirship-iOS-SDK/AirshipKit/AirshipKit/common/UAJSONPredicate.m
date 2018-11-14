/* Copyright 2017 Urban Airship and Contributors */

#import "UAJSONPredicate.h"
#import "UAJSONMatcher.h"

@interface UAJSONPredicate()
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSArray *subpredicates;
@property (nonatomic, strong) UAJSONMatcher *jsonMatcher;
@end

NSString *const UAJSONPredicateAndType = @"and";
NSString *const UAJSONPredicateOrType = @"or";
NSString *const UAJSONPredicateNotType = @"not";

NSString * const UAJSONPredicateErrorDomain = @"com.urbanairship.json_predicate";


@implementation UAJSONPredicate

- (instancetype)initWithType:(NSString *)type
                 jsonMatcher:(UAJSONMatcher *)jsonMatcher
               subpredicates:(NSArray *)subpredicates {

    self = [super self];
    if (self) {
        self.type = type;
        self.jsonMatcher = jsonMatcher;
        self.subpredicates = subpredicates;
    }

    return self;
}

- (NSDictionary *)payload {
    if (self.type) {
        NSMutableArray *subpredicatePayloads = [NSMutableArray array];
        for (UAJSONPredicate *predicate in self.subpredicates) {
            [subpredicatePayloads addObject:predicate.payload];
        }

        return @{ self.type : [subpredicatePayloads copy] };
    }

    return self.jsonMatcher.payload;
}

- (BOOL)evaluateObject:(id)object {
    // And
    if ([self.type isEqualToString:UAJSONPredicateAndType]) {
        for (UAJSONPredicate *predicate in self.subpredicates) {
            if (![predicate evaluateObject:object]) {
                return NO;
            }
        }
        return YES;
    }

    // Or
    if ([self.type isEqualToString:UAJSONPredicateOrType]) {
        for (UAJSONPredicate *predicate in self.subpredicates) {
            if ([predicate evaluateObject:object]) {
                return YES;
            }
        }
        return NO;
    }

    // Not
    if ([self.type isEqualToString:UAJSONPredicateNotType]) {
        // The factory methods prevent NOT from ever having more than 1 predicate
        return ![[self.subpredicates firstObject] evaluateObject:object];
    }

    // Matcher
    return [self.jsonMatcher evaluateObject:object];
}

+ (instancetype)predicateWithJSONMatcher:(UAJSONMatcher *)matcher {
    return [[UAJSONPredicate alloc] initWithType:nil jsonMatcher:matcher subpredicates:nil];
}

+ (instancetype)andPredicateWithSubpredicates:(NSArray<UAJSONPredicate*>*)subpredicates {
    return [[UAJSONPredicate alloc] initWithType:UAJSONPredicateAndType jsonMatcher:nil subpredicates:subpredicates];
}

+ (instancetype)orPredicateWithSubpredicates:(NSArray<UAJSONPredicate*>*)subpredicates {
    return [[UAJSONPredicate alloc] initWithType:UAJSONPredicateOrType jsonMatcher:nil subpredicates:subpredicates];

}

+ (instancetype)notPredicateWithSubpredicate:(UAJSONPredicate *)subpredicate {
    return [[UAJSONPredicate alloc] initWithType:UAJSONPredicateNotType jsonMatcher:nil subpredicates:@[subpredicate]];
}

+ (instancetype)predicateWithJSON:(id)json error:(NSError **)error {

    if (![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid object: %@", json];
            *error =  [NSError errorWithDomain:UAJSONPredicateErrorDomain
                                          code:UAJSONPredicateErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    NSString *type;
    if (json[UAJSONPredicateAndType]) {
        type = UAJSONPredicateAndType;
    } else if (json[UAJSONPredicateOrType]) {
        type = UAJSONPredicateOrType;
    } else if (json[UAJSONPredicateNotType]) {
        type = UAJSONPredicateNotType;
    }

    if (type && [json count] != 1) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Invalid JSON: %@", json];
            *error =  [NSError errorWithDomain:UAJSONPredicateErrorDomain
                                          code:UAJSONPredicateErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    if (type) {
        NSMutableArray *subpredicates = [NSMutableArray array];
        id typeInfo = json[type];

        if (![typeInfo isKindOfClass:[NSArray class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid object: %@", typeInfo];
                *error =  [NSError errorWithDomain:UAJSONPredicateErrorDomain
                                              code:UAJSONPredicateErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }

            return nil;
        }

        if (([type isEqualToString:UAJSONPredicateNotType] && [typeInfo count] != 1) || [typeInfo count] == 0) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"A `not` predicate must contain a single sub predicate or matcher."];
                *error =  [NSError errorWithDomain:UAJSONPredicateErrorDomain
                                              code:UAJSONPredicateErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }

        for (id subpredicateInfo in typeInfo) {
            UAJSONPredicate *predicate = [UAJSONPredicate predicateWithJSON:subpredicateInfo error:error];
            if (!predicate) {
                return nil;
            }

            [subpredicates addObject:predicate];
        }

        return [[UAJSONPredicate alloc] initWithType:type jsonMatcher:nil subpredicates:subpredicates];
    }

    UAJSONMatcher *jsonMatcher = [UAJSONMatcher matcherWithJSON:json error:error];
    if (jsonMatcher) {
        return [[UAJSONPredicate alloc] initWithType:nil jsonMatcher:jsonMatcher subpredicates:nil];
    }

    return nil;
}

@end
