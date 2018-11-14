/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/**
 * CoreData class representing the backing data for
 * a UAEvent.
 *
 * This class should not ordinarily be used directly.
 */
@interface UAEventData : NSManagedObject

///---------------------------------------------------------------------------------------
/// @name Event Data Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The event's session ID.
 */
@property (nullable, nonatomic, retain) NSString *sessionID;

/**
 * The event's Data.
 */
@property (nullable, nonatomic, retain) NSData *data;

/**
 * The event's creation time.
 */
@property (nullable, nonatomic, retain) NSString *time;

/**
 * The event's time.
 */
@property (nullable, nonatomic, retain) NSNumber *bytes;

/**
 * The event's type.
 */
@property (nullable, nonatomic, retain) NSString *type;

/**
 * The event's identifier.
 */
@property (nullable, nonatomic, retain) NSString *identifier;

/**
 * The event's store date.
 */
@property (nullable, nonatomic, retain) NSDate *storeDate;

@end
