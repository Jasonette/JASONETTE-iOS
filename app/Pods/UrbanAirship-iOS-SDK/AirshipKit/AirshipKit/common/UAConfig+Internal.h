/* Copyright 2017 Urban Airship and Contributors */

#import "UAConfig.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * SDK-private extensions to UAConfig
 */
@interface UAConfig ()

///---------------------------------------------------------------------------------------
/// @name Config Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The provisioning profile path to use for this configuration. It defaults to the `embedded.mobileprovision` file
 * included with app packages, but it may be customized for testing purposes.
 */
@property (nonatomic, copy, nullable) NSString *profilePath;

/*
 * The master secret for running functional tests. Not for use in production!
 */
@property (nonatomic, copy, nullable) NSString *testingMasterSecret;

/**
 * Defaults to `YES` if the current device is a simulator. Exposed for testing/mocking purposes.
 */
@property (nonatomic, readonly) BOOL isSimulator;

/**
 * Defaults the defaultDetectProvisioningMode flag to `YES`.
 */
@property (nonatomic, assign) BOOL defaultDetectProvisioningMode;

/**
 * Determines whether or not the app is currently configured to use the APNS production servers.
 * @return `YES` if using production servers, `NO` if development servers or if the app is not properly
 * configured for push.
 */
@property (nonatomic, strong) NSNumber *usesProductionPushServer;

///---------------------------------------------------------------------------------------
/// @name Config Internal Methods
///---------------------------------------------------------------------------------------


/**
 * Tests if the profile at a given path is set up for the production push environment.
 * @param profilePath The specified path of the profile.
 * @return `YES` if using production servers, `NO` if development servers or if the app is not properly
 * configured for push.
 */
+ (BOOL)isProductionProvisioningProfile:(NSString *)profilePath;

/*
 * Converts string keys from the old ALL_CAPS format to the new property name format. Transforms
 * boolean strings (YES/NO) into NSNumber BOOLs if the target property is a primitive char type. Transforms
 * integer strings ("1", "5", etc. for log levels) into NSNumber objects.
 * @param keyedValues The dictionary to be normalized.
 * @return A normalized NSDictionary.
 */
+ (NSDictionary *)normalizeDictionary:(NSDictionary *)keyedValues;

@end

NS_ASSUME_NONNULL_END


