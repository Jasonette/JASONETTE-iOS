/* Copyright 2017 Urban Airship and Contributors */

#import "UAScheduleTrigger+Internal.h"
#import "UAJSONPredicate.h"
#import "UARegionEvent+Internal.h"

// JSON Keys
NSString *const UAScheduleTriggerTypeKey = @"type";
NSString *const UAScheduleTriggerPredicateKey = @"predicate";
NSString *const UAScheduleTriggerGoalKey = @"goal";

// Trigger Names
NSString *const UAScheduleTriggerAppInitName = @"app_init";
NSString *const UAScheduleTriggerAppForegroundName = @"foreground";
NSString *const UAScheduleTriggerAppBackgroundName = @"background";
NSString *const UAScheduleTriggerRegionEnterName = @"region_enter";
NSString *const UAScheduleTriggerRegionExitName = @"region_exit";
NSString *const UAScheduleTriggerCustomEventCountName = @"custom_event_count";
NSString *const UAScheduleTriggerCustomEventValueName = @"custom_event_value";
NSString *const UAScheduleTriggerScreenName = @"screen";

NSString * const UAScheduleTriggerErrorDomain = @"com.urbanairship.schedule_trigger";

@implementation UAScheduleTrigger

- (instancetype)initWithType:(UAScheduleTriggerType)type goal:(NSNumber *)goal predicate:(UAJSONPredicate *)predicate {
    self = [super self];
    if (self) {
        self.goal = goal;
        self.predicate = predicate;
        self.type = type;
    }

    return self;
}

+ (instancetype)triggerWithType:(UAScheduleTriggerType)type goal:(NSNumber *)goal predicate:(UAJSONPredicate *)predicate {
    return [[UAScheduleTrigger alloc] initWithType:type goal:goal predicate:predicate];
}

+ (instancetype)appInitTriggerWithCount:(NSUInteger)count {
    return [UAScheduleTrigger triggerWithType:UAScheduleTriggerAppInit goal:@(count) predicate:nil];
}

+ (instancetype)foregroundTriggerWithCount:(NSUInteger)count {
    return [UAScheduleTrigger triggerWithType:UAScheduleTriggerAppForeground goal:@(count) predicate:nil];
}

+ (instancetype)backgroundTriggerWithCount:(NSUInteger)count {
    return [UAScheduleTrigger triggerWithType:UAScheduleTriggerAppBackground goal:@(count) predicate:nil];
}

+ (instancetype)regionEnterTriggerForRegionID:(NSString *)regionID count:(NSUInteger)count {
    UAJSONValueMatcher *valueMatcher = [UAJSONValueMatcher matcherWhereStringEquals:regionID];
    UAJSONMatcher *jsonMatcher = [UAJSONMatcher matcherWithValueMatcher:valueMatcher key:kUARegionIDKey];
    UAJSONPredicate *predicate = [UAJSONPredicate predicateWithJSONMatcher:jsonMatcher];

    return [UAScheduleTrigger triggerWithType:UAScheduleTriggerRegionEnter
                                         goal:@(count)
                                    predicate:predicate];
}

+ (instancetype)regionExitTriggerForRegionID:(NSString *)regionID count:(NSUInteger)count {
    UAJSONValueMatcher *valueMatcher = [UAJSONValueMatcher matcherWhereStringEquals:regionID];
    UAJSONMatcher *jsonMatcher = [UAJSONMatcher matcherWithValueMatcher:valueMatcher key:kUARegionIDKey];
    UAJSONPredicate *predicate = [UAJSONPredicate predicateWithJSONMatcher:jsonMatcher];

    return [UAScheduleTrigger triggerWithType:UAScheduleTriggerRegionExit
                                         goal:@(count)
                                    predicate:predicate];
}

+ (instancetype)screenTriggerForScreenName:(NSString *)screenName count:(NSUInteger)count {
    UAJSONValueMatcher *valueMatcher = [UAJSONValueMatcher matcherWhereStringEquals:screenName];
    UAJSONMatcher *jsonMatcher = [UAJSONMatcher matcherWithValueMatcher:valueMatcher];
    UAJSONPredicate *predicate = [UAJSONPredicate predicateWithJSONMatcher:jsonMatcher];

    return [UAScheduleTrigger triggerWithType:UAScheduleTriggerScreen
                                         goal:@(count)
                                    predicate:predicate];
}

