/* Copyright 2017 Urban Airship and Contributors */

#import "UAEvent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Event when app exits.
 */
@interface UAAppExitEvent : UAEvent

///---------------------------------------------------------------------------------------
/// @name App Exit Event Internal Factory
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAAppExitEvent.
 */
+ (instancetype)event;

@end

NS_ASSUME_NONNULL_END
