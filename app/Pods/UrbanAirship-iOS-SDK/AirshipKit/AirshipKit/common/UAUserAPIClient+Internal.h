/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAAPIClient+Internal.h"

@class UAUser;
@class UAConfig;
@class UAUserData;

NS_ASSUME_NONNULL_BEGIN

/**
 * A block called when user creation succeeded.
 *
 * @param data The user data.
 * @param payload The request payload.
 */
typedef void (^UAUserAPIClientCreateSuccessBlock)(UAUserData *data, NSDictionary *payload);

/**
 * A block called when the user update succeeded.
 */
typedef void (^UAUserAPIClientUpdateSuccessBlock)(void);

/**
 * A block called when the user update failed.
 *
 * @param statusCode The request status code.
 */
typedef void (^UAUserAPIClientFailureBlock)(NSUInteger statusCode);

/**
 * High level abstraction for the User API.
 */
@interface UAUserAPIClient : UAAPIClient

///---------------------------------------------------------------------------------------
/// @name User API Client Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAUserAPIClient.
 * @param config The Urban Airship config.
 * @return UAUserAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config;

/**
 * Factory method to create a UAUserAPIClient.
 * @param config The Urban Airship config.
 * @param session The request session.
 * @return UAUserAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config session:(UARequestSession *)session;

/**
 * Create a user.
 * 
 * @param channelID The user's channel ID.
 * @param successBlock A UAUserAPIClientCreateSuccessBlock that will be called if user creation was successful.
 * @param failureBlock A UAUserAPIClientFailureBlock that will be called if user creation was unsuccessful.
 */
- (void)createUserWithChannelID:(NSString *)channelID
                      onSuccess:(UAUserAPIClientCreateSuccessBlock)successBlock
                      onFailure:(UAUserAPIClientFailureBlock)failureBlock;

/**
 * Update a user.
 *
 * @param user The specified user to update.
 * @param channelID The user's channel ID.
 * @param successBlock A UAUserAPIClientUpdateSuccessBlock that will be called if the update was successful.
 * @param failureBlock A UAUserAPIClientFailureBlock that will be called if the update was unsuccessful.
 */
- (void)updateUser:(UAUser *)user
         channelID:(NSString *)channelID
         onSuccess:(UAUserAPIClientUpdateSuccessBlock)successBlock
         onFailure:(UAUserAPIClientFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
