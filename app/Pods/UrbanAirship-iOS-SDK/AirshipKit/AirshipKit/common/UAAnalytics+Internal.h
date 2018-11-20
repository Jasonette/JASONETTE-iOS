/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAAnalytics.h"

#define kUAAnalyticsEnabled @"UAAnalyticsEnabled"
#define kUAMissingSendID @"MISSING_SEND_ID"
#define kUAPushMetadata @"com.urbanairship.metadata"

@class UACustomEvent;
@class UARegionEvent;
@class UAPreferenceDataStore;
@class UAConfig;
@class UAEventManager;

NS_ASSUME_NONNULL_BEGIN


/**
 * Analytics delegate.
 */
@protocol UAAnalyticsDelegate <NSObject>

///---------------------------------------------------------------------------------------
/// @name Analytics Delegate Internal Methods
///---------------------------------------------------------------------------------------

@optional
/**
 * Called when a custom event was added.
 *
 * @param event The added custom event.
 */
-(void)customEventAdded:(UACustomEvent *)event;


/**
 * Called when a region event was added.
 *
 * @param event The added region event.
 */
-(void)regionEventAdded:(UARegionEvent *)event;

/**
 * Called when a screen was tracked. Called when a `trackScreen:` is first called.
 * An event will be added for the screen will be added after the next time
 * `trackScreen:` is called or if the application backgrounds.
 *
 * @param screenName Name of the screen.
 */
-(void)screenTracked:(nullable NSString *)screenName;

@end

/*
 * SDK-private extensions to Analytics
 */
@interface UAAnalytics ()

///---------------------------------------------------------------------------------------
/// @name Analytics Internal Properties
///---------------------------------------------------------------------------------------

/**
 * Set a delegate that implements the UAAnalyticsDelegate protocol.
 */
@property (nonatomic, weak, nullable) id<UAAnalyticsDelegate> delegate;

/**
 * The conversion send ID.
 */
@property (nonatomic, copy, nullable) NSString *conversionSendID;

/**
 * The conversion push metadata.
 */
@property (nonatomic, copy, nullable) NSString *conversionPushMetadata;

/**
 * The conversion rich push ID.
 */
@property (nonatomic, copy, nullable) NSString *conversionRichPushID;

/**
 * The current session ID.
 */
@property (nonatomic, copy, nullable) NSString *sessionID;

///---------------------------------------------------------------------------------------
/// @name Analytics Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create an analytics instance.
 * @param airshipConfig The 'AirshipConfig.plist' file
 * @param dataStore The shared preference data store.
 * @return A new analytics instance.
 */
+ (instancetype)analyticsWithConfig:(UAConfig *)airshipConfig
                          dataStore:(UAPreferenceDataStore *)dataStore;


/**
 * Factory method to create an analytics instance.
 * @param airshipConfig The 'AirshipConfig.plist' file
 * @param dataStore The shared preference data store.
 * @param eventManager An event manager instance.
 * @return A new analytics instance.
 */
+ (instancetype)analyticsWithConfig:(UAConfig *)airshipConfig
                          dataStore:(UAPreferenceDataStore *)dataStore
                       eventManager:(UAEventManager *)eventManager;

/**
 * Called to notify analytics the app was launched from a push notification.
 * @param notification The push notification.
 */
- (void)launchedFromNotification:(NSDictionary *)notification;

/**
 * Cancels any scheduled event uploads.
 */
- (void)cancelUpload;

@end

NS_ASSUME_NONNULL_END
