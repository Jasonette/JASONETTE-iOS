// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSPush.h"
#import "MSClientInternal.h"
#import "MSPushRequest.h"
#import "MSPushConnection.h"

#pragma mark * MSPush Implementation

@implementation MSPush

#pragma  mark * Public Initializer Methods

- (MSPush *)initWithClient:(MSClient *)client
{
    self = [super init];
    
    if (self) {
        _client = client;
    }
    
    return self;
}

- (NSString *)installationId
{
    return self.client.installId;
}

#pragma mark * Registration Methods
- (void) registerDeviceToken:(NSData *)deviceToken completion:(MSCompletionBlock)completion
{
    [self registerDeviceToken:deviceToken template:nil completion:completion];
}

- (void) registerDeviceToken:(NSData *)deviceToken template:(NSDictionary *)template completion:(MSCompletionBlock)completion
{
    // Verify the device token is present
    if (!deviceToken) {
        if (completion) {
            completion([self errorForMissingParameterWithParameterName:@"deviceToken"]);
        }
        
        return;
    }

    // Create the request
    MSPushRequest *request = [MSPushRequest requestToRegisterDeviceToken:deviceToken
                                                                    push:self
                                                               templates:template
                                                              completion:completion];
    // Send the request
    if (request) {
        MSPushConnection *connection = [MSPushConnection connectionWithRegistrationRequest:request
                                                                                    client:self.client
                                                                                completion:completion];
        [connection start];
    }
}

- (void) unregisterWithCompletion:(MSCompletionBlock)completion
{
    // Create the request
    MSPushRequest *request = [MSPushRequest requestToUnregisterPush:self
                                                         completion:completion];
    // Send the request
    if (request) {
        MSPushConnection *connection = [MSPushConnection connectionWithUnregisterRequest:request
                                                                                  client:self.client
                                                                              completion:completion];
        [connection start];
    }
    
}

#pragma  mark * Private Methods

-(NSError *) errorForMissingParameterWithParameterName:(NSString *)parameterName
{
    NSString *descriptionKey = @"'%@' is a required parameter.";
    NSString *descriptionFormat = NSLocalizedString(descriptionKey, nil);
    NSString *description = [NSString stringWithFormat:descriptionFormat, parameterName];
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey :description };
    
    return [NSError errorWithDomain:MSErrorDomain
                               code:MSPushRequiredParameter
                           userInfo:userInfo];
}

@end