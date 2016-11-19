// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSAPIConnection.h"
#import "MSAPIRequest.h"

#pragma mark * MSAPIConnection Private Interface


@interface MSAPIConnection ()

// Private properties
@property (nonatomic, strong, readwrite)        id<MSSerializer> serializer;

@end


#pragma mark * MSAPIConnection Implementation


@implementation MSAPIConnection

@synthesize serializer = serializer_;


#pragma mark * Public Static Constructors


+(MSAPIConnection *)connectionWithApiDataRequest:(MSAPIRequest *)request
                                          client:(MSClient *)client
                                      completion:(MSAPIDataBlock)completion
{
    // We'll use the conection in the response block below but won't set
    // it until the init at the end, so we need to use __block
    __block MSAPIConnection *connection = nil;
    
    // Create an HTTP response block that will invoke the MSItemBlock
    MSResponseBlock responseCompletion = nil;
    
    if (completion) {
        
        responseCompletion =
        ^(NSHTTPURLResponse *response, NSData *data, NSError *error)
        {
            if (!error) {
                [connection isSuccessfulResponse:response
                                            data:data
                                         orError:&error];
            }
            
            if (error) {
                [connection addRequestAndResponse:response toError:&error];
                data = nil;
                response = nil;
            }
            
            completion(data, response, error);
        };
    }
    
    // Now create the connection with the MSResponseBlock
     connection = [[MSAPIConnection alloc] initWithApiRequest:request
                                                       client:client 
                                                   completion:responseCompletion];
    return connection;
}

+(MSAPIConnection *)connectionWithApiRequest:(MSAPIRequest *)request
                                      client:(MSClient *)client
                                  completion:(MSAPIBlock)completion
{
    // We'll use the conection in the response block below but won't set
    // it until the init at the end, so we need to use __block
    __block MSAPIConnection *connection = nil;
    
    // Create an HTTP response block that will invoke the MSItemBlock
    MSResponseBlock responseCompletion = nil;
    
    if (completion) {
        
        responseCompletion =
        ^(NSHTTPURLResponse *response, NSData *data, NSError *error)
        {
            id item = nil;
            
            if (!error) {
                
                [connection isSuccessfulResponse:response
                                            data:data
                                         orError:&error];
                if (!error && data)
                {
                    item = [connection itemFromData:data
                                           response:response
                                   ensureDictionary:NO
                                            orError:&error];
                }
            }
            
            [connection addRequestAndResponse:response toError:&error];
            completion(item, response, error);
            connection = nil;
        };
    }
    
    // Now create the connection with the MSResponseBlock
    connection = [[MSAPIConnection alloc] initWithApiRequest:request
                                                      client:client 
                                                  completion:responseCompletion];
    return connection;
}


# pragma mark * Private Init Methods


-(id) initWithApiRequest:(MSAPIRequest *)request
                  client:(MSClient *)client
              completion:(MSResponseBlock)completion
{
    self = [super initWithRequest:request
                           client:client
                       completion:completion];
    return self;
}

@end