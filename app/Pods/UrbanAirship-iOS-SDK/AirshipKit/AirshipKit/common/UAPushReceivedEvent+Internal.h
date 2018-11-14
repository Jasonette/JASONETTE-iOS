/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "UAEvent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Event when a push notification is received.
 */
@interface UAPushReceivedEvent : UAEvent

///---------------------------------------------------------------------------------------
/// @name Push Received Event Internal Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAPushReceivedEvent.
 * @param notification The received push notification.
 */
+ (instancetype)eventWithNotification:(NSDictionary *)notification;

@end

NS_ASSUME_NONNULL_END
