/* Copyright 2017 Urban Airship and Contributors */

#import "UACircularRegion+Internal.h"
#import "UARegionEvent+Internal.h"
#import "UAGlobal.h"

@implementation UACircularRegion

+ (nullable instancetype)circularRegionWithRadius:(NSNumber *)radius latitude:(NSNumber *)latitude longitude:(NSNumber *)longitude {

    UACircularRegion *circularRegion = [[self alloc] init];

    circularRegion.radius = radius;
    circularRegion.latitude = latitude;
    circularRegion.longitude = longitude;

    if (!circularRegion.isValid) {
        return nil;
    }

    return circularRegion;
}

- (BOOL)isValid {
    if (![UARegionEvent regionEventRadiusIsValid:self.radius]) {
        UA_LERR(@"Circular region radius must not be greater than %d meters or less than %f meters.", kUACircularRegionMaxRadius, kUACircularRegionMinRadius);
        return NO;
    }

    if (![UARegionEvent regionEventLatitudeIsValid:self.latitude]) {
        UA_LERR(@"Circular region latitude must not be greater than %d or less than %d degrees.", kUARegionEventMaxLatitude, kUARegionEventMinLatitude);
        return NO;
    }

    if (![UARegionEvent regionEventLongitudeIsValid:self.longitude]) {
        UA_LERR(@"Circular region longitude must not be greater than %d or less than %d degrees.", kUARegionEventMaxLongitude, kUARegionEventMinLongitude);
        return NO;
    }

    return YES;
}

@end
