/* Copyright 2017 Urban Airship and Contributors */

#import "UAAppExitEvent+Internal.h"
#import "UAEvent+Internal.h"
#import "UAAnalytics.h"
#import "UAirship.h"
#import "UAUtils.h"

@implementation UAAppExitEvent

+ (instancetype)event {
    UAAppExitEvent *event = [[self alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    UAAnalytics *analytics = [UAirship shared].analytics;

    [data setValue:analytics.conversionSendID forKey:@"push_id"];
    [data setValue:analytics.conversionPushMetadata forKey:@"metadata"];
    [data setValue:analytics.conversionRichPushID forKey:@"rich_push_id"];

    [data setValue:[UAUtils connectionType] forKey:@"connection_type"];

    event.data = [data mutableCopy];
    return event;
}

- (NSString *)eventType {
    return @"app_exit";
}

@end
