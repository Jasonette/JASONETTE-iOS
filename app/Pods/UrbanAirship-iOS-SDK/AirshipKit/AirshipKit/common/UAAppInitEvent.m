/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UAAppInitEvent+Internal.h"
#import "UAEvent+Internal.h"
#import "UAAnalytics.h"
#import "UAirship.h"
#import "UAUser.h"
#import "UAUtils.h"

@implementation UAAppInitEvent

+ (instancetype)event {
    UAAppInitEvent *event = [[self alloc] init];
    event.data = [[event gatherData] mutableCopy];
    return event;
}

- (NSMutableDictionary *)gatherData {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    UAAnalytics *analytics = [UAirship shared].analytics;

    [data setValue:analytics.conversionSendID forKey:@"push_id"];
    [data setValue:analytics.conversionPushMetadata forKey:@"metadata"];
    [data setValue:analytics.conversionRichPushID forKey:@"rich_push_id"];

#if !TARGET_OS_TV   // Inbox not supported on tvOS
    [data setValue:[UAirship inboxUser].username forKey:@"user_id"];
    [data setValue:[self carrierName] forKey:@"carrier"];
#endif

    [data setValue:[UAUtils connectionType] forKey:@"connection_type"];

    [data setValue:[self notificationTypes] forKey:@"notification_types"];

    NSTimeZone *localtz = [NSTimeZone defaultTimeZone];
    [data setValue:[NSNumber numberWithDouble:[localtz secondsFromGMT]] forKey:@"time_zone"];
    [data setValue:([localtz isDaylightSavingTime] ? @"true" : @"false") forKey:@"daylight_savings"];

    // Component Versions
    [data setValue:[[UIDevice currentDevice] systemVersion] forKey:@"os_version"];
    [data setValue:[UAirshipVersion get] forKey:@"lib_version"];

    NSString *packageVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"";
    [data setValue:packageVersion forKey:@"package_version"];

    // Foreground
    BOOL isInForeground = ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground);
    [data setValue:(isInForeground ? @"true" : @"false") forKey:@"foreground"];

    return data;
}

- (NSString *)eventType {
    return @"app_init";
}

@end
