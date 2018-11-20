/* Copyright 2017 Urban Airship and Contributors */

#import "UAActionScheduleInfo.h"
#import "UAUtils.h"

NSUInteger const UAActionScheduleInfoMaxTriggers = 10;

NSString *const UAActionScheduleInfoActionsKey = @"actions";
NSString *const UAActionScheduleInfoLimitKey = @"limit";
NSString *const UAActionScheduleInfoGroupKey = @"group";
NSString *const UAActionScheduleInfoEndKey = @"end";
NSString *const UAActionScheduleInfoStartKey = @"start";
NSString *const UAActionScheduleInfoTriggersKey = @"triggers";
NSString *const UAActionScheduleInfoDelayKey = @"delay";

NSString * const UAActionScheduleInfoErrorDomain = @"com.urbanairship.schedule_info";

@implementation UAActionScheduleInfoBuilder

@end


@interface UAActionScheduleInfo()
@property(nonatomic, copy) NSDictionary *actions;
@property(nonatomic, copy) NSArray *triggers;
@property(nonatomic, copy) NSString *group;
@property(nonatomic, assign) NSUInteger limit;
@property(nonatomic, strong) NSDate *start;
@property(nonatomic, strong) NSDate *end;
@property(nonatomic, strong) UAScheduleDelay *delay;

@end

@implementation UAActionScheduleInfo

- (BOOL)isValid {
    if (!self.triggers.count || self.triggers.count > UAActionScheduleInfoMaxTriggers) {
        return NO;
    }

    if (!self.actions.count) {
        return NO;
    }

    if ([self.start compare:self.end] == NSOrderedDescending) {
        return NO;
    }

    if (self.delay && !self.delay.isValid) {
        return NO;
    }

    return YES;
}

- (instancetype)initWithBuilder:(UAActionScheduleInfoBuilder *)builder {
    self = [super self];
    if (self) {
        self.actions = [builder.actions copy] ?: @{};
        self.triggers = [builder.triggers copy] ?: @[];
        self.limit = builder.limit;
        self.group = builder.group;
        self.delay = builder.delay;
        self.start = builder.start ?: [NSDate distantPast];
        self.end = builder.end ?: [NSDate distantFuture];
    }

    return self;
}

+ (instancetype)actionScheduleInfoWithBuilderBlock:(void (^)(UAActionScheduleInfoBuilder *))builderBlock {
    UAActionScheduleInfoBuilder *builder = [[UAActionScheduleInfoBuilder alloc] init];
    builder.limit = 1;

    if (builderBlock) {
        builderBlock(builder);
    }

    return [[UAActionScheduleInfo alloc] initWithBuilder:builder];
}


+ (instancetype)actionScheduleInfoWithJSON:(id)json error:(NSError **)error {
    if (![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid object: %@", json];
            *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                          code:UAActionScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    // Actions
    id actions = json[UAActionScheduleInfoActionsKey];
    if (![actions isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Actions payload must be a dictionary. Invalid value: %@", actions];
            *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                          code:UAActionScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    // Limit
    id limit = json[UAActionScheduleInfoLimitKey];
    if (limit && ![limit isKindOfClass:[NSNumber class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Limit must be defined and be a number. Invalid value: %@", limit];
            *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                          code:UAActionScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    // Start
    NSDate *start;
    if (json[UAActionScheduleInfoStartKey]) {
        if (![json[UAActionScheduleInfoStartKey] isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Start must be ISO 8601 timestamp. Invalid value: %@", start];
                *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                              code:UAActionScheduleInfoErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }

            return nil;
        }

        start = [UAUtils parseISO8601DateFromString:json[UAActionScheduleInfoStartKey]];
    }

    // End
    NSDate *end;
    if (json[UAActionScheduleInfoEndKey]) {
        if (![json[UAActionScheduleInfoEndKey] isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"End must be ISO 8601 timestamp. Invalid value: %@", end];
                *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                              code:UAActionScheduleInfoErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }

            return nil;
        }

        end = [UAUtils parseISO8601DateFromString:json[UAActionScheduleInfoEndKey]];
    }

    // Group
    id group = json[UAActionScheduleInfoGroupKey];
    if (group && ![group isKindOfClass:[NSString class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Group must be a string. Invalid value: %@", group];
            *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                          code:UAActionScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    // Triggers
    NSMutableArray *triggers = [NSMutableArray array];
    id triggersJSONArray = json[UAActionScheduleInfoTriggersKey];
    if (!triggersJSONArray || ![triggersJSONArray isKindOfClass:[NSArray class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Schedule must contain an array of triggers. Invalid value %@", triggersJSONArray];
            *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                          code:UAActionScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    for (id triggerJSON in triggersJSONArray) {
        UAScheduleTrigger *trigger = [UAScheduleTrigger triggerWithJSON:triggerJSON error:error];
        if (!trigger) {
            return nil;
        }

        [triggers addObject:trigger];
    }

    if (!triggers.count) {
        if (error) {
            NSString *msg = @"Schedule must contain at least 1 trigger.";
            *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                          code:UAActionScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }
        return nil;
    }
    
    // Delay
    UAScheduleDelay *delay = nil;
    if (json[UAActionScheduleInfoDelayKey]) {
        if (![json[UAActionScheduleInfoDelayKey] isKindOfClass:[NSDictionary class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Delay payload must be a dictionary. Invalid value: %@", json[UAActionScheduleInfoDelayKey]];
                *error =  [NSError errorWithDomain:UAActionScheduleInfoErrorDomain
                                              code:UAActionScheduleInfoErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
        }
        
        delay = [UAScheduleDelay delayWithJSON:json[UAActionScheduleInfoDelayKey] error:error];
        
        if (!delay) {
            return nil;
        }
    }

    return [UAActionScheduleInfo actionScheduleInfoWithBuilderBlock:^(UAActionScheduleInfoBuilder *builder) {
        builder.actions = actions;
        builder.triggers = triggers;
        builder.limit = [limit unsignedIntegerValue];
        builder.group = group;
        builder.start = start;
        builder.end = end;
        builder.delay = delay;
    }];
}

- (BOOL)isEqualToScheduleInfo:(UAActionScheduleInfo *)scheduleInfo {
    if (!scheduleInfo) {
        return NO;
    }

    if (self.limit != scheduleInfo.limit) {
        return NO;
    }

    if (![self.start isEqualToDate:scheduleInfo.start]) {
        return NO;
    }

    if (![self.end isEqualToDate:scheduleInfo.end]) {
        return NO;
    }

    if (self.actions != scheduleInfo.actions && ![self.actions isEqualToDictionary:scheduleInfo.actions]) {
        return NO;
    }

    if (self.triggers != scheduleInfo.triggers && ![self.triggers isEqualToArray:scheduleInfo.triggers]) {
        return NO;
    }

    if (self.group != scheduleInfo.group && ![self.group isEqualToString:scheduleInfo.group]) {
        return NO;
    }
    
    if (self.delay != scheduleInfo.delay && ![self.delay isEqualToDelay:scheduleInfo.delay]) {
        return NO;
    }

    return YES;
}


#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[UAActionScheduleInfo class]]) {
        return NO;
    }

    return [self isEqualToScheduleInfo:(UAActionScheduleInfo *)object];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    result = 31 * result + self.limit;
    result = 31 * result + [self.start hash];
    result = 31 * result + [self.end hash];
    result = 31 * result + [self.group hash];
    result = 31 * result + [self.triggers hash];
    result = 31 * result + [self.actions hash];
    result = 31 * result + [self.delay hash];

    return result;
}

@end
