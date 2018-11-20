/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CoreData class representing the backing data for
 * a UAInboxMessage.
 *
 * This classs should not ordinarily be used directly.
 */
@interface UAInboxMessageData : NSManagedObject

///---------------------------------------------------------------------------------------
/// @name Message Internal Properties
///---------------------------------------------------------------------------------------

/**
 * The Urban Airship message ID.
 * This ID may be used to match an incoming push notification to a specific message.
 */
@property (nonatomic, copy) NSString *messageID;

/**
 * The URL for the message body itself.
 * This URL may only be accessed with Basic Auth credentials set to the user ID and password.
 */
@property (nonatomic, strong) NSURL *messageBodyURL;

/** The URL for the message.
 * This URL may only be accessed with Basic Auth credentials set to the user ID and password.
 */
@property (nonatomic, strong) NSURL *messageURL;

/** The MIME content type for the message (e.g., text/html) */
@property (nonatomic, copy) NSString *contentType;

/** YES if the message is unread, otherwise NO. */
@property (nonatomic, assign) BOOL unread;

/** YES if the message is unread on the client, otherwise NO. */
@property (assign) BOOL unreadClient;

/** YES if the message is deleted, otherwise NO. */
@property (assign) BOOL deletedClient;

/** The date and time the message was sent (UTC) */
@property (nonatomic, strong) NSDate *messageSent;

/**
 * The date and time the message will expire. 
 *
 * A nil value indicates it will never expire.
 */
@property (nonatomic, strong, nullable) NSDate *messageExpiration;

/** The message title */
@property (nonatomic, copy) NSString *title;

/**
 * The message's extra dictionary. This dictionary can be populated
 * with arbitrary key-value data at the time the message is composed.
 */
@property (nonatomic, strong) NSDictionary *extra;

/** 
 * The raw message dictionary. This is the dictionary that
 * originally created the message.  It can contain more values
 * then the message.
 */
@property (nonatomic, strong) NSDictionary *rawMessageObject;

/**
 * Indicates whether the message has been deleted from the backing store.
 *
 * Note: this method is more reliable for our purposes than the inherited
 * isInserted and isDeleted methods, which both return NO after and insertion
 * or deletion has been commited to disk once the context is saved.
 */
@property (nonatomic, readonly) BOOL isGone;

@end

NS_ASSUME_NONNULL_END
