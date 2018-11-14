/* Copyright 2017 Urban Airship and Contributors */

#import "UAInAppDisplayEvent+Internal.h"
#import "UAInAppMessage.h"
#import "UAAnalytics.h"
#import "UAirship.h"
#import "UAEvent+Internal.h"


@implementation UAInAppDisplayEvent

- (instancetype) initWithMessage:(UAInAppMessage *)message {
    self = [super init];
    if (self) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        [data setValue:message.identifier forKey:@"id"];
        [data setValue:[UAirship shared].analytics.conversionSendID forKey:@"conversion_send_id"];
        [data setValue:[UAirship shared].analytics.conversionPushMetadata forKey:@"conversion_metadata"];
        self.data = [data copy];
        return self;
    }
    return nil;
}

+ (instancetype)eventWithMessage:(UAInAppMessage *)message {
    return [[self alloc] initWithMessage:message];
}

- (NSString *)eventType {
    return @"in_app_display";
}

- (BOOL)isValid {
    return self.data[@"id"] != nil;
}

@end
