/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAEvent.h"

@class UANotificationAction;

NS_ASSUME_NONNULL_BEGIN

/**
 * A UAInteractiveNotificationEvent captures information regarding an interactive
 * notification event for UAAnalytics.
 */
@interface UAInteractiveNotificationEvent : UAEvent

///---------------------------------------------------------------------------------------
/// @name Interactive Notificaiton Event Internal Factories
///---------------------------------------------------------------------------------------

/**
 * Factory method for creating an interactive notification event.
 *
 * @param action The triggered UANotificationAction.
 * @param category The category in the notification.
 * @param notification The notification.
 */
+ (instancetype)eventWithNotificationAction:(UANotificationAction *)action
                                 categoryID:(NSString *)category
                               notification:(NSDictionary *)notification;

/**
 * Factory method for creating an interactive notification event.
 *
 * @param action The triggered UANotificationAction.
 * @param category The category in the notification.
 * @param notification The notification.
 * @param responseText The response text, as passed to the application delegate or notification center delegate.
 */
+ (instancetype)eventWithNotificationAction:(UANotificationAction *)action
                                 categoryID:(NSString *)category
                               notification:(NSDictionary *)notification
                               responseText:(nullable NSString *)responseText;

@end

NS_ASSUME_NONNULL_END
