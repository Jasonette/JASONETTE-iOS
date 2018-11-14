/* Copyright 2017 Urban Airship and Contributors */

#import "UACustomEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface UACustomEvent ()

/**
 * The send ID that triggered the event.
 */
@property (nonatomic, copy, nullable) NSString *conversionSendID;

/**
 * The conversion push metadata.
 */
@property (nonatomic, copy, nullable) NSString *conversionPushMetadata;

/**
 * The event's template type. The template type's length must not exceed 255 characters or it will
 * invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *templateType;

/**
 * The event's JSON payload. Used for automation.
 */
@property (nonatomic, readonly) NSDictionary *payload;

@end

NS_ASSUME_NONNULL_END
