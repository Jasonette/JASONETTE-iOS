/* Copyright 2017 Urban Airship and Contributors */

#import "UAActionSchedule+Internal.h"

@implementation UAActionSchedule

- (instancetype)initWithIdentifier:(NSString *)identifier info:(UAActionScheduleInfo *)info {
    self = [super self];
    if (self) {
        self.identifier = identifier;
        self.info = info;
    }

    return self;
}

+ (instancetype)actionScheduleWithIdentifier:(NSString *)identifier info:(UAActionScheduleInfo *)info {
    return [[UAActionSchedule alloc] initWithIdentifier:identifier info:info];
}

- (BOOL)isEqualToSchedule:(UAActionSchedule *)schedule {
    if (!schedule) {
        return NO;
    }

    if (![self.identifier isEqualToString:schedule.identifier]) {
        return NO;
    }

    if (![self.info isEqualToScheduleInfo:schedule.info]) {
        return NO;
    }

    return YES;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[UAActionSchedule class]]) {
        return NO;
    }

    return [self isEqualToSchedule:(UAActionSchedule *)object];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    result = 31 * result + [self.info hash];
    result = 31 * result + [self.identifier hash];
    return result;
}

@end
