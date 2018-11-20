/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

#import "UAGlobal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The UAConfig object provides an interface for passing common configurable values to [UAirship takeOff].
 * The simplest way to use this class is to add an AirshipConfig.plist file in your app's bundle and set
 * the desired options. The plist keys use the same names as this class's configuration options. Older,
 * all-caps keys are still supported, but you should migrate your properties file to make use of a number 
 * of new options.
 */
@interface UAConfig : NSObject <NSCopying>

///---------------------------------------------------------------------------------------
/// @name Configuration Options
///---------------------------------------------------------------------------------------

/**
 * The development app key. This should match the application on go.urbanairship.com that is
 * configured with your development push certificate.
 */
@property (nonatomic, copy, nullable) NSString *developmentAppKey;

/**
 * The development app secret. This should match the application on go.urbanairship.com that is
 * configured with your development push certificate.
 */
@property (nonatomic, copy, nullable) NSString *developmentAppSecret;

/**
 * The production app key. This should match the application on go.urbanairship.com that is
 * configured with your production push certificate. This is used for App Store, Ad-Hoc and Enterprise
 * app configurations.
 */
@property (nonatomic, copy, nullable) NSString *productionAppKey;

/**
 * The production app secret. This should match the application on go.urbanairship.com that is
 * configured with your production push certificate. This is used for App Store, Ad-Hoc and Enterprise
 * app configurations.
 */
@property (nonatomic, copy, nullable) NSString *productionAppSecret;

/**
 * The log level used for development apps. Defaults to `UALogLevelDebug` (4).
 */
@property (nonatomic, assign) UALogLevel developmentLogLevel;

/**
 * The log level used for production apps. Defaults to `UALogLevelError` (1).
 */
@property (nonatomic, assign) UALogLevel productionLogLevel;

/**
 * The size in MB for the UA Disk Cache.  Defaults to 100.
 *
 * Only items that are small enough (1/20th of the size) of the cache will be 
 * cached.
 * 
 * Any size greater than 0 will cause the UA Disk Cache to become active. 
 * UAURLProtocol will be registered as a NSURLProtocol.  Only requests whose
 * mainDocumentURL or URL that have been added as a cachable URL will be considered
 * for caching.  By defualt it includes all of the Rich Application Page URLs.
 *
 */
@property (nonatomic, assign) NSUInteger cacheDiskSizeInMB;

/**
 * If enabled, the UA library automatically registers for remote notifications when push is enabled
 * and intercepts incoming notifications in both the foreground and upon launch.
 *
 * Defaults to YES. If this is disabled, you will need to register for remote notifications
 * in application:didFinishLaunchingWithOptions: and forward all notification-related app delegate
 * calls to UAPush and UAInbox.
 */
@property (nonatomic, assign, getter=isAutomaticSetupEnabled) BOOL automaticSetupEnabled;

/**
 * An array of UAWhitelist entry strings.
 *
 * @note See UAWhitelist for pattern entry syntax.
 */
@property (nonatomic, strong) NSArray<NSString *> *whitelist;

///---------------------------------------------------------------------------------------
/// @name Advanced Configuration Options
///---------------------------------------------------------------------------------------

/**
 * Toggles Urban Airship analytics. Defaults to `YES`. If set to `NO`, many UA features will not be
 * available to this application.
 */
@property (nonatomic, assign, getter=isAnalyticsEnabled) BOOL analyticsEnabled;

/**
 * Apps may be set to self-configure based on the APS-environment set in the
 * embedded.mobileprovision file by using detectProvisioningMode. If
 * detectProvisioningMode is set to `YES`, the inProduction value will
 * be determined at runtime by reading the provisioning profile. If it is set to
 * `NO` (the default), the inProduction flag may be set directly or by using the
 * AirshipConfig.plist file.
 *
 * When this flag is enabled, the inProduction flag defaults to `YES` for safety
 * so that the production keys will always be used if the profile cannot be read
 * in a released app. Simulator builds do not include the profile, and the
 * detectProvisioningMode flag does not have any effect in cases where a profile
 * is not present. When a provisioning file is not present, the app will fall
 * back to the inProduction property as set in code or the AirshipConfig.plist
 * file.
 */
