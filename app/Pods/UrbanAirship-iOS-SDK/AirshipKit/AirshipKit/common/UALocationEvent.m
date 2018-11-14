/* Copyright 2017 Urban Airship and Contributors */

#import "UALocationEvent.h"
#import "UAEvent+Internal.h"

@implementation UALocationEvent

UALocationEventAnalyticsKey * const UALocationEventForegroundKey = @"foreground";
UALocationEventAnalyticsKey * const UALocationEventLatitudeKey = @"lat";
UALocationEventAnalyticsKey * const UALocationEventLongitudeKey = @"long";
UALocationEventAnalyticsKey * const UALocationEventDesiredAccuracyKey = @"requested_accuracy";
UALocationEventAnalyticsKey * const UALocationEventUpdateTypeKey = @"update_type";
UALocationEventAnalyticsKey * const UALocationEventProviderKey = @"provider";
UALocationEventAnalyticsKey * const UALocationEventDistanceFilterKey = @"update_dist";
UALocationEventAnalyticsKey * const UALocationEventHorizontalAccuracyKey = @"h_accuracy";
UALocationEventAnalyticsKey * const UALocationEventVerticalAccuracyKey = @"v_accuracy";

UALocationEventUpdateType * const UALocationEventAnalyticsType = @"location";
UALocationEventUpdateType * const UALocationEventUpdateTypeChange = @"CHANGE";
UALocationEventUpdateType * const UALocationEventUpdateTypeContinuous = @"CONTINUOUS";
UALocationEventUpdateType * const UALocationEventUpdateTypeSingle = @"SINGLE";
UALocationEventUpdateType * const UALocationEventUpdateTypeNone = @"NONE";

UALocationServiceProviderType *const UALocationServiceProviderGps = @"GPS";
UALocationServiceProviderType *const UALocationServiceProviderNetwork = @"NETWORK";
UALocationServiceProviderType *const UALocationServiceProviderUnknown = @"UNKNOWN";

NSString * const UAAnalyticsValueNone = @"NONE";

+ (UALocationEvent *)locationEventWithLocation:(CLLocation *)location
                                  providerType:(UALocationServiceProviderType *)providerType
                               desiredAccuracy:(NSNumber *)desiredAccuracy
                                distanceFilter:(NSNumber *)distanceFilter
                                    updateType:(UALocationEventUpdateType *)updateType {

    UALocationEvent *event = [[UALocationEvent alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    [data setValue:updateType forKey:UALocationEventUpdateTypeKey];
    [data setValue:[NSString stringWithFormat:@"%.7f", location.coordinate.latitude] forKey:UALocationEventLatitudeKey];
    [data setValue:[NSString stringWithFormat:@"%.7f", location.coordinate.longitude] forKey:UALocationEventLongitudeKey];
    [data setValue:[NSString stringWithFormat:@"%i", (int)location.horizontalAccuracy] forKey:UALocationEventHorizontalAccuracyKey];
    [data setValue:[NSString stringWithFormat:@"%i", (int)location.verticalAccuracy] forKey:UALocationEventVerticalAccuracyKey];

    if (providerType) {
        [data setValue:providerType forKey:UALocationEventProviderKey];
    } else {
        [data setValue:UALocationServiceProviderUnknown forKey:UALocationEventProviderKey];
    }

    if (desiredAccuracy) {
        [data setValue:[NSString stringWithFormat:@"%i", [desiredAccuracy intValue]] forKey:UALocationEventDesiredAccuracyKey];
    } else {
        [data setValue:UAAnalyticsValueNone forKey:UALocationEventDesiredAccuracyKey];
    }

    if (distanceFilter) {
        [data setValue:[NSString stringWithFormat:@"%i", [distanceFilter intValue]] forKey:UALocationEventDistanceFilterKey];
    } else {
        [data setValue:UAAnalyticsValueNone forKey:UALocationEventDistanceFilterKey];
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [data setValue:@"true" forKey:UALocationEventForegroundKey];
    } else {
        [data setValue:@"false" forKey:UALocationEventForegroundKey];
    }

    event.data = [data mutableCopy];
    return event;
}

+ (UALocationEvent *)locationEventWithLocation:(CLLocation *)location
                                  providerType:(UALocationServiceProviderType *)providerType
                               desiredAccuracy:(NSNumber *)desiredAccuracy
                                distanceFilter:(NSNumber *)distanceFilter {

    return [UALocationEvent locationEventWithLocation:location
                                         providerType:providerType
                                      desiredAccuracy:desiredAccuracy
                                       distanceFilter:distanceFilter
                                           updateType:UALocationEventUpdateTypeNone];

}

+ (UALocationEvent *)singleLocationEventWithLocation:(CLLocation *)location
                                        providerType:(UALocationServiceProviderType *)providerType
                                     desiredAccuracy:(NSNumber *)desiredAccuracy
                                      distanceFilter:(NSNumber *)distanceFilter {

    return [UALocationEvent locationEventWithLocation:location
                                         providerType:providerType
                                      desiredAccuracy:desiredAccuracy
                                       distanceFilter:distanceFilter
                                           updateType:UALocationEventUpdateTypeSingle];
}

+ (UALocationEvent *)significantChangeLocationEventWithLocation:(CLLocation *)location
                                                   providerType:(UALocationServiceProviderType *)providerType {

    return [UALocationEvent locationEventWithLocation:location
                                         providerType:providerType
                                      desiredAccuracy:nil
                                       distanceFilter:nil
                                           updateType:UALocationEventUpdateTypeChange];

}

+ (UALocationEvent *)standardLocationEventWithLocation:(CLLocation *)location
                                          providerType:(UALocationServiceProviderType *)providerType
                                       desiredAccuracy:(NSNumber *)desiredAccuracy
                                        distanceFilter:(NSNumber *)distanceFilter {

    return [UALocationEvent locationEventWithLocation:location
                                         providerType:providerType
                                      desiredAccuracy:desiredAccuracy
                                       distanceFilter:distanceFilter
                                           updateType:UALocationEventUpdateTypeContinuous];

}

- (NSString *)eventType {
    return UALocationEventAnalyticsType;
}

- (UAEventPriority)priority {
    return UAEventPriorityLow;
}


@end
