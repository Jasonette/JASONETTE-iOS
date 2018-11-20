/* Copyright 2017 Urban Airship and Contributors */

#import "UAActionArguments.h"
#import "UAActionArguments+Internal.h"


NSString * const UAActionMetadataWebViewKey = @"com.urbanairship.webview";
NSString * const UAActionMetadataPushPayloadKey = @"com.urbanairship.payload";
NSString * const UAActionMetadataForegroundPresentationKey = @"com.urbanairship.foreground_presentation";
NSString * const UAActionMetadataInboxMessageKey = @"com.urbanairship.message";
NSString * const UAActionMetadataRegisteredName = @"com.urbanairship.registered_name";

NSString * const UAActionMetadataUserNotificationActionIDKey = @"com.urbanairship.user_notification_id";

NSString * const UAActionMetadataResponseInfoKey = @"com.urbanairship.response_info";

@implementation UAActionArguments

- (instancetype)initWithValue:(id)value
                withSituation:(UASituation)situation {

    self = [super init];
    if (self) {
        self.situation = situation;
        self.value = value;
    }

    return self;
}

- (instancetype)initWithValue:(id)value
                withSituation:(UASituation)situation
                     metadata:(NSDictionary *)metadata {
    
    self = [super init];
    if (self) {
        self.situation = situation;
        self.value = value;
        self.metadata = metadata;
    }
    
    return self;
}

+ (instancetype)argumentsWithValue:(id)value
                     withSituation:(UASituation)situation {
    return [[self alloc] initWithValue:value withSituation:situation];
}

+ (instancetype)argumentsWithValue:(id)value
                     withSituation:(UASituation)situation
                          metadata:(NSDictionary *)metadata {
    return [[self alloc] initWithValue:value withSituation:situation metadata:metadata];
}

- (NSString *)situationString {
    switch (self.situation) {
        case UASituationManualInvocation:
            return @"Manual Invocation";
            break;
        case UASituationBackgroundPush:
            return @"Background Push";
            break;
        case UASituationForegroundPush:
            return @"Foreground Push";
            break;
        case UASituationLaunchedFromPush:
            return @"Launched from Push";
            break;
        case UASituationWebViewInvocation:
            return @"Webview Invocation";
            break;
        case UASituationForegroundInteractiveButton:
            return @"Foreground Interactive Button";
            break;
        case UASituationBackgroundInteractiveButton:
            return @"Background Interactive Button";
            break;
        case UASituationAutomation:
            return @"Automation";
            break;
    }

    return @"Manual Invocation";
}

- (NSString *)description {
    return [NSString stringWithFormat:@"UAActionArguments with situation: %@, value: %@", self.situationString, self.value];
}

@end
