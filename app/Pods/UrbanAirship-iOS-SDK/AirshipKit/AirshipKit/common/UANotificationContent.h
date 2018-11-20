/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UNNotification;

/**
 * Clone of UNNotificationContent for iOS 8-9 support. Contains convenient accessors
 * to the notification's content.
 */
@interface UANotificationContent : NSObject

///---------------------------------------------------------------------------------------
/// @name Notification Content Properties
///---------------------------------------------------------------------------------------

/**
 * Alert title
 */
@property (nonatomic, copy, nullable, readonly) NSString *alertTitle;

/**
 * Alert body
 */
@property (nonatomic, copy, nullable, readonly) NSString *alertBody;

/**
 * Sound file name
 */
@property (nonatomic, copy, nullable, readonly) NSString *sound;

/**
 * Badge number
 */
@property (nonatomic, assign, nullable, readonly) NSNumber *badge;

/**
 * Content available
 */
@property (nonatomic, strong, nullable, readonly) NSNumber *contentAvailable;

/**
 * Category
 */
@property (nonatomic, copy, nullable, readonly) NSString *categoryIdentifier;

/**
 * Launch image file name
 */
@property (nonatomic, copy, nullable, readonly) NSString *launchImage;

/**
 * Localization keys
 */
@property (nonatomic, copy, nullable, readonly) NSDictionary *localizationKeys;

/**
 * Notification info dictionary used to generate the UANotification.
 */
@property (nonatomic, copy, readonly) NSDictionary *notificationInfo;

/**
 * UNNotification used to generate the UANotification.
 */
@property (nonatomic, strong, nullable, readonly) UNNotification *notification;

///---------------------------------------------------------------------------------------
/// @name Notification Content Utilities
///---------------------------------------------------------------------------------------

/**
 * Parses the raw notification dictionary into a UANotification.
 *
 * @param notificationInfo The raw notification dictionary.
 *
 * @return UANotification instance
 */
+ (instancetype)notificationWithNotificationInfo:(NSDictionary *)notificationInfo;

/**
 * Converts a UNNotification into a UANotification.
 *
 * @param notification the UNNotification instance to be converted.
 *
 * @return UANotification instance
 */
+ (instancetype)notificationWithUNNotification:(UNNotification *)notification;

@end

NS_ASSUME_NONNULL_END
