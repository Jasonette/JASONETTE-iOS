/* Copyright 2017 Urban Airship and Contributors */


#import <Foundation/Foundation.h>
#import "UAAPIClient+Internal.h"

@class UAConfig;
@class UATagGroupsMutation;

NS_ASSUME_NONNULL_BEGIN

/**
 * A high level abstraction for performing tag group operations.
 */
@interface UATagGroupsAPIClient : UAAPIClient

///---------------------------------------------------------------------------------------
/// @name Tag Groups API Client Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UATagGroupsAPIClient.
 *
 * @param config The Urban Airship config.
 * @return UATagGroupsAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config;

/**
 * Factory method to create a UATagGroupsAPIClient.
 *
 * @param config The Urban Airship config.
 * @param session The request session.
 * @return UATagGroupsAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config session:(UARequestSession *)session;

/**
 * Update the channel tag group.
 *
 * @param channelId The channel ID string.
 * @param mutation The tag groups changes.
 * @param completionHandler The completion handler with the status code.
 */
- (void)updateChannel:(NSString *)channelId
    tagGroupsMutation:(UATagGroupsMutation *)mutation
    completionHandler:(void (^)(NSUInteger status))completionHandler;

/**
 * Update the named user tags.
 *
 * @param identifier The named user ID string.
 * @param mutation The tag groups changes.
 * @param completionHandler The completion handler with the status code.
 */
- (void)updateNamedUser:(NSString *)identifier
      tagGroupsMutation:(UATagGroupsMutation *)mutation
      completionHandler:(void (^)(NSUInteger status))completionHandler;

@end

NS_ASSUME_NONNULL_END
