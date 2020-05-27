//
//  JasonNetworking.h
//  Jasonette
//
//  Created by Jasonelle Team on 05-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface JasonNetworking : NSObject


/**
 * Custom Session manager
 *
 * @return AFHTTPSessionManager
 */
+ (nonnull AFHTTPSessionManager *)manager;
+ (void)                          setSessionManager:(AFHTTPSessionManager *)manager;


/**
 * Custom Response Serializer
 *
 * @return AFJSONResponseSerializer
 */
+ (nonnull AFJSONResponseSerializer *)serializer;
+ (void)setResponseSerializer:(AFJSONResponseSerializer *)serializer;



/**
 * Retrieves the accepted content types for the response
 *
 * @return NSArray of content types
 */
+ (nonnull NSArray *)                 acceptedContentTypes;

/**
 * Add additional accepted content types for the response
 *
 * @return NSArray with content types
 */
+ (void)setAcceptedContentTypes:(nonnull NSArray<NSString *> *)types;


/**
 * Retrieves the headers for the request
 *
 * @return NSDictionary with headers
 */
+ (nonnull NSDictionary *)            headers;


/**
 * Set the headers for the request
 *
 * @param headers
 */
+ (void)setHeaders:(nonnull NSDictionary *)headers;

@end

NS_ASSUME_NONNULL_END
