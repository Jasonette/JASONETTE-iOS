/* Copyright 2017 Urban Airship and Contributors */

#import "UAGlobal.h"
#import "UAJavaScriptDelegate.h"
#import "UAWhitelist.h"
#import "UAirshipVersion.h"

// Frameworks
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <Security/Security.h>
#import <QuartzCore/QuartzCore.h>
#import <Availability.h>
#import <UserNotifications/UserNotifications.h>
#import <StoreKit/StoreKit.h>

#import "UAConfig.h"

#if !TARGET_OS_TV    // CoreTelephony and WebKit not supported in tvOS
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <WebKit/WebKit.h>

#endif

@class UAConfig;
@class UAAnalytics;
@class UAApplicationMetrics;
@class UAPush;
@class UAUser;
@class UANamedUser;
@class UAActionRegistry;
@class UAInAppMessaging;
@class UADefaultMessageCenter;
@class UALocation;
@class UAAutomation;
@class UAChannelCapture;

#if !TARGET_OS_TV   // Inbox not supported on tvOS
@class UAInbox;
#endif


NS_ASSUME_NONNULL_BEGIN

/**
 * The takeOff method must be called on the main thread. Not doing so results in 
 * this exception being thrown.
 */
extern NSString * const UAirshipTakeOffBackgroundThreadException;

/**
 * UAirship manages the shared state for all Urban Airship services. [UAirship takeOff:] should be
 * called from within your application delegate's `application:didFinishLaunchingWithOptions:` method
 * to initialize the shared instance.
 */
@interface UAirship : NSObject

/**
 * The application configuration. This is set on takeOff.
 */
@property (nonatomic, strong, readonly) UAConfig *config;

/**
 * The shared analytics manager. There are not currently any user-defined events,
 * so this is for internal library use only at this time.
 */
@property (nonatomic, strong, readonly) UAAnalytics *analytics;


/**
 * The default action registry.
 */
@property (nonatomic, strong, readonly) UAActionRegistry *actionRegistry;


/**
 * Stores common application metrics such as last open.
 */
@property (nonatomic, strong, readonly) UAApplicationMetrics *applicationMetrics;

/**
 * This flag is set to `YES` if the application is set up 
 * with the "remote-notification" background mode
 */
@property (nonatomic, assign, readonly) BOOL remoteNotificationBackgroundModeEnabled;


/**
 * A user configurable JavaScript delegate.
 *
 * NOTE: this delegate is not retained.
 */
@property (nonatomic, weak, nullable) id<UAJavaScriptDelegate> jsDelegate;

/**
 * The whitelist used for validating webview URLs.
 */
@property (nonatomic, strong, readonly) UAWhitelist *whitelist;

/**
 * The channel capture utility.
 */
@property (nonatomic, strong, readonly) UAChannelCapture *channelCapture;

///---------------------------------------------------------------------------------------
/// @name Logging
///---------------------------------------------------------------------------------------

/**
 * Enables or disables logging. Logging is enabled by default, though the log level must still be set
 * to an appropriate value.
 *
 * @param enabled If `YES`, console logging is enabled.
 */
+ (void)setLogging:(BOOL)enabled;

/**
 * Sets the log level for the Urban Airship library. The log level defaults to `UALogLevelDebug`
 * for development apps, and `UALogLevelError` for production apps (when the inProduction
 * AirshipConfig flag is set to `YES`). Values set with this method prior to `takeOff` will be overridden
 * during takeOff.
 * 
 * @param level The desired `UALogLevel` value.
 */
+ (void)setLogLevel:(UALogLevel)level;

/**
 * Enables or disables logging implementation errors with emoji to make it stand
 * out in the console. It is enabled by default, and will be disabled for production
 * applications.
 *
 * @param enabled If `YES`, loud implementation error logging is enabled.
 */
+ (void)setLoudImpErrorLogging:(BOOL)enabled;

///---------------------------------------------------------------------------------------
/// @name Lifecycle
///---------------------------------------------------------------------------------------

/**
 * Initializes UAirship and performs all necessary setup. This creates the shared instance, loads
 * configuration values, initializes the analytics/reporting
 * module and creates a UAUser if one does not already exist.
 * 
 * This method *must* be called from your application delegate's
 * `application:didFinishLaunchingWithOptions:` method, and it may be called
 * only once.
 *
 * @warning `takeOff:` must be called on the main thread. This method will throw
 * an `UAirshipTakeOffMainThreadException` if it is run on a background thread.
 * @param config The populated UAConfig to use.
 *
 */
+ (void)takeOff:(nullable UAConfig *)config;

/**
 * Simplified `takeOff` method that uses `AirshipConfig.plist` for initialization.
 */
+ (void)takeOff;

///---------------------------------------------------------------------------------------
/// @name Instance Accessors
///---------------------------------------------------------------------------------------

/**
 * Returns the `UAirship` instance.
 *
 * @return The `UAirship` instance.
 */
+ (null_unspecified UAirship *)shared;

/**
 * Returns the `UAPush` instance. Used for configuring and managing push
 * notifications.
 *
 * @return The `UAPush` instance.
 */
+ (null_unspecified UAPush *)push;

#if !TARGET_OS_TV   // Inbox not supported on tvOS
/**
 * Returns the `UAInbox` instance. Provides access to the inbox messages.
 *
 * @return The `UAInbox` instance.
 */
+ (null_unspecified UAInbox *)inbox;

/**
 * Returns the `UAUser` instance.
 *
 * @return The `UAUser` instance.
 */
+ (null_unspecified UAUser *)inboxUser;


/**
 * Returns the `UAInAppMessaging` instance. Used for customizing
 * in-app notifications.
 */
+ (null_unspecified UAInAppMessaging *)inAppMessaging;

/**
 * Returns the `UADefaultMessageCenter` instance. Used for customizing
 * and displaying the default message center.
 */
+ (null_unspecified UADefaultMessageCenter *)defaultMessageCenter;

#endif

/**
 * Returns the `UANamedUser` instance.
 */
+ (null_unspecified UANamedUser *)namedUser;

/**
 * Returns the AirshipResources bundle, or nil if the the bundle
 * cannot be located at runtime.
 */
+ (nullable NSBundle *) resources;


/**
 * Returns the `UALocation` instance.
 */
+ (null_unspecified UALocation *)location;


/**
 * Returns the `UAAutomation` instance.
 */
+ (null_unspecified UAAutomation *)automation;

NS_ASSUME_NONNULL_END

@end

