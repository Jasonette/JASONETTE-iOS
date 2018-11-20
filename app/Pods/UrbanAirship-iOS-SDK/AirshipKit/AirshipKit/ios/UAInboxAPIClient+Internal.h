/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAAPIClient+Internal.h"

@class UAUser;
@class UAConfig;
@class UAPreferenceDataStore;

NS_ASSUME_NONNULL_BEGIN

#define kUAChannelIDHeader @"X-UA-Channel-ID"

/**
 * A block called when the inbox message retrieval succeeded.
 *
 * @param status The request status.
 * @param messages The retrieved messages.
 */
typedef void (^UAInboxClientMessageRetrievalSuccessBlock)(NSUInteger status,  NSArray * __nullable messages);

/**
 * A block called when the channel update succeeded.
 */
typedef void (^UAInboxClientSuccessBlock)(void);

/**
 * A block called when the channel creation or update failed.
 */
typedef void (^UAInboxClientFailureBlock)(void);

/**
 * A high level abstraction for performing Rich Push API requests.
 */
@interface UAInboxAPIClient : UAAPIClient

///---------------------------------------------------------------------------------------
/// @name Inbox API Client Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method for client.
 * @param config The Urban Airship config.
 * @param session The request session.
 * @param user The inbox user.
 * @param dataStore The preference data store.
 * @return UAInboxAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config
                         session:(UARequestSession *)session
                            user:(UAUser *)user
                       dataStore:(UAPreferenceDataStore *)dataStore;


/**
 * Retrieves the full message list from the server.
 *
 * @param successBlock A block to be executed when the call completes successfully.
 * @param failureBlock A block to be executed if the call fails.
 */
- (void)retrieveMessageListOnSuccess:(UAInboxClientMessageRetrievalSuccessBlock)successBlock
                           onFailure:(UAInboxClientFailureBlock)failureBlock;

/**
 * Performs a batch delete request on the server.
 *
 * @param messageURLs An NSArray of message URLs to be deleted.
 * @param successBlock A block to be executed when the call completes successfully.
 * @param failureBlock A block to be executed if the call fails.
 */

- (void)performBatchDeleteForMessageURLs:(NSArray<NSURL *> *)messageURLs
                            onSuccess:(UAInboxClientSuccessBlock)successBlock
                            onFailure:(UAInboxClientFailureBlock)failureBlock;

/**
 * Performs a batch mark-as-read request on the server.
 *
 * @param messageURLs An NSArray of message URLs to be marked as read.
 * @param successBlock A block to be executed when the call completes successfully.
 * @param failureBlock A block to be executed if the call fails.
 */

- (void)performBatchMarkAsReadForMessageURLs:(NSArray<NSURL *> *)messageURLs
                                   onSuccess:(UAInboxClientSuccessBlock)successBlock
                                   onFailure:(UAInboxClientFailureBlock)failureBlock;

/**
 * Clears the last modified time for message list requests.
 */
- (void)clearLastModifiedTime;

@end

NS_ASSUME_NONNULL_END
