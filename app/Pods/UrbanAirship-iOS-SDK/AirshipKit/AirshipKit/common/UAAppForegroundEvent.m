/* Copyright 2017 Urban Airship and Contributors */

#import "UAAppForegroundEvent+Internal.h"
#import "UAEvent+Internal.h"

@implementation UAAppForegroundEvent

- (NSMutableDictionary *)gatherData {
    NSMutableDictionary *data = [super gatherData];
    [data removeObjectForKey:@"foreground"];
    return data;
}

- (NSString *)eventType {
    return @"app_foreground";
}

@end
