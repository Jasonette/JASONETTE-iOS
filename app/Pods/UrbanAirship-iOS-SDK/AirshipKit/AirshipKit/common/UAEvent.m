/* Copyright 2017 Urban Airship and Contributors */

#import "UAEvent+Internal.h"
#import "UAPush.h"
#import "UAirship.h"

#if !TARGET_OS_TV   // CoreTelephony not supported in tvOS
/*
 * Fix for CTTelephonyNetworkInfo bug where instances might receive
 * notifications after being deallocated causes EXC_BAD_ACCESS exceptions. We
 * suspect that it is an iOS6 only issue.
 *
 * http://stackoverflow.com/questions/14238586/coretelephony-crash/15510580#15510580
 */
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

static CTTelephonyNetworkInfo *netInfo_;
static dispatch_once_t netInfoDispatchToken_;
#endif

@implementation UAEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        self.eventID = [NSUUID UUID].UUIDString;
        self.time = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
        return self;
    }
    return nil;
}

- (BOOL)isValid {
    return YES;
}

- (NSString *)eventType {
    return @"base";
}

- (UAEventPriority)priority {
    return UAEventPriorityNormal;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"UAEvent ID: %@ type: %@ time: %@ data: %@",
            self.eventID, self.eventType, self.time, self.data];
}

- (NSString *)carrierName {
#if TARGET_OS_TV    // Core Telephony not supported on tvOS
    return nil;
#else
    dispatch_once(&netInfoDispatchToken_, ^{
        netInfo_ = [[CTTelephonyNetworkInfo alloc] init];
    });
    return netInfo_.subscriberCellularProvider.carrierName;
#endif
}

- (NSArray *)notificationTypes {
    NSMutableArray *notificationTypes = [NSMutableArray array];

    UANotificationOptions authorizedOptions = [UAirship push].authorizedNotificationOptions;

    if ((UANotificationOptionBadge & authorizedOptions) > 0) {
        [notificationTypes addObject:@"badge"];
    }

#if !TARGET_OS_TV   // sound and alert notifications are not supported in tvOS
    if ((UANotificationOptionSound & authorizedOptions) > 0) {
        [notificationTypes addObject:@"sound"];
    }

    if ((UANotificationOptionAlert & authorizedOptions) > 0) {
        [notificationTypes addObject:@"alert"];
    }
#endif

    return notificationTypes;
}

- (NSUInteger)jsonEventSize {
    NSMutableDictionary *eventDictionary = [NSMutableDictionary dictionary];
    [eventDictionary setValue:self.eventType forKey:@"type"];
    [eventDictionary setValue:self.time forKey:@"time"];
    [eventDictionary setValue:self.eventID forKey:@"event_id"];
    [eventDictionary setValue:self.data forKey:@"data"];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventDictionary
                                                       options:0
                                                         error:nil];

    return [jsonData length];
}

- (id)debugQuickLookObject {
    return self.data.description;
}

@end
