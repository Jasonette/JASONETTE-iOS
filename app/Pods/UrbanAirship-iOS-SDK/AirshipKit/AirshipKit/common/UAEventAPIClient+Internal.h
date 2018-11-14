/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAAPIClient+Internal.h"

@class UAConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * API client to upload events to Urban Airship.
 */
@interface UAEventAPIClient : UAAPIClient

///---------------------------------------------------------------------------------------
/// @name Event API Client Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Default factory method.
 *
 * @param config The Urban Airship config.
 * @return A UAEventAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config;

/**
 * Factory method to create a UAEventAPIClient.
 *
 * @param config The Urban Airship config.
 * @param session The UARequestSession instance.
 * @return UAEventAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UAConfig *)config session:(UARequestSession *)session;

/**
 * Uploads analytic events.
 * @param events The events to upload.
 * @param completionHandler A completion handler.
 */
-(void)uploadEvents:(NSArray *)events completionHandler:(void (^)(NSHTTPURLResponse * nullable))completionHandler;

@end

NS_ASSUME_NONNULL_END
