/* Copyright 2017 Urban Airship and Contributors */

#import "UAEvent.h"

@class UAInAppMessage;

NS_ASSUME_NONNULL_BEGIN

/**
 * In-app message display event.
 */
@interface UAInAppDisplayEvent : UAEvent

///---------------------------------------------------------------------------------------
/// @name In App Display Event Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAInAppDisplayEvent event.
 * @param message The in-app message.
 * @return A in-app display event.
 */
+ (instancetype)eventWithMessage:(UAInAppMessage *)message;

@end

NS_ASSUME_NONNULL_END
