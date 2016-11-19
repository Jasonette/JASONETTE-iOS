// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSClientConnection.h"

@class MSAPIRequest;
@class MSClient;

#pragma  mark * MSAPIConnection Public Interface


// The |MSAPIConnection| class is a subclass of the |MSClientConnection|
// that takes |MSAPIRequest| instances and the appropriate |MS*ApiBlock|
// instances for calling back into when the response is received.
@interface MSAPIConnection : MSClientConnection


#pragma  mark * Public Static Constructor Methods


// Creates a connection for an invoke API request.
// NOTE: The request is not sent until |start| is called.
+(MSAPIConnection *)connectionWithApiDataRequest:(MSAPIRequest *)request
                                          client:(MSClient *)client
                                      completion:(MSAPIDataBlock)completion;

// Creates a connection for an invoke API request that uses JSON.
// NOTE: The request is not sent until |start| is called.
+(MSAPIConnection *)connectionWithApiRequest:(MSAPIRequest *)request
                                      client:(MSClient *)client
                                  completion:(MSAPIBlock)completion;

@end