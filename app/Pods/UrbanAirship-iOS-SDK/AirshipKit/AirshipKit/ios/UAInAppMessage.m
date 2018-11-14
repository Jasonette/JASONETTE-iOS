/* Copyright 2017 Urban Airship and Contributors */

#import "UAInAppMessage.h"
#import "UAUtils.h"
#import "UAColorUtils+Internal.h"
#import "UAInAppMessageButtonActionBinding.h"
#import "UAActionArguments.h"
#import "UAirship+Internal.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAPush+Internal.h"
#import "UANotificationCategories+Internal.h"
#import "UANotificationCategory.h"
#import "UANotificationAction.h"

// 30 days in seconds
#define kUADefaultInAppMessageExpiryInterval 60 * 60 * 24 * 30

// 15 seconds
#define kUADefaultInAppMessageDurationInterval 15

@implementation UAInAppMessage

+ (instancetype)message {
    return [[self alloc] init];
}

+ (instancetype)messageWithPayload:(NSDictionary *)payload {
    UAInAppMessage *message = [[self alloc] init];

    id (^typeCheck)(id, Class) = ^id(id value, Class class) {
        return [value isKindOfClass:class] ? value : nil;
    };

    // top-level keys
    NSString *identifier = typeCheck(payload[@"identifier"], [NSString class]);
    NSString *expiry = typeCheck(payload[@"expiry"], [NSString class]);
    NSDictionary *extra = typeCheck(payload[@"extra"], [NSDictionary class]);
    NSDictionary *display = typeCheck(payload[@"display"], [NSDictionary class]);
    NSDictionary *actions = typeCheck(payload[@"actions"], [NSDictionary class]);

    message.identifier = identifier;

    if (expiry) {
        message.expiry = [UAUtils parseISO8601DateFromString:expiry];
    }

    message.extra = extra;

    // display

    NSString *displayType = typeCheck(display[@"type"], [NSString class]);

    if ([displayType isEqualToString:@"banner"]) {
        message.displayType = UAInAppMessageDisplayTypeBanner;
    } else {
        message.displayType = UAInAppMessageDisplayTypeUnknown;
    }

    message.alert = typeCheck(display[@"alert"], [NSString class]);

    NSNumber *durationNumber = typeCheck(display[@"duration"], [NSNumber class]);
    if (durationNumber) {
        message.duration = [durationNumber doubleValue];
    }

    NSString *positionString = typeCheck(display[@"position"], [NSString class]);
    if ([positionString isEqualToString:@"top"]) {
        message.position = UAInAppMessagePositionTop;
    } else if ([positionString isEqualToString:@"bottom"]) {
        message.position = UAInAppMessagePositionBottom;
    }

    message.primaryColor = [UAColorUtils colorWithHexString:typeCheck(display[@"primary_color"], [NSString class])];
    message.secondaryColor = [UAColorUtils colorWithHexString:typeCheck(display[@"secondary_color"], [NSString class])];

    // actions

    message.buttonGroup = typeCheck(actions[@"button_group"], [NSString class]);
    message.buttonActions = typeCheck(actions[@"button_actions"], [NSDictionary class]);
    message.onClick = typeCheck(actions[@"on_click"], [NSDictionary class]);

    return message;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default values unless otherwise specified
        self.displayType = UAInAppMessageDisplayTypeBanner;
        self.expiry = [NSDate dateWithTimeIntervalSinceNow:kUADefaultInAppMessageExpiryInterval];
        self.position = UAInAppMessagePositionBottom;
        self.duration = kUADefaultInAppMessageDurationInterval;
    }
    return self;
}

- (BOOL)isEqualToMessage:(UAInAppMessage *)message {
    return [self.payload isEqualToDictionary:message.payload];
}

- (NSDictionary *)payload {

    NSDateFormatter *formatter = [UAUtils ISODateFormatterUTCWithDelimiter];
    NSString *expiry = [formatter stringFromDate:self.expiry];

    NSDictionary *extra = self.extra;

    NSString *displayType;
    if (self.displayType == UAInAppMessageDisplayTypeBanner) {
        displayType = @"banner";
    } else {
        displayType = @"unknown";
    }

    NSString *alert = self.alert;

    NSNumber *duration = [NSNumber numberWithDouble:self.duration];

    NSString *position;
    if (self.position == UAInAppMessagePositionTop) {
        position = @"top";
    } else if (self.position == UAInAppMessagePositionBottom) {
        position = @"bottom";
    }

    NSString *primaryColor = [UAColorUtils hexStringWithColor:self.primaryColor];
    NSString *secondaryColor = [UAColorUtils hexStringWithColor:self.secondaryColor];

    NSMutableDictionary *display = [NSMutableDictionary dictionary];
    [display setValue:displayType forKey:@"type"];
    [display setValue:position forKey:@"position"];
    [display setValue:alert forKey:@"alert"];
    [display setValue:duration forKey:@"duration"];
    [display setValue:primaryColor forKey:@"primary_color"];
    [display setValue:secondaryColor forKey:@"secondary_color"];
    
    NSMutableDictionary *actions = [NSMutableDictionary dictionary];
    [actions setValue:self.buttonGroup forKey:@"button_group"];
    [actions setValue:self.buttonActions forKey:@"button_actions"];
    [actions setValue:self.onClick forKey:@"on_click"];

    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:self.identifier forKey:@"identifier"];
    [payload setValue:expiry forKey:@"expiry"];
    [payload setValue:(extra.count ? extra : nil) forKey:@"extra"];
    [payload setValue:(display.count ? display : nil) forKey:@"display"];
    [payload setValue:(actions.count ? actions : nil) forKey:@"actions"];

    return payload;
}

- (UANotificationCategory *)buttonCategory {
    if (self.buttonGroup) {
        NSSet *categories = [UAirship push].combinedCategories;

        for (UANotificationCategory *category in categories) {
            // Find the category that matches our buttonGroup
            if ([category.identifier isEqualToString:self.buttonGroup]) {
                return category;
            }
        }
    }

    return nil;
}

- (NSArray *)notificationActions {
    return self.buttonCategory.actions;
}

- (NSArray *)buttonActionBindings {
    NSMutableArray *bindings = [NSMutableArray array];

    // Create a button action binding for each corresponding action identifier
    for (UANotificationAction *notificationAction in self.notificationActions) {
        NSDictionary *payload = self.buttonActions[[notificationAction identifier]] ?: [NSDictionary dictionary];

        UAInAppMessageButtonActionBinding *binding = [[UAInAppMessageButtonActionBinding alloc] init];

        binding.title = notificationAction.title;

        binding.identifier = notificationAction.identifier;

        // choose the situation that matches the corresponding notificationAction's activation mode
        if ((notificationAction.options & UANotificationActionOptionForeground) > 0) {
            binding.situation = UASituationForegroundInteractiveButton;
        } else {
            binding.situation = UASituationBackgroundInteractiveButton;
        }

        binding.actions = payload;

        [bindings addObject:binding];
    }

    return bindings;
}

- (NSString *)description {
    return self.payload.description;
}

@end
