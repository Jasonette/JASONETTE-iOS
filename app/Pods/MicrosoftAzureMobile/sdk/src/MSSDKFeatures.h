// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#pragma mark * Telemetry features definitions

typedef NS_OPTIONS(NSUInteger, MSFeatures) {
    MSFeatureNone                     = 0,

    // Custom API where the request / response body is serialized
    // into / deserialized from JSON
    MSFeatureApiJson                  = 1 << 0,

    // Custom API where the request / response body is given as a
    // NSData object
    MSFeatureApiGeneric               = 1 << 1,

    // Table or API calls where the caller passes additional query
    // string parameters
    MSFeatureQueryParameters          = 1 << 2,

    // Table reads where the caller uses a MSQuery / NSPredicate to
    // determine the items to be returned
    MSFeatureTableReadQuery           = 1 << 3,

    // Table reads where the caller uses a raw query string to determine
    // the items to be returned
    MSFeatureTableReadRaw             = 1 << 4,

    // Conditional table updates / deletes (If-Match based on record version)
    MSFeatureOpportunisticConcurrency = 1 << 5,

    // Table reads / writes originated from a sync (offline) table
    MSFeatureOffline                  = 1 << 6,
    
    // Table read with absolute url as queryString parameter
    MSFeatureReadWithLinkHeader       = 1 << 7,
    
    // Table read is using incremental pull
    MSFeatureIncrementalPull          = 1 << 8,
    
    // Refresh Token
    MSFeatureRefreshToken             = 1 << 9
};

extern NSString *const MSFeaturesHeaderName;

extern NSString *const MSFeatureCodeApiJson;
extern NSString *const MSFeatureCodeApiGeneric;
extern NSString *const MSFeatureCodeQueryParameters;
extern NSString *const MSFeatureCodeTableReadQuery;
extern NSString *const MSFeatureCodeTableReadRaw;
extern NSString *const MSFeatureCodeOpportunisticConcurrency;
extern NSString *const MSFeatureCodeOffline;
extern NSString *const MSFeatureCodeIncrementalPull;
extern NSString *const MSFeatureCodeRefreshToken;


// The |MSSDKFeatures| class defines methods to convert between the
// |MSFeatures| enumeration and the value to be sent in HTTP requests
// with telemetry information to the service.
@interface MSSDKFeatures : NSObject

+(NSString *)httpHeaderForFeatures:(MSFeatures)features;

@end