@property (nonatomic, assign) BOOL detectProvisioningMode;

/**
 * The Urban Airship device API url. This option is reserved for internal debugging.
 */
@property (nonatomic, copy) NSString *deviceAPIURL;

/**
 * The Urban Airship analytics API url. This option is reserved for internal debugging.
 */
@property (nonatomic, copy) NSString *analyticsURL;

/**
 * The Urban Airship landing page content url. This option is reserved for internal debugging.
 */
@property (nonatomic, copy) NSString *landingPageContentURL;

/**
 * The Urban Airship default message center style configuration file.
 */
@property (nonatomic, copy) NSString *messageCenterStyleConfig;

/**
 * The iTunes ID used for Rate App Actions.
 */
@property (nonatomic, copy) NSString *itunesID;

/**
 * If set to `YES`, the Urban Airship user will be cleared if the application is
 * restored on a different device from an encrypted backup.
 *
 * Defaults to `NO`.
 */
@property (nonatomic, assign) BOOL clearUserOnAppRestore;

/**
 * If set to `YES`, the application will clear the previous named user ID on a
 * re-install. Defaults to `NO`.
 */
@property (nonatomic, assign) BOOL clearNamedUserOnAppRestore;

/**
 * Flag indicating whether channel capture feature is enabled or not.
 *
 * Defaults to `YES`.
 */
@property (nonatomic, assign, getter=isChannelCaptureEnabled) BOOL channelCaptureEnabled;

/**
 * Flag indicating whether delayed channel creation is enabled. If set to `YES` channel 
 * creation will not occur until channel creation is manually enabled.
 *
 * Defaults to `NO`.
 */
@property (nonatomic, assign, getter=isChannelCreationDelayEnabled) BOOL channelCreationDelayEnabled;

/**
 * Dictionary of custom config values.
 */
@property (nonatomic, copy) NSDictionary *customConfig;

/**
 * If set to `YES`, SDK will use WKWebView for UA default inbox message and overlay views.
 * If set to `NO`,  SDK will use UIWebView for UA default inbox message and overlay views.
 *
 * Defaults to `NO`. 
 * @note Will default to `YES` in SDK 9.0.
 */
@property (nonatomic, assign) BOOL useWKWebView;

///---------------------------------------------------------------------------------------
/// @name Resolved Options
///---------------------------------------------------------------------------------------

/**
 * The current app key (resolved using the inProduction flag).
 */
@property (nonatomic, readonly, nullable) NSString *appKey;

/**
 * The current app secret (resolved using the inProduction flag).
 */
@property (nonatomic, readonly, nullable) NSString *appSecret;

/**
 * The current log level for the library's UA_L<level> macros (resolved using the inProduction flag).
 */
@property (nonatomic, readonly) UALogLevel logLevel;

/**
 * The production status of this application. This may be set directly, or it may be determined
 * automatically if the detectProvisioningMode flag is set to `YES`.
 */
@property (nonatomic, assign, getter=isInProduction) BOOL inProduction;

///---------------------------------------------------------------------------------------
/// @name Factory Methods
///---------------------------------------------------------------------------------------

/**
 * Creates an instance using the values set in the `AirshipConfig.plist` file.
 * @return A UAConfig with values from `AirshipConfig.plist` file.
 */
+ (UAConfig *)defaultConfig;

/**
 * Creates an instance using the values found in the specified `.plist` file.
 * @param path The path of the specified file.
 * @return A UAConfig with values from the specified file.
 */
+ (UAConfig *)configWithContentsOfFile:(NSString *)path;

/**
 * Creates an instance with empty values.
 * @return A UAConfig with empty values.
 */
+ (UAConfig *)config;

///---------------------------------------------------------------------------------------
/// @name Utilities, Helpers
///---------------------------------------------------------------------------------------

/**
 * Validates the current configuration. In addition to performing a strict validation, this method
 * will log warnings and common configuration errors.
 * @return `YES` if the current configuration is valid, otherwise `NO`.
 */
- (BOOL)validate;

@end

NS_ASSUME_NONNULL_END
