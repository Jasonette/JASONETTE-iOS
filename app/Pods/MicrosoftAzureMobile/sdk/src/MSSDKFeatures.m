// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSSDKFeatures.h"

#pragma mark * Telemetry Features String Constants

NSString *const MSFeaturesHeaderName = @"X-ZUMO-FEATURES";
NSString *const MSFeatureCodeApiJson = @"AJ";
NSString *const MSFeatureCodeApiGeneric = @"AG";
NSString *const MSFeatureCodeQueryParameters = @"QS";
NSString *const MSFeatureCodeTableReadQuery = @"TQ";
NSString *const MSFeatureCodeTableReadRaw = @"TR";
NSString *const MSFeatureCodeOpportunisticConcurrency = @"OC";
NSString *const MSFeatureCodeOffline = @"OL";
NSString *const MSFeatureCodeReadWithLinkHeader = @"LH";
NSString *const MSFeatureCodeIncrementalPull = @"IP";
NSString *const MSFeatureCodeRefreshToken = @"RT";

@implementation MSSDKFeatures

+(NSString *)httpHeaderForFeatures:(MSFeatures)features {
    if (features == MSFeatureNone) return nil;

    NSMutableArray *allFeatures = [[NSMutableArray alloc] init];
    if (features & MSFeatureApiGeneric) {
        [allFeatures addObject:MSFeatureCodeApiGeneric];
    }
    if (features & MSFeatureApiJson) {
        [allFeatures addObject:MSFeatureCodeApiJson];
    }
    if (features & MSFeatureTableReadQuery) {
        [allFeatures addObject:MSFeatureCodeTableReadQuery];
    }
    if (features & MSFeatureTableReadRaw) {
        [allFeatures addObject:MSFeatureCodeTableReadRaw];
    }
    if (features & MSFeatureQueryParameters) {
        [allFeatures addObject:MSFeatureCodeQueryParameters];
    }
    if (features & MSFeatureOpportunisticConcurrency) {
        [allFeatures addObject:MSFeatureCodeOpportunisticConcurrency];
    }
    if (features & MSFeatureOffline) {
        [allFeatures addObject:MSFeatureCodeOffline];
    }
    if (features & MSFeatureReadWithLinkHeader) {
        [allFeatures addObject:MSFeatureCodeReadWithLinkHeader];
    }
    if (features & MSFeatureIncrementalPull) {
        [allFeatures addObject:MSFeatureCodeIncrementalPull];
    }
    if (features & MSFeatureRefreshToken) {
        [allFeatures addObject:MSFeatureCodeRefreshToken];
    }

    return [allFeatures componentsJoinedByString:@","];
}

@end
