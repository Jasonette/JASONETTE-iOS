/* Copyright 2017 Urban Airship and Contributors */

#import "UAScreenTrackingEvent+Internal.h"
#import "UAEvent+Internal.h"
#import "UAGlobal.h"

@implementation UAScreenTrackingEvent

+ (instancetype)eventWithScreen:(NSString *)screen startTime:(NSTimeInterval)startTime {

    UAScreenTrackingEvent *screenTrackingEvent = [[UAScreenTrackingEvent alloc] init];
    screenTrackingEvent.screen = screen;
    screenTrackingEvent.startTime = startTime;

    return screenTrackingEvent;
}

- (BOOL)isValid {

    if (![UAScreenTrackingEvent screenTrackingEventCharacterCountIsValid:self.screen]) {
        UA_LERR(@"Screen name must not be greater than %d characters or less than %d characters in length.", kUAScreenTrackingEventMaxCharacters, kUAScreenTrackingEventMinCharacters);
        return NO;
    }

    // Return early if tracking duration is < 0
    if (self.duration <= 0) {
        UA_LERR(@"Screen tracking duration must be positive.");
        return NO;
    }

    return YES;
}

- (NSString *)eventType {
    return kUAScreenTrackingEventType;
}

- (NSTimeInterval)duration {

    if (!self.stopTime) {
        UA_LERR(@"Duration is not available without a stop time.");
        return 0;
    }

    return self.stopTime - self.startTime;
}

+ (BOOL)screenTrackingEventCharacterCountIsValid:(NSString *)string {
    if (!string || string.length > kUAScreenTrackingEventMaxCharacters || string.length < kUAScreenTrackingEventMinCharacters) {
        return NO;
    }

    return YES;
}

- (NSDictionary *)data {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setValue:self.screen forKey:kUAScreenTrackingEventScreenKey];
    [dictionary setValue:self.previousScreen forKey:kUAScreenTrackingEventPreviousScreenKey];
    [dictionary setValue:[NSString stringWithFormat:@"%0.3f", self.startTime] forKey:kUAScreenTrackingEventEnteredTimeKey];
    [dictionary setValue:[NSString stringWithFormat:@"%0.3f", self.stopTime] forKey:kUAScreenTrackingEventExitedTimeKey];
    [dictionary setValue:[NSString stringWithFormat:@"%0.3f", self.duration] forKey:kUAScreenTrackingEventDurationKey];

    return dictionary;
}

@end
