/* Copyright 2017 Urban Airship and Contributors */

#import "UAJSONValueMatcher.h"
#import "NSJSONSerialization+UAAdditions.h"

@interface UAJSONValueMatcher ()
@property(nonatomic, strong) NSNumber *atLeast;
@property(nonatomic, strong) NSNumber *atMost;
@property(nonatomic, strong) NSNumber *equalsNumber;
@property(nonatomic, copy) NSString *equalsString;
@property(nonatomic, assign) NSNumber *isPresent;
@end


NSString *const UAJSONValueMatcherAtMost = @"at_most";
NSString *const UAJSONValueMatcherAtLeast = @"at_least";
NSString *const UAJSONValueMatcherEquals = @"equals";
NSString *const UAJSONValueMatcherIsPresent = @"is_present";

NSString * const UAJSONValueMatcherErrorDomain = @"com.urbanairship.json_value_matcher";


@implementation UAJSONValueMatcher

- (NSDictionary *)payload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];

    [payload setValue:self.equalsNumber ?: self.equalsString forKey:UAJSONValueMatcherEquals];
    [payload setValue:self.atLeast forKey:UAJSONValueMatcherAtLeast];
    [payload setValue:self.atMost forKey:UAJSONValueMatcherAtMost];
    [payload setValue:self.isPresent forKey:UAJSONValueMatcherIsPresent];

    return payload;
}

- (BOOL)evaluateObject:(id)value {
    if (self.isPresent != nil) {
        return [self.isPresent boolValue] == (value != nil);
    }


    if (self.equalsString && ![self.equalsString isEqual:value]) {
        return NO;
    }

    NSNumber *numberValue = [value isKindOfClass:[NSNumber class]] ? value : nil;

    if (self.equalsNumber && !(numberValue && [self.equalsNumber isEqualToNumber:numberValue])) {
        return NO;
    }

    if (self.atLeast && !(numberValue && [self.atLeast compare:numberValue] != NSOrderedDescending)) {
        return NO;
    }

    if (self.atMost && !(numberValue && [self.atMost compare:numberValue] != NSOrderedAscending)) {
        return NO;
    }
    
    return YES;
}

+ (instancetype)matcherWhereNumberAtLeast:(NSNumber *)number {
    UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
    matcher.atLeast = number;
    return matcher;
}

+ (instancetype)matcherWhereNumberAtLeast:(NSNumber *)lowerNumber atMost:(NSNumber *)higherNumber {
    UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
    matcher.atLeast = lowerNumber;
    matcher.atMost = higherNumber;
    return matcher;
}

+ (instancetype)matcherWhereNumberAtMost:(NSNumber *)number {
    UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
    matcher.atMost = number;
    return matcher;
}

+ (instancetype)matcherWhereNumberEquals:(NSNumber *)number {
    UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
    matcher.equalsNumber = number;
    return matcher;
}

+ (instancetype)matcherWhereStringEquals:(NSString *)string {
    UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
    matcher.equalsString = string;
    return matcher;
}

+ (instancetype)matcherWhereValueIsPresent:(BOOL)present {
    UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
    matcher.isPresent = @(present);
    return matcher;
}

+ (instancetype)matcherWithJSON:(id)json error:(NSError **)error {
    if (![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid object: %@", json];
            *error =  [NSError errorWithDomain:UAJSONValueMatcherErrorDomain
                                          code:UAJSONValueMatcherErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    if ([self isNumericMatcherExpression:json]) {
        UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
        matcher.atMost = json[UAJSONValueMatcherAtMost];
        matcher.atLeast = json[UAJSONValueMatcherAtLeast];
        matcher.equalsNumber = json[UAJSONValueMatcherEquals];
        return matcher;
    }

    if ([self isStringMatcherExpression:json]) {
        UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
        matcher.equalsString = json[UAJSONValueMatcherEquals];
        return matcher;
    }

    if ([self isPresentMatcherExpression:json]) {
        UAJSONValueMatcher *matcher = [[UAJSONValueMatcher alloc] init];
        matcher.isPresent = json[UAJSONValueMatcherIsPresent];
        return matcher;
    }

    if (error) {
        NSString *msg = [NSString stringWithFormat:@"Invalid value matcher: %@", json];
        *error =  [NSError errorWithDomain:UAJSONValueMatcherErrorDomain
                                      code:UAJSONValueMatcherErrorCodeInvalidJSON
                                  userInfo:@{NSLocalizedDescriptionKey:msg}];
    }


    // Invalid
    return nil;
}


+ (BOOL)isNumericMatcherExpression:(NSDictionary *)expression {
    // "equals": number | "at_least": number | "at_most": number | "at_least": number, "at_most": number
    if ([expression count] == 0 || [expression count] > 2) {
        return NO;
    }

    if ([expression count] == 1) {
        return [expression[UAJSONValueMatcherEquals] isKindOfClass:[NSNumber class]] ||
        [expression[UAJSONValueMatcherAtLeast] isKindOfClass:[NSNumber class]] ||
        [expression[UAJSONValueMatcherAtMost] isKindOfClass:[NSNumber class]];
    }

    if ([expression count] == 2) {
        return [expression[UAJSONValueMatcherAtLeast] isKindOfClass:[NSNumber class]] &&
        [expression[UAJSONValueMatcherAtMost] isKindOfClass:[NSNumber class]];
    }

    return [expression[UAJSONValueMatcherEquals] isKindOfClass:[NSNumber class]];
}

+ (BOOL)isStringMatcherExpression:(NSDictionary *)expression {
    if ([expression count] != 1) {
        return NO;
    }

    id subexp = expression[UAJSONValueMatcherEquals];
    return [subexp isKindOfClass:[NSString class]];
}

+ (BOOL)isPresentMatcherExpression:(NSDictionary *)expression {
    if ([expression count] != 1) {
        return NO;
    }

    id subexp = expression[UAJSONValueMatcherIsPresent];

    // Note: it's not possible to reflect a pure boolean value here so this will accept non-binary numbers as well
    return [subexp isKindOfClass:[NSNumber class]];
}


@end
