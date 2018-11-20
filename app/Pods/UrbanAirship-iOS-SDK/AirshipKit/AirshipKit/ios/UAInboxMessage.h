/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UADisposable.h"


@class UAInboxMessageList;
@class UAInboxMessage;

NS_ASSUME_NONNULL_BEGIN

typedef void (^UAInboxMessageCallbackBlock)(UAInboxMessage *message);

/**
 * This class represents a Rich Push Inbox message. It contains all
 * the available information about a message, including the URLs where
 * the message can be retrieved.
 */
@interface UAInboxMessage : NSObject

///---------------------------------------------------------------------------------------
/// @name Message Properties
///---------------------------------------------------------------------------------------

/**
 * The Urban Airship message ID.
 * This ID may be used to match an incoming push notification to a specific message.
 */
@property (nonatomic, readonly) NSString *messageID;

/**
 * The URL for the message body itself.
 * This URL may only be accessed with Basic Auth credentials set to the user ID and password.
 */
@property (nonatomic, readonly) NSURL *messageBodyURL;

/**
 * The URL for the message.
 * This URL may only be accessed with Basic Auth credentials set to the user ID and password.
 */
@property (nonatomic, readonly) NSURL *messageURL;

/**
 * The MIME content type for the message (e.g., text/html).
 */
@property (nonatomic, readonly) NSString *contentType;

/**
 * YES if the message is unread, otherwise NO.
 */
@property (nonatomic, readonly) BOOL unread;

/**
 * YES if the message is deleted, otherwise NO.
 */
@property (nonatomic, readonly) BOOL deleted;

/**
 * The date and time the message was sent (UTC).
 */
@property (nonatomic, readonly) NSDate *messageSent;

/**
 * The date and time the message will expire.
 *
 * A nil value indicates it will never expire.
 */
@property (nonatomic, readonly, nullable) NSDate *messageExpiration;

/**
 * The message title.
 */
@property (nonatomic, readonly) NSString *title;

/**
 * The message's extra dictionary. This dictionary can be populated
 * with arbitrary key-value data at the time the message is composed.
 */
@property (nonatomic, readonly) NSDictionary *extra;

/**
 * The raw message dictionary. This is the dictionary that
 * originally created the message.  It can contain more values
 * then the message.
 */
@property (nonatomic, readonly) NSDictionary *rawMessageObject;

/**
 * The parent inbox.
 *
 * Note that this object is not retained by the message.
 */
@property (nonatomic, readonly, weak) UAInboxMessageList *messageList;



///---------------------------------------------------------------------------------------
/// @name Message Management
///---------------------------------------------------------------------------------------

/**
 * Mark the message as read.
 *
 * @param completionHandler A block to be executed on completion.
 * @return A UADisposable which can be used to cancel callback execution, or nil
 * if the message is already marked read.
 */
- (nullable UADisposable *)markMessageReadWithCompletionHandler:(nullable UAInboxMessageCallbackBlock)completionHandler;

/**
 * YES if the message is expired, NO otherwise
 */
- (BOOL)isExpired;

@end

NS_ASSUME_NONNULL_END
