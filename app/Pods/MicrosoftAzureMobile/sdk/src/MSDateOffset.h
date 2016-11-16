// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

/**
 The MSDateOffset class is used to represent an NSDate that is stored as a DateTimeOffset in the 
 Mobile App. This class is used when building NSPredicates for an MSQuery to be ran against
 the server.
*/
@interface MSDateOffset : NSObject

/** @name Properties */

/** The date represented by tne MSDateOffset instance. */
@property (nonatomic, strong, nonnull) NSDate *date;

/** @name Initializing the MSDateOffset Object */

/**
 Initializes an MSDateOffset instance with the given date.
 
 @param date The NSDate being represented
 @returns a new instance of the MSDateOffset class
 */
-(nonnull instancetype)initWithDate:(nonnull NSDate *)date;

/**
 Creates an *MSDateOffset* instance with the given date.

 @param date The NSDate being represented
 @returns a new instance of the MSDateOffset class
 */
+(nonnull instancetype)offsetFromDate:(nonnull NSDate *)date;

@end
