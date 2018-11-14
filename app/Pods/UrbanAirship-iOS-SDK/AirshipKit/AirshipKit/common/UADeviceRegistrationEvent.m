/* Copyright 2017 Urban Airship and Contributors */

#import "UADeviceRegistrationEvent+Internal.h"
#import "UAEvent+Internal.h"
#import "UAPush.h"
#import "UAUser.h"
#import "UAirship.h"

@implementation UADeviceRegistrationEvent

+ (instancetype)event {
    UADeviceRegistrationEvent *event = [[self alloc] init];

    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    if ([UAirship push].pushTokenRegistrationEnabled) {
        [data setValue:[UAirship push].deviceToken forKey:@"device_token"];
    }

    [data setValue:[UAirship push].channelID forKey:@"channel_id"];
#if !TARGET_OS_TV   // Inbox not supported on tvOS
    [data setValue:[UAirship inboxUser].username forKey:@"user_id"];
#endif

    event.data = [data mutableCopy];
    return event;
}

- (NSString *)eventType {
    return @"device_registration";
}

@end
