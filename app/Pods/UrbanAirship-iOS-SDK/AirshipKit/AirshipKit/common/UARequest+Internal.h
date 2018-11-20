/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UADisposable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The request builder.
 */
@interface UARequestBuilder : NSObject

/**
 * The HTTP method.
 */
@property (nonatomic, copy) NSString *method;

/**
 * The request URL.
 */
@property (nonatomic, strong) NSURL *URL;

/**
 * The user name for basic authorization.
 */
@property (nonatomic, copy, nullable) NSString *username;

/**
 * The user password for basic authorization.
 */
@property (nonatomic, copy, nullable) NSString *password;

/**
 * The request body.
 */
@property (nonatomic, copy, nullable) NSData *body;

/**
 * Flag to compress the request body using GZIP or not.
 */
@property (nonatomic, assign) BOOL compressBody;

/**
 * Sets a http request header.
 * @param value The header value.
 * @param header The header name.
 */
- (void)setValue:(id)value forHeader:(NSString *)header;

@end

/**
 * Defines a network request.
 */
@interface UARequest : NSObject

/**
 * The HTTP method.
 */
@property (nonatomic, readonly, nullable) NSString *method;

/**
 * The request URL.
 */
@property (nonatomic, readonly, nullable) NSURL *URL;

/**
 * The request headers.
 */
@property (nonatomic, readonly) NSDictionary *headers;

/**
 * The request body.
 */
@property (nonatomic, readonly, nullable) NSData *body;

/**
 * Factory method to create a request.
 * @param builderBlock A block with a request builder to customize the UARequest instance.
 * @return A UARequest instance.
 */
+ (instancetype)requestWithBuilderBlock:(void(^)(UARequestBuilder *builder))builderBlock;

@end

NS_ASSUME_NONNULL_END
