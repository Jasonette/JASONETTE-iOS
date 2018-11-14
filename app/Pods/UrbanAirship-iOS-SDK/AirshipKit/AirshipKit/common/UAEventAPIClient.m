/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>

#import "UAEventAPIClient+Internal.h"
#import "UAUtils.h"
#import "UAirship.h"
#import "UAPush+Internal.h"
#import "UAUser.h"
#import "UALocation.h"
#import "NSJSONSerialization+UAAdditions.h"

#if !TARGET_OS_TV
#import "UAInbox.h"
#endif

@implementation UAEventAPIClient

+ (instancetype)clientWithConfig:(UAConfig *)config {
    return [[UAEventAPIClient alloc] initWithConfig:config session:[UARequestSession sessionWithConfig:config]];
}

+ (instancetype)clientWithConfig:(UAConfig *)config session:(UARequestSession *)session {
    return [[UAEventAPIClient alloc] initWithConfig:config session:session];
}

-(void)uploadEvents:(NSArray *)events completionHandler:(void (^)(NSHTTPURLResponse *))completionHandler {
    UARequest *request = [self requestWithEvents:events];

    if (uaLogLevel >= UALogLevelTrace) {
        UA_LTRACE(@"Sending analytics events with IDs: %@", [events valueForKey:@"event_id"]);
        UA_LTRACE(@"Sending to server: %@", self.config.analyticsURL);
        UA_LTRACE(@"Sending analytics headers: %@", [request.headers descriptionWithLocale:nil indent:1]);
        UA_LTRACE(@"Sending analytics body: %@", [NSJSONSerialization stringWithObject:events options:NSJSONWritingPrettyPrinted]);
    }

    // Perform the upload
    [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }
        completionHandler(httpResponse);
    }];
}


- (UARequest*)requestWithEvents:(NSArray *)events {
    UARequest *request = [UARequest requestWithBuilderBlock:^(UARequestBuilder *builder) {
        builder.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.config.analyticsURL, @"/warp9/"]];
        builder.method = @"POST";

        // Body
        builder.compressBody = YES;
        builder.body = [NSJSONSerialization dataWithJSONObject:events options:0 error:nil];
        [builder setValue:@"application/json" forHeader:@"Content-Type"];

        // Sent timestamp
        [builder setValue:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] forHeader:@"X-UA-Sent-At"];

        // Device info
        [builder setValue:[UIDevice currentDevice].systemName forHeader:@"X-UA-Device-Family"];
        [builder setValue:[UIDevice currentDevice].systemVersion forHeader:@"X-UA-OS-Version"];
        [builder setValue:[UAUtils deviceModelName] forHeader:@"X-UA-Device-Model"];

        // App info
        [builder setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleIdentifierKey] forHeader:@"X-UA-Package-Name"];
        [builder setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"" forHeader:@"X-UA-Package-Version"];

        // Time zone
        [builder setValue:[[NSTimeZone defaultTimeZone] name] forHeader:@"X-UA-Timezone"];
        [builder setValue:[[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleLanguageCode] forHeader:@"X-UA-Locale-Language"];
        [builder setValue:[[NSLocale autoupdatingCurrentLocale] objectForKey: NSLocaleCountryCode] forHeader:@"X-UA-Locale-Country"];
        [builder setValue:[[NSLocale autoupdatingCurrentLocale] objectForKey: NSLocaleVariantCode] forHeader:@"X-UA-Locale-Variant"];

        // Urban Airship identifiers
        [builder setValue:[UAUtils deviceID] forHeader:@"X-UA-ID"];
#if !TARGET_OS_TV   // Inbox not supported on tvOS
        [builder setValue:[UAirship inboxUser].username forHeader:@"X-UA-User-ID"];
#endif
        [builder setValue:[UAirship push].channelID forHeader:@"X-UA-Channel-ID"];
        [builder setValue:self.config.appKey forHeader:@"X-UA-App-Key"];

        // SDK Version
        [builder setValue:[UAirshipVersion get] forHeader:@"X-UA-Lib-Version"];

        // Only send up token if enabled
        if ([UAirship push].pushTokenRegistrationEnabled) {
            [builder setValue:[UAirship push].deviceToken forHeader:@"X-UA-Push-Address"];
        }

        // Push settings
        [builder setValue:[[UAirship push] userPushNotificationsAllowed] ? @"true" : @"false" forHeader:@"X-UA-Channel-Opted-In"];
        [builder setValue:[UAirship push].userPromptedForNotifications ? @"true" : @"false" forHeader:@"X-UA-Notification-Prompted"];
        [builder setValue:[[UAirship push] backgroundPushNotificationsAllowed] ? @"true" : @"false" forHeader:@"X-UA-Channel-Background-Enabled"];

        // Location settings
        [builder setValue:[self locationPermission] forHeader:@"X-UA-Location-Permission"];
        [builder setValue:[UAirship location].locationUpdatesEnabled ? @"true" : @"false" forHeader:@"X-UA-Location-Service-Enabled"];
    }];
    
    return request;
}

- (NSString *)locationPermission {
    if (![CLLocationManager locationServicesEnabled]) {
        return @"SYSTEM_LOCATION_DISABLED";
    } else {
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted:
                return @"NOT_ALLOWED";
            case kCLAuthorizationStatusAuthorizedAlways:
                return @"ALWAYS_ALLOWED";
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                return @"FOREGROUND_ALLOWED";
            case kCLAuthorizationStatusNotDetermined:
                return @"UNPROMPTED";
        }
    }
}

@end
