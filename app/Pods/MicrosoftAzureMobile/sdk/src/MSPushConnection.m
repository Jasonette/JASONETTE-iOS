// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSPushConnection.h"
#import "MSError.h"
#import "MSPushRequest.h"

@implementation MSPushConnection


+(MSPushConnection *) connectionWithRegistrationRequest:(MSPushRequest *)request
                                                 client:(MSClient *)client
                                             completion:(MSCompletionBlock)completion
{
    return [self connectionWithRequest:request client:client completion:completion];
}


+(MSPushConnection *) connectionWithUnregisterRequest:(MSPushRequest *)request
                                               client:(MSClient *)client
                                           completion:(MSCompletionBlock)completion
{
    return [self connectionWithRequest:request client:client completion:completion];
}

+(MSPushConnection *) connectionWithRequest:(MSPushRequest *)request
                                     client:(MSClient *)client
                                 completion:(MSCompletionBlock)completion
{
    // We'll use the connection in the response block below but won't set
    // it until the init at the end, so we need to use __block
    __block MSPushConnection *connection = nil;
    
    // Create an HTTP response block that will invoke the MSItemBlock
    MSResponseBlock responseCompletion = nil;
    
    if (completion) {
        responseCompletion = ^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            if (!error) {
                [connection isSuccessfulResponse:response
                                            data:data
                                         orError:&error];
            } else {
                [connection addRequestAndResponse:response toError:&error];
            }
            
            completion(error);
        };
    }
    
    // Now create the connection with the MSResponseBlock
    connection = [[MSPushConnection alloc] initWithPushRequest:request
                                                        client:client
                                                    completion:responseCompletion];
    
    return connection;
}

-(id) initWithPushRequest:(MSPushRequest *)request
                   client:(MSClient *)client
               completion:(MSResponseBlock)completion
{
    self = [super initWithRequest:request
                           client:client
                       completion:completion];
    return self;
}

@end
