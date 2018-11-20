/* Copyright 2017 Urban Airship and Contributors */

#import "UAPushReceivedEvent+Internal.h"

#import "UAEvent+Internal.h"
#import "UAAnalytics+Internal.h"

#if !TARGET_OS_TV
#import "UAInboxUtils.h"
#endif

@implementation UAPushReceivedEvent

+ (instancetype)eventWithNotification:(NSDictionary *)notification {
    UAPushReceivedEvent *event = [[self alloc] init];

    NSMutableDictionary *data = [NSMutableDictionary dictionary];

#if !TARGET_OS_TV   // Inbox not supported on tvOS
    NSString *richPushID = [UAInboxUtils inboxMessageIDFromNotification:notification];
    if (richPushID) {
        [data setValue:richPushID forKey:@"rich_push_id"];
    }
#endif

    // Add the std push ID, if present, else send "MISSING_SEND_ID"
    NSString *pushID = [notification objectForKey:@"_"];
    if (pushID) {
        [data setValue:pushID forKey:@"push_id"];
    } else {
        [data setValue:kUAMissingSendID forKey:@"push_id"];
    }

    // Add the metadata only if present
    NSString *metadata = [notification objectForKey:kUAPushMetadata];
    [data setValue:metadata forKey:@"metadata"];

    event.data = [data mutableCopy];
    return event;
}

- (NSString *)eventType {
    return @"push_received";
}

@end
