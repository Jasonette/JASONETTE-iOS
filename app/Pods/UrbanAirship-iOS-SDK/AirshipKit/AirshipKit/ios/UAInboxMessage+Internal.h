/* Copyright 2017 Urban Airship and Contributors */

#import "UAInboxMessage.h"
#import "UAInboxAPIClient+Internal.h"
#import "UAInboxMessageData+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface UAInboxMessageBuilder : NSObject

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

/**
 * The URL for the message.
 * This URL may only be accessed with Basic Auth credentials set to the user ID and password.
 */
@property (nonatomic, strong) NSURL *messageURL;

/**
 * The MIME content type for the message (e.g., text/html).
 */
@property (nonatomic, copy) NSString *contentType;

/**
 * YES if the message is unread, otherwise NO.
 */
@property (nonatomic, assign) BOOL unread;

/**
 * YES if the message is deleted, otherwise NO.
 */
@property (nonatomic, assign) BOOL deleted;

/**
 * The date and time the message was sent (UTC).
 */
@property (nonatomic, strong) NSDate *messageSent;

/**
 * The date and time the message will expire.
 *
 * A nil value indicates it will never expire.
 */
@property (nonatomic, strong, nullable) NSDate *messageExpiration;

/**
 * The message title.
 */
@property (nonatomic, copy) NSString *title;

/**
 * The message's extra dictionary. This dictionary can be populated
 * with arbitrary key-value data at the time the message is composed.
 */
@property (nonatomic, copy) NSDictionary *extra;

/**
 * The raw message dictionary. This is the dictionary that
 * originally created the message.  It can contain more values
 * then the message.
 */
@property (nonatomic, copy) NSDictionary *rawMessageObject;

/**
 * The message list instance.
 */
@property (nonatomic, weak) UAInboxMessageList *messageList;

@end


/*
 * SDK-private extensions to UAInboxMessage
 */
@interface UAInboxMessage ()

@property (nonatomic, assign) BOOL unread;


///---------------------------------------------------------------------------------------
/// @name Message Internal Methods
///---------------------------------------------------------------------------------------


/**
 * Creates an inbox message with a builder block.
 *
 * @param builderBlock The builder block.
 * @return An inbox message.
 */
+ (instancetype)messageWithBuilderBlock:(void (^)(UAInboxMessageBuilder *))builderBlock;

@end

NS_ASSUME_NONNULL_END
