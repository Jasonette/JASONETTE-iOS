/* Copyright 2017 Urban Airship and Contributors */
#import <Foundation/Foundation.h>
#import "UAAsyncOperation+Internal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Performs a NSURLSession dataTask in an NSOperation.
 */
@interface UAURLRequestOperation : UAAsyncOperation

/**
 * UAURLRequestOperation factory method.
 * @param request The request to perform.
 * @param session The url session to peform the request in.
 * @param completionHandler A completion handler to call once the request is finished.
 */
+ (instancetype)operationWithRequest:(NSURLRequest *)request
                             session:(NSURLSession *)session
                   completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END

