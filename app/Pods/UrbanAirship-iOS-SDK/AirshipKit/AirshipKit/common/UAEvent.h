/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

/**
 * This base class encapsulates analytics events.
 */
@interface UAEvent : NSObject

///---------------------------------------------------------------------------------------
/// @name Event Properties
///---------------------------------------------------------------------------------------

/**
 * The time the event was created.
 */
@property (nonatomic, readonly, copy) NSString *time;

/**
 * The unique event ID.
 */
@property (nonatomic, readonly, copy) NSString *eventID;

/**
 * The event's data.
 */
@property (nonatomic, readonly, strong) NSDictionary *data;

/**
 * The event's type.
 */
@property (nonatomic, readonly) NSString *eventType;

///---------------------------------------------------------------------------------------
/// @name Event Validation
///---------------------------------------------------------------------------------------

/**
 * Checks if the event is valid. Invalid events will be dropped.
 * @return YES if the event is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
