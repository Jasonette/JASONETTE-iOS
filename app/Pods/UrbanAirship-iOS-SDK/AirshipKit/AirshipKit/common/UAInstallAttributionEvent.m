/* Copyright 2017 Urban Airship and Contributors */

#import "UAInstallAttributionEvent.h"
#import "UAEvent+Internal.h"

@implementation UAInstallAttributionEvent

+ (instancetype)event {
    return [[self alloc] init];
}

+ (instancetype)eventWithAppPurchaseDate:(NSDate *)appPurchaseDate
                       iAdImpressionDate:(NSDate *)iAdImpressionDate {
    UAInstallAttributionEvent *event = [[self alloc] init];

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"app_store_purchase_date"] = [NSString stringWithFormat:@"%f", [appPurchaseDate timeIntervalSince1970]];
    data[@"app_store_ad_impression_date"] = [NSString stringWithFormat:@"%f", [iAdImpressionDate timeIntervalSince1970]];

    // Set an immutable copy of the data
    event.data = [data copy];

    return event;
}

- (NSString *)eventType {
    return @"install_attribution";
}

@end
