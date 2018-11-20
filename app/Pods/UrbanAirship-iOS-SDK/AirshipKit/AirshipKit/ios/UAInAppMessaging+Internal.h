/* Copyright 2017 Urban Airship and Contributors */

#import "UAInAppMessaging.h"
#import "UAInAppMessageController+Internal.h"

// User defaults key for storing and retrieving pending messages
#define kUAPendingInAppMessageDataStoreKey @"UAPendingInAppMessage"

// User defaults key for storing and retrieving auto display enabled
#define kUAAutoDisplayInAppMessageDataStoreKey @"UAAutoDisplayInAppMessageDataStoreKey"

@class UAPreferenceDataStore;
@class UAAnalytics;
@class UAPush;
@class UANotificationResponse;
@class UANotificationContent;

NS_ASSUME_NONNULL_BEGIN
/*
 * SDK-private extensions to UAInAppMessaging
 */
@interface UAInAppMessaging ()

///---------------------------------------------------------------------------------------
/// @name In App Messaging Internal Properties
///---------------------------------------------------------------------------------------

/**
 * A Boolean value indicating whether or not the keyboard is displayed.
 */
@property(nonatomic, assign, getter=isKeyboardDisplayed) BOOL keyboardDisplayed;

///---------------------------------------------------------------------------------------
/// @name In App Messaging Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create an UAInAppMessaging instance.
 * @param analytics The UAAnalytics instance.
 * @param dataStore The preference data store.
 * @return An instance of UAInAppMessaging.
 */
+ (instancetype)inAppMessagingWithAnalytics:(UAAnalytics *)analytics
                                  dataStore:(UAPreferenceDataStore *)dataStore;

/**
 * Invalidates the autodisplay timer.
 */
- (void)invalidateAutoDisplayTimer;

/**
 * Called when a notification response is received.
 *
 * @param response The notification response.
 */
- (void)handleNotificationResponse:(UANotificationResponse *)response;

/**
 * Called when a remote notification is received.
 *
 * @param notification The notification content.
 */
- (void)handleRemoteNotification:(UANotificationContent *)notification;

@end

NS_ASSUME_NONNULL_END
