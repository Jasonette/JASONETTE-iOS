/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAAPIClient+Internal.h"

@class UAConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * A block called when named user association or disassociation succeeded.
 */
typedef void (^UANamedUserAPIClientSuccessBlock)(void);

/**
 * A block called when named user association or disassociation failed.
 *
 * @param status The failed request status.
 */
typedef void (^UANamedUserAPIClientFailureBlock)(NSUInteger status);

/**
 * A high level abstraction for performing Named User API association and disassociation.
 */
@interface UANamedUserAPIClient : UAAPIClient

///---------------------------------------------------------------------------------------
/// @name Named User Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UANamedUserAPIClient.
 * @param config the Urban Airship config.
 * @return UANamedUserAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config;

/**
 * Factory method to create a UANamedUserAPIClient.
 * @param config the Urban Airship config.
 * @param session the request session.
 * @return UANamedUserAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config session:(UARequestSession *)session;

/**
 * Associates the channel to the named user ID.
 *
 * @param identifier The named user ID string.
 * @param channelID The channel ID string.
 * @param successBlock A UANamedUserAPIClientCreateSuccessBlock that will be
 *        called if the named user ID was associated successfully.
 * @param failureBlock A UANamedUserAPIClientFailureBlock that will be called
 *        if the named user ID association was unsuccessful.
 */
- (void)associate:(NSString *)identifier
        channelID:(NSString *)channelID
        onSuccess:(UANamedUserAPIClientSuccessBlock)successBlock
        onFailure:(UANamedUserAPIClientFailureBlock)failureBlock;

/**
 * Disassociate the channel from the named user ID.
 *
 * @param channelID The channel ID string.
 * @param successBlock A UANamedUserAPIClientCreateSuccessBlock that will be
 *        called if the named user ID was disassociated successfully.
 * @param failureBlock A UANamedUserAPIClientFailureBlock that will be called
 *        if the named user ID disassociation was unsuccessful.
 */
- (void)disassociate:(NSString *)channelID
           onSuccess:(UANamedUserAPIClientSuccessBlock)successBlock
           onFailure:(UANamedUserAPIClientFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