+ (instancetype)customEventTriggerWithPredicate:(UAJSONPredicate *)predicate count:(NSUInteger)count {
    return [UAScheduleTrigger triggerWithType:UAScheduleTriggerCustomEventCount
                                         goal:@(count)
                                    predicate:predicate];
}

+ (instancetype)customEventTriggerWithPredicate:(UAJSONPredicate *)predicate value:(NSNumber *)value {
    return [UAScheduleTrigger triggerWithType:UAScheduleTriggerCustomEventValue
                                         goal:value
                                    predicate:predicate];
}


+ (instancetype)triggerWithJSON:(id)json error:(NSError **)error {
    if (![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid object: %@", json];
            *error =  [NSError errorWithDomain:UAScheduleTriggerErrorDomain
                                          code:UAScheduleTriggerErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    UAScheduleTriggerType triggerType;

    NSString *triggerTypeString = [json[UAScheduleTriggerTypeKey] lowercaseString];
    if ([UAScheduleTriggerAppForegroundName isEqualToString:triggerTypeString]) {
        triggerType = UAScheduleTriggerAppForeground;
    } else if ([UAScheduleTriggerAppBackgroundName isEqualToString:triggerTypeString]) {
        triggerType = UAScheduleTriggerAppBackground;
    } else if ([UAScheduleTriggerRegionEnterName isEqualToString:triggerTypeString]) {
        triggerType = UAScheduleTriggerRegionEnter;
    } else if ([UAScheduleTriggerRegionExitName isEqualToString:triggerTypeString]) {
        triggerType = UAScheduleTriggerRegionExit;
    } else if ([UAScheduleTriggerCustomEventCountName isEqualToString:triggerTypeString]) {
        triggerType = UAScheduleTriggerCustomEventCount;
    } else if ([UAScheduleTriggerCustomEventValueName isEqualToString:triggerTypeString]) {
        triggerType = UAScheduleTriggerCustomEventValue;
    } else if ([UAScheduleTriggerScreenName isEqualToString:triggerTypeString]) {
        triggerType = UAScheduleTriggerScreen;
    } else if ([UAScheduleTriggerAppInitName isEqualToString:triggerTypeString]) {
        triggerType = UAScheduleTriggerAppInit;
    } else {

        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Invalid trigger type: %@", triggerTypeString];
            *error =  [NSError errorWithDomain:UAScheduleTriggerErrorDomain
                                          code:UAScheduleTriggerErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        // No valid trigger type
        return nil;
    }

    NSNumber *goal;
    if ([json[UAScheduleTriggerGoalKey] isKindOfClass:[NSNumber class]]) {
        goal = json[UAScheduleTriggerGoalKey];
    }

    if (!goal || [goal doubleValue] <= 0) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Goal must be defined and greater than 0. Invalid value: %@", goal];
            *error =  [NSError errorWithDomain:UAScheduleTriggerErrorDomain
                                          code:UAScheduleTriggerErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    UAJSONPredicate *predicate;
    if (json[UAScheduleTriggerPredicateKey]) {
        predicate = [UAJSONPredicate predicateWithJSON:json[UAScheduleTriggerPredicateKey] error:error];
        if (!predicate) {
            return nil;
        }
    }

    return [UAScheduleTrigger triggerWithType:triggerType goal:goal predicate:predicate];
}


- (BOOL)isEqualToTrigger:(UAScheduleTrigger *)trigger {
    if (!trigger) {
        return NO;
    }

    if (self.type != trigger.type) {
        return NO;
    }

    if (![self.goal isEqualToNumber:trigger.goal]) {
        return NO;
    }

    if (self.predicate != trigger.predicate && ![self.predicate.payload isEqualToDictionary:trigger.predicate.payload]) {
        return NO;
    }

    return YES;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[UAScheduleTrigger class]]) {
        return NO;
    }

    return [self isEqualToTrigger:(UAScheduleTrigger *)object];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    result = 31 * result + self.type;
    result = 31 * result + [self.goal hash];
    result = 31 * result + [self.predicate hash];
    return result;
}

@end
