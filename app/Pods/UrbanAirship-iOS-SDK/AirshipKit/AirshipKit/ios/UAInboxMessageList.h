/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

#import "UAUser.h"
#import "UADisposable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A completion block for message list operations.
 */
typedef void (^UAInboxMessageListCallbackBlock)(void);

/**
 * NSNotification posted when the message list is about to update.
 *
 * Note: this notification is posted regardless of the type of update (retrieval, batch).
 */
extern NSString * const UAInboxMessageListWillUpdateNotification;

/**
 * NSNotification posted when the message list is finished updating.
 *
 * Note: this notification is posted regardless of the type of update (retrieval, batch)
 * and regardless of the success/failure of the underlying operation.
 */
extern NSString * const UAInboxMessageListUpdatedNotification;

@class UAInboxMessage;

/**
 * The primary interface to the contents of the inbox.
 * Use this class to asychronously retrieve messges from the server,
 * delete or mark messages as read, retrieve individual messages from the
 * list.
 */
@interface UAInboxMessageList : NSObject

///---------------------------------------------------------------------------------------
/// @name Message List Properties
///---------------------------------------------------------------------------------------

/**
 * The list of messages stored locally as an NSArray.
 */
@property (nonatomic, readonly, strong) NSArray<UAInboxMessage *> *messages;

/**
 * The number of messages that are currently unread or -1
 * if the message list is not loaded.
 */
@property (assign) NSInteger unreadCount;

/**
 * YES if retrieving message list is currently in progress.
 * NO otherwise.
 */
@property (readonly) BOOL isRetrieving;

/**
 * YES if message batching is currently in progress.
 * NO otherwise.
 */
@property (readonly) BOOL isBatchUpdating;


///---------------------------------------------------------------------------------------
/// @name Message List Retrieval
///---------------------------------------------------------------------------------------

/**
 * Fetch new messages from the server. If the associated user has not yet
 * been created, this will be a no-op.
 *
 * @param successBlock A block to be executed if message retrieval succeeds.
 * @param failureBlock A block to be executed if message retrieval fails.
 * @return A UADisposable token which can be used to cancel callback execution.
 * This value will be nil if the associated user has not yet been created.
 */
- (nullable UADisposable *)retrieveMessageListWithSuccessBlock:(nullable UAInboxMessageListCallbackBlock)successBlock
                                              withFailureBlock:(nullable UAInboxMessageListCallbackBlock)failureBlock;

///---------------------------------------------------------------------------------------
/// @name Message Management
///---------------------------------------------------------------------------------------

/**
 * Marks messages read. They will be marked locally as read and synced with
 * Urban Airship on the next message retrieval.
 *
 * @param messages The array of messages to be marked read.
 * @param completionHandler An optional completion handler.
 * @return A UADisposable token which can be used to cancel callback execution,
 * or nil if the array of messages to mark read is empty.
 */
- (nullable UADisposable *)markMessagesRead:(NSArray *)messages
                          completionHandler:(nullable UAInboxMessageListCallbackBlock)completionHandler;

/**
 * Marks messages deleted. They will be marked locally as deleted and synced with
 * Urban Airship on the next message retrieval.
 *
 * @param messages The array of messages to be marked deleted.
 * @param completionHandler An optional completion handler.
 * @return A UADisposable token which can be used to cancel callback execution,
 * or nil if the array of messages to mark deleted is empty.
 */
- (nullable UADisposable *)markMessagesDeleted:(NSArray *)messages
                             completionHandler:(nullable UAInboxMessageListCallbackBlock)completionHandler;

/**
 * Returns the list of messages stored locally as an NSArray, filtered by the supplied predicate.
 *
 * @param predicate The predicate to use as a filter over messages.
 */
- (NSArray<UAInboxMessage *> *)messagesFilteredUsingPredicate:(NSPredicate *)predicate;

/**
 * Returns the number of messages currently in the inbox.
 *
 * @return The message count as an integer.
 */
- (NSUInteger)messageCount;

/**
 * Returns the message associated with a particular URL.
 * @param url The URL of the message
 * @return The associated UAInboxMessage object or nil if a message was
 * unable to be found.
 */
- (nullable UAInboxMessage *)messageForBodyURL:(NSURL *)url;

/**
 * Returns the message associated with a particular ID.
 * @param messageID The message ID as an NSString.
 * @return The associated UAInboxMessage object or nil if a message was
 * unable to be found.
 */
- (nullable UAInboxMessage *)messageForID:(NSString *)messageID;


@end

NS_ASSUME_NONNULL_END
