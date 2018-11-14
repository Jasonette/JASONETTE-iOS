/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UACustomEvent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A UAMediaEventTemplate represents a custom media event template for the
 * application.
 */
@interface UAMediaEventTemplate : NSObject

///---------------------------------------------------------------------------------------
/// @name Media Event Template Properties
///---------------------------------------------------------------------------------------

/**
 * The event's ID. The ID's length must not exceed 255 characters or it will
 * invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *identifier;

/**
 * The event's category. The category's length must not exceed 255 characters or
 * it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *category;

/**
 * The event's type. The type's length must not exceed 255 characters or it will
 * invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *type;

/**
 * The event's description. The description's length must not exceed 255 characters
 * or it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *eventDescription;

/**
 * `YES` if the event is a feature, else `NO`.
 */
@property (nonatomic, assign) BOOL isFeature;

/**
 * The event's author. The author's length must not exceed 255 characters
 * or it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *author;

/**
 * The event's publishedDate. The publishedDate's length must not exceed 255 characters
 * or it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *publishedDate;

///---------------------------------------------------------------------------------------
/// @name Media Event Template Factories
///---------------------------------------------------------------------------------------

/**
 * Factory method for creating a browsed content event template.
 */
+ (instancetype)browsedTemplate;

/**
 * Factory method for creating a starred content event template.
 */
+ (instancetype)starredTemplate;

/**
 * Factory method for creating a shared content event template.
 */
+ (instancetype)sharedTemplate;

/**
 * Factory method for creating a shared content event template.
 * If the source or medium exceeds 255 characters it will cause the event to be invalid.
 *
 * @param source The source as an NSString.
 * @param medium The medium as an NSString.
 */
+ (instancetype)sharedTemplateWithSource:(nullable NSString *)source withMedium:(nullable NSString *)medium;

/**
 * Factory method for creating a consumed content event template.
 */
+ (instancetype)consumedTemplate;

/**
 * Factory method for creating a consumed content event template with a value.
 *
 * @param eventValue The value of the event as as string. The value must be between
 * -2^31 and 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)consumedTemplateWithValueFromString:(nullable NSString *)eventValue;

/**
 * Factory method for creating a consumed content event template with a value.
 *
 * @param eventValue The value of the event. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)consumedTemplateWithValue:(nullable NSNumber *)eventValue;

/**
 * Creates the custom media event.
 */
- (UACustomEvent *)createEvent;

@end

NS_ASSUME_NONNULL_END
