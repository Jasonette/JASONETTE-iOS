/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UACustomEvent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A UAAccountEventTemplate represents a custom account event template for the
 * application.
 */
@interface UAAccountEventTemplate : NSObject

///---------------------------------------------------------------------------------------
/// @name Account Event Template Properties
///---------------------------------------------------------------------------------------

/**
* The event's value. The value must be between -2^31 and
* 2^31 - 1 or it will invalidate the event.
*/
@property (nonatomic, strong, nullable) NSDecimalNumber *eventValue;

/**
 * The event's transaction ID. The transaction ID's length must not exceed 255
 * characters or it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *transactionID;

/**
 * The event's category. The category's length must not exceed 255 characters or
 * it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *category;

///---------------------------------------------------------------------------------------
/// @name Account Event Template Factories
///---------------------------------------------------------------------------------------

/**
 * Factory method for creating a registered account event template.
 */
+ (instancetype)registeredTemplate;

/**
 * Factory method for creating a registered account event template with a value from a string.
 *
 * @param eventValue The value of the event as a string. The value must be a valid
 * number between -2^31 and 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)registeredTemplateWithValueFromString:(nullable NSString *)eventValue;

/**
 * Factory method for creating a registered account event template with a value.
 *
 * @param eventValue The value of the event. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)registeredTemplateWithValue:(nullable NSNumber *)eventValue;

/**
 * Creates the custom account event.
 */
- (UACustomEvent *)createEvent;

@end

NS_ASSUME_NONNULL_END
