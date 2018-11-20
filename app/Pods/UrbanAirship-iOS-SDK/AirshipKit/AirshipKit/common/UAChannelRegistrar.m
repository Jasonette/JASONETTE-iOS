/* Copyright 2017 Urban Airship and Contributors */

#import "UAChannelRegistrar+Internal.h"
#import "UAChannelAPIClient+Internal.h"
#import "UAGlobal.h"
#import "UAUtils.h"
#import "UAChannelRegistrationPayload+Internal.h"
#import "UAConfig.h"

@implementation UAChannelRegistrar

-(id)initWithConfig:(UAConfig *)config {
    self = [super init];
    if (self) {
        self.channelAPIClient = [UAChannelAPIClient clientWithConfig:config];
        self.isRegistrationInProgress = NO;
    }
    return self;
}

+ (instancetype)channelRegistrarWithConfig:(UAConfig *)config {
    return [[UAChannelRegistrar alloc] initWithConfig:config];
}

- (void)registerWithChannelID:(NSString *)channelID
              channelLocation:(NSString *)channelLocation
                  withPayload:(UAChannelRegistrationPayload *)payload
                   forcefully:(BOOL)forcefully {

    UAChannelRegistrationPayload *payloadCopy = [payload copy];

    if (self.isRegistrationInProgress) {
        UA_LDEBUG(@"Ignoring registration request, one already in progress.");
        return;
    }

    self.isRegistrationInProgress = YES;

    if (forcefully || ![payload isEqualToPayload:self.lastSuccessPayload]) {
        if (!channelID || !channelLocation) {
            [self createChannelWithPayload:payloadCopy];
        } else {
            [self updateChannel:channelID channelLocation:channelLocation withPayload:payloadCopy];
        }

    } else {
        UA_LDEBUG(@"Ignoring registration request, registration is up to date.");
        [self succeededWithPayload:payload];
    }
}

- (void)cancelAllRequests {
    [self.channelAPIClient cancelAllRequests];

    // If a registration was in progress, its undeterministic if it succeeded
    // or not, so just clear the last success payload.
    if (self.isRegistrationInProgress) {
        self.lastSuccessPayload = nil;
    }

    self.isRegistrationInProgress = NO;
}

- (void)updateChannel:(NSString *)channelID
      channelLocation:(NSString *)location
          withPayload:(UAChannelRegistrationPayload *)payload {

    UA_LDEBUG(@"Updating channel %@", channelID);


    UA_WEAKIFY(self);
    UAChannelAPIClientUpdateSuccessBlock successBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UA_STRONGIFY(self);
            [self succeededWithPayload:payload];
        });
    };

    UAChannelAPIClientFailureBlock failureBlock = ^(NSUInteger statusCode) {

        if (statusCode != 409) {
            UA_LDEBUG(@"Channel failed to update with JSON payload %@", [[NSString alloc] initWithData:[payload asJSONData] encoding:NSUTF8StringEncoding]);

            dispatch_async(dispatch_get_main_queue(), ^{
                UA_STRONGIFY(self);
                [self failedWithPayload:payload];
            });

            return;
        }

        // Conflict with channel ID, create a new one
        UAChannelAPIClientCreateSuccessBlock successBlock = ^(NSString *newChannelID, NSString *channelLocation, BOOL existing) {

            if (!channelID || !channelLocation) {
                UA_LDEBUG(@"Channel ID: %@ or channel location: %@ is missing. Channel creation failed", channelID, channelLocation);
                dispatch_async(dispatch_get_main_queue(), ^{
                    UA_STRONGIFY(self);
                    [self failedWithPayload:payload];
                });

            } else {
                UA_LDEBUG(@"Channel %@ created successfully. Channel location: %@.", newChannelID, channelLocation);
                dispatch_async(dispatch_get_main_queue(), ^{
                    UA_STRONGIFY(self);
                    [self channelCreated:newChannelID channelLocation:channelLocation existing:existing];
                    [self succeededWithPayload:payload];
                });
            }
        };

        UAChannelAPIClientFailureBlock failureBlock = ^(NSUInteger statusCode) {
            UA_LDEBUG(@"Channel failed to create with JSON payload %@", [[NSString alloc] initWithData:[payload asJSONData] encoding:NSUTF8StringEncoding]);
            dispatch_async(dispatch_get_main_queue(), ^{
                UA_STRONGIFY(self);
                [self failedWithPayload:payload];
            });
        };

        UA_STRONGIFY(self);
        UA_LDEBUG(@"Channel conflict, recreating.");
        [self.channelAPIClient createChannelWithPayload:payload
                                              onSuccess:successBlock
                                              onFailure:failureBlock];
    };

    [self.channelAPIClient updateChannelWithLocation:location
                                         withPayload:payload
                                           onSuccess:successBlock
                                           onFailure:failureBlock];
}

- (void)createChannelWithPayload:(UAChannelRegistrationPayload *)payload {

    UA_LDEBUG(@"Creating channel.");

    UA_WEAKIFY(self);

    UAChannelAPIClientCreateSuccessBlock successBlock = ^(NSString *channelID, NSString *channelLocation, BOOL existing) {
        if (!channelID || !channelLocation) {
            UA_LDEBUG(@"Channel ID: %@ or channel location: %@ is missing. Channel creation failed", channelID, channelLocation);
            dispatch_async(dispatch_get_main_queue(), ^{
                UA_STRONGIFY(self);
                [self failedWithPayload:payload];
            });
        } else {
            UA_LDEBUG(@"Channel %@ created successfully. Channel location: %@.", channelID, channelLocation);

            dispatch_async(dispatch_get_main_queue(), ^{
                UA_STRONGIFY(self);
                [self channelCreated:channelID channelLocation:channelLocation existing:existing];
                [self succeededWithPayload:payload];
            });
        }
    };

    UAChannelAPIClientFailureBlock failureBlock = ^(NSUInteger statusCode) {
        UA_LDEBUG(@"Channel creation failed.");
        dispatch_async(dispatch_get_main_queue(), ^{
            UA_STRONGIFY(self);
            [self failedWithPayload:payload];
        });
    };

    [self.channelAPIClient createChannelWithPayload:payload
                                          onSuccess:successBlock
                                          onFailure:failureBlock];
}

// Must be called on main queue
- (void)failedWithPayload:(UAChannelRegistrationPayload *)payload {
    if (!self.isRegistrationInProgress) {
        return;
    }

    self.isRegistrationInProgress = NO;

    id strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(registrationFailedWithPayload:)]) {
        [strongDelegate registrationFailedWithPayload:payload];
    }
}

// Must be called on main queue
- (void)succeededWithPayload:(UAChannelRegistrationPayload *)payload {
    if (!self.isRegistrationInProgress) {
        return;
    }

    self.lastSuccessPayload = payload;
    self.isRegistrationInProgress = NO;

    id strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(registrationSucceededWithPayload:)]) {
        [strongDelegate registrationSucceededWithPayload:payload];
    }
}

// Must be called on main queue
- (void)channelCreated:(NSString *)channelID
       channelLocation:(NSString *)channelLocation
              existing:(BOOL)existing {

    id strongDelegate = self.delegate;

    if ([strongDelegate respondsToSelector:@selector(channelCreated:channelLocation:existing:)]) {
        [strongDelegate channelCreated:channelID channelLocation:channelLocation existing:existing];
    }
}

@end
