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

// Can override the request session manager
+ (nonnull AFHTTPSessionManager *)manager;
+ (void)                          setSessionManager:(AFHTTPSessionManager *)manager;

// Can override the response serializer
+ (nonnull AFJSONResponseSerializer *)serializer;
+ (void)setResponseSerializer:(AFJSONResponseSerializer *)serializer;

// Can add additional accepted content types
+ (nonnull NSArray *)                 acceptedContentTypes;
+ (void)setAcceptedContentTypes:(nonnull NSArray<NSString *> *)types;

// Can add additional headers
+ (nonnull NSDictionary *)            headers;
+ (void)setHeaders:(nonnull NSDictionary *)headers;

@end

NS_ASSUME_NONNULL_END
