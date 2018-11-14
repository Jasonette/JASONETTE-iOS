/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UANotificationContent.h"

NS_ASSUME_NONNULL_BEGIN

@class UNNotificationResponse;

/**
 * Clone of UNNotificationResponse for iOS 8-9 support. Contains the
 * user's reponse to a notification.
 */
@interface UANotificationResponse : NSObject

/**
 * Action identifier representing an application launch via notification.
 */
extern NSString *const UANotificationDefaultActionIdentifier;

/**
 * Action identifier representing a notification dismissal.
 */
extern NSString *const UANotificationDismissActionIdentifier;

///---------------------------------------------------------------------------------------
/// @name Notification Response Properties
///---------------------------------------------------------------------------------------

/**
 * Action identifier for the response.
 */
@property (nonatomic, copy, readonly) NSString *actionIdentifier;

/**
 * String populated with any response text provided by the user.
 */
@property (nonatomic, copy, readonly) NSString *responseText;

/**
 * The UANotificationContent instance associated with the response.
 */
@property (nonatomic, strong, readonly) UANotificationContent *notificationContent;

#if !TARGET_OS_TV    // UNNotificationResponse not available on tvOS
/**
 * The UNNotificationResponse that generated the UANotificationResponse.
 * Note: Only available on iOS 10+. Will be nil otherwise.
 */
@property (nonatomic, readonly, nullable, strong) UNNotificationResponse *response;

#endif

///---------------------------------------------------------------------------------------
/// @name Notification Response Factories
///---------------------------------------------------------------------------------------

/**
 * UANotificationResponse factory method.
 *
 * @param notificationInfo The notification user info.
 * @param actionIdentifier The notification action ID.
 * @param responseText Optional response text.
 * @return A UANotificationResponse instance.
 */
+ (instancetype)notificationResponseWithNotificationInfo:(NSDictionary *)notificationInfo
                                        actionIdentifier:(NSString *)actionIdentifier
                                            responseText:(nullable NSString *)responseText;

#if !TARGET_OS_TV    // UNNotificationResponse not available on tvOS
/**
 * UANotificationResponse factory method.
 *
 * @param response The UNNotificationResponse.
 * @return A UANotificationResponse instance.
 */
+ (instancetype)notificationResponseWithUNNotificationResponse:(UNNotificationResponse *)response;
#endif


@end

NS_ASSUME_NONNULL_END
