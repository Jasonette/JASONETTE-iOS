/* Copyright 2017 Urban Airship and Contributors */

#import "UANamedUserAPIClient+Internal.h"
#import "UAConfig.h"
#import "UAUtils.h"
#import "NSJSONSerialization+UAAdditions.h"

#define kUANamedUserPath @"/api/named_users"
#define kUANamedUserChannelIDKey @"channel_id"
#define kUANamedUserDeviceTypeKey @"device_type"
#define kUANamedUserIdentifierKey @"named_user_id"

@implementation UANamedUserAPIClient

+ (instancetype)clientWithConfig:(UAConfig *)config {
    return [[self alloc] initWithConfig:config session:[UARequestSession sessionWithConfig:config]];
}

+ (instancetype)clientWithConfig:(UAConfig *)config session:(UARequestSession *)session {
    return [[self alloc] initWithConfig:config session:session];
}

- (void)associate:(NSString *)identifier
        channelID:(NSString *)channelID
        onSuccess:(UANamedUserAPIClientSuccessBlock)successBlock
        onFailure:(UANamedUserAPIClientFailureBlock)failureBlock {

    if (!identifier) {
        UA_LERR(@"The named user ID cannot be nil.");
        return;
    }

    if (!channelID) {
        UA_LERR(@"The channel ID cannot be nil.");
        return;
    }

    UA_LTRACE(@"Associating channel %@ with named user ID: %@", channelID, identifier);


    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:channelID forKey:kUANamedUserChannelIDKey];
    [payload setObject:@"ios" forKey:kUANamedUserDeviceTypeKey];
    [payload setValue:identifier forKey:kUANamedUserIdentifierKey];

    NSString *urlString = [NSString stringWithFormat:@"%@%@", self.config.deviceAPIURL, kUANamedUserPath];
    UARequest *request = [self requestWithPayload:payload
                                        urlString:[NSString stringWithFormat:@"%@%@", urlString, @"/associate"]];

    [self.session dataTaskWithRequest:request retryWhere:^BOOL(NSData * _Nullable data, NSURLResponse * _Nullable response) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }

        NSInteger status = httpResponse.statusCode;
        return (BOOL)(status >= 500 && status <= 599);
    } completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }
        NSInteger status = httpResponse.statusCode;

        // Failure
        if (!(status >= 200 && status <= 299)) {
            UA_LTRACE(@"Failed to associate named user with status: %lu", (unsigned long)status);
            failureBlock(status);
            return;
        }

        // Success
        UA_LTRACE(@"Associated named user with status: %lu", (unsigned long)status);
        successBlock();
    }];
}

- (void)disassociate:(NSString *)channelID
           onSuccess:(UANamedUserAPIClientSuccessBlock)successBlock
           onFailure:(UANamedUserAPIClientFailureBlock)failureBlock {

    if (!channelID) {
        UA_LERR(@"The channel ID cannot be nil.");
        return;
    }

    UA_LTRACE(@"Disassociating channel %@ from named user ID", channelID);

    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:channelID forKey:kUANamedUserChannelIDKey];
    [payload setObject:@"ios" forKey:kUANamedUserDeviceTypeKey];

    NSString *urlString = [NSString stringWithFormat:@"%@%@", self.config.deviceAPIURL, kUANamedUserPath];
    UARequest *request = [self requestWithPayload:payload
                                        urlString:[NSString stringWithFormat:@"%@%@", urlString, @"/disassociate"]];

    [self.session dataTaskWithRequest:request retryWhere:^BOOL(NSData * _Nullable data, NSURLResponse * _Nullable response) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }
        NSInteger status = httpResponse.statusCode;
        return (BOOL)(status >= 500 && status <= 599);


    } completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }
        NSInteger status = httpResponse.statusCode;

        // Failure
        if (!(status >= 200 && status <= 299)) {
            UA_LTRACE(@"Failed to dissociate named user with status: %lu", (unsigned long)status);
            failureBlock(status);
            return;
        }

        // Success
        UA_LTRACE(@"Dissociated named user with status: %lu", (unsigned long)status);
        successBlock();
    }];
}

- (UARequest *)requestWithPayload:(NSDictionary *)payload urlString:(NSString *)urlString {

    UARequest *request = [UARequest requestWithBuilderBlock:^(UARequestBuilder * _Nonnull builder) {
        builder.method = @"POST";
        builder.URL = [NSURL URLWithString:urlString];
        builder.username = self.config.appKey;
        builder.password = self.config.appSecret;
        [builder setValue:@"application/vnd.urbanairship+json; version=3;" forHeader:@"Accept"];
        [builder setValue:@"application/json" forHeader:@"Content-Type"];
        builder.body = [NSJSONSerialization dataWithJSONObject:payload
                                                       options:0
                                                         error:nil];
    }];

    return request;
}

@end
