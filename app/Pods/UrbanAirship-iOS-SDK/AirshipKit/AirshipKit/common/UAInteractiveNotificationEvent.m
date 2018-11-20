/* Copyright 2017 Urban Airship and Contributors */

#import "UAInteractiveNotificationEvent+Internal.h"
#import "UAEvent+Internal.h"
#import "UANotificationAction.h"
#import "UAGlobal.h"

#define kUAInteractiveNotificationEventSize 350
@implementation UAInteractiveNotificationEvent

const NSUInteger UAInteractiveNotificationEventCharacterLimit = 255;

+ (instancetype)eventWithNotificationAction:(UANotificationAction *)action
                                 categoryID:(NSString *)category
                               notification:(NSDictionary *)notification {

    return [self eventWithNotificationAction:action categoryID:category notification:notification responseText:nil];
}

+ (instancetype)eventWithNotificationAction:(UANotificationAction *)action
                                 categoryID:(NSString *)category
                               notification:(NSDictionary *)notification
                               responseText:(nullable NSString *)responseText {

    UAInteractiveNotificationEvent *event = [[self alloc] init];

#if TARGET_OS_TV   // application launch to the foreground (UNNotificationActionOptionForeground) not supported in tvOS
    BOOL foreground = NO;
#else
    BOOL foreground = (action.options & UNNotificationActionOptionForeground) > 0;
#endif

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:category forKey:@"button_group"];
    [data setValue:action.identifier forKey:@"button_id"];
    [data setValue:action.title forKey:@"button_description"];
    [data setValue:foreground ? @"true" : @"false" forKey:@"foreground"];
    [data setValue:notification[@"_"] forKey:@"send_id"];

    if (responseText) {
        NSString *userInputString = [responseText copy];
        if (userInputString.length > UAInteractiveNotificationEventCharacterLimit) {
            UA_LDEBUG(@"Interactive Notification %@ value exceeds %lu characters. Truncating to max chars", @"user_input", (unsigned long)
                    UAInteractiveNotificationEventCharacterLimit);
            userInputString = [userInputString substringToIndex:UAInteractiveNotificationEventCharacterLimit];
        }

        // Set the userInputString, which can be 0 - 255 characters. Empty string is acceptable.
        [data setValue:userInputString forKey:@"user_input"];
    }

    event.data = [NSDictionary dictionaryWithDictionary:data];

    return event;
}

- (NSString *)eventType {
    return @"interactive_notification_action";
}

- (UAEventPriority)priority {
    return UAEventPriorityHigh;
}

@end
