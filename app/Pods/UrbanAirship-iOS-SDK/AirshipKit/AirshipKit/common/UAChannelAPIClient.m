/* Copyright 2017 Urban Airship and Contributors */

#import "UAChannelAPIClient+Internal.h"
#import "UAChannelRegistrationPayload+Internal.h"
#import "UAConfig.h"
#import "UAUtils.h"
#import "UAirship.h"
#import "UAAnalytics+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"

#define kUAChannelCreateLocation @"/api/channels/"

@implementation UAChannelAPIClient

+ (instancetype)clientWithConfig:(UAConfig *)config {
    return [UAChannelAPIClient clientWithConfig:config session:[UARequestSession sessionWithConfig:config]];
}

+ (instancetype)clientWithConfig:(UAConfig *)config session:(UARequestSession *)session {
    return [[UAChannelAPIClient alloc] initWithConfig:config session:session];
}

- (void)createChannelWithPayload:(UAChannelRegistrationPayload *)payload
                      onSuccess:(UAChannelAPIClientCreateSuccessBlock)successBlock
                      onFailure:(UAChannelAPIClientFailureBlock)failureBlock {

    UA_LTRACE(@"Creating channel with: %@.", payload);

    UARequest *request = [UARequest requestWithBuilderBlock:^(UARequestBuilder *builder) {
        NSString *urlString = [NSString stringWithFormat:@"%@%@", self.config.deviceAPIURL, kUAChannelCreateLocation];
        builder.URL = [NSURL URLWithString:urlString];
        builder.method = @"POST";
        builder.username = self.config.appKey;
        builder.password = self.config.appSecret;
        builder.body = [payload asJSONData];
        [builder setValue:@"application/vnd.urbanairship+json; version=3;" forHeader:@"Accept"];
        [builder setValue:@"application/json" forHeader:@"Content-Type"];
    }];

    [self.session dataTaskWithRequest:request retryWhere:^BOOL(NSData *data, NSURLResponse *response) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }

        if (httpResponse.statusCode >= 500 && httpResponse.statusCode <= 599) {
            return YES;
        }

        return NO;
    } completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }

        // Failure
        if (httpResponse.statusCode != 200 && httpResponse.statusCode != 201) {
            UA_LTRACE(@"Channel creation failed with status: %ld error: %@", (unsigned long)httpResponse.statusCode, error);
            failureBlock(httpResponse.statusCode);
            return;
        }

        // Success
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

        UA_LTRACE(@"Channel creation succeeded with status: %ld jsonResponse: %@", (unsigned long)httpResponse.statusCode, jsonResponse);

        // Parse the response
        NSString *channelID = [jsonResponse valueForKey:@"channel_id"];
        NSString *channelLocation = [httpResponse.allHeaderFields valueForKey:@"Location"];
        BOOL existing = httpResponse.statusCode == 200;

        successBlock(channelID, channelLocation, existing);
    }];
}

- (void)updateChannelWithLocation:(NSString *)channelLocation
                      withPayload:(UAChannelRegistrationPayload *)payload
                        onSuccess:(UAChannelAPIClientUpdateSuccessBlock)successBlock
                        onFailure:(UAChannelAPIClientFailureBlock)failureBlock {

    UA_LTRACE(@"Updating channel with: %@.", payload);

    UARequest *request = [UARequest requestWithBuilderBlock:^(UARequestBuilder *builder) {
        builder.URL = [NSURL URLWithString:channelLocation];
        builder.method = @"PUT";
        builder.username = self.config.appKey;
        builder.password = self.config.appSecret;
        builder.body = [payload asJSONData];
        [builder setValue:@"application/vnd.urbanairship+json; version=3;" forHeader:@"Accept"];
        [builder setValue:@"application/json" forHeader:@"Content-Type"];
    }];

    [self.session dataTaskWithRequest:request retryWhere:^BOOL(NSData *data, NSURLResponse *response) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }

        if (httpResponse.statusCode >= 500 && httpResponse.statusCode <= 599) {
            return YES;
        }

        return NO;
    } completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }

        // Failure
        if (httpResponse.statusCode != 200 && httpResponse.statusCode != 201) {
            UA_LTRACE(@"Channel update failed with status: %ld error: %@", (unsigned long)httpResponse.statusCode, error);
            failureBlock(httpResponse.statusCode);
            return;
        }

        // Success
        UA_LTRACE(@"Channel update succeeded with status: %ld", (unsigned long)httpResponse.statusCode);
        successBlock();
    }];
}


@end
