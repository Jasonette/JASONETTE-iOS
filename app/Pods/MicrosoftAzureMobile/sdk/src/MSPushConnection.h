// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSBlockDefinitions.h"
#import "MSClientConnection.h"

@class MSPushConnection;
@class MSPushRequest;
@class MSClient;

// The |MSPushConnection| class is a subclass of the |MSClientConnection|
// that takes |MSTableRequest| instances and the appropriate |MS*SuccessBlock|
// instances for calling back into when the response is received.
@interface MSPushConnection : MSClientConnection

// Creates a connection for a registration request
// NOTE: The request is not sent until |start| is called.
+(MSPushConnection *) connectionWithRegistrationRequest:(MSPushRequest *)request
                                                 client:(MSClient *)client
                                             completion:(MSCompletionBlock)completion;

// Creates a connection for a unregister (delete) request.
// NOTE: The request is not sent until |start| is called.
+(MSPushConnection *) connectionWithUnregisterRequest:(MSPushRequest *)request
                                               client:(MSClient *)client
                                           completion:(MSCompletionBlock)completion;


@end
