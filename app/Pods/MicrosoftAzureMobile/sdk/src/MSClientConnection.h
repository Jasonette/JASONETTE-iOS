// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"
#import "MSSDKFeatures.h"

@class MSClient;

#pragma mark * MSClientConnection Public Interface


// The |MSClientConnection| class sends an HTTP request asynchronously and
// returns either the response and response data or an error via block
// callbacks.
@interface MSClientConnection : NSObject


#pragma mark * Public Readonly Properties


// The client that created the connection
@property (nonatomic, strong, readonly)     MSClient *client;

// The request used with the connection
@property (nonatomic, strong, readonly)     NSURLRequest *request;

// The callback to use with the response
@property (nonatomic, copy, readonly)       MSResponseBlock completion;


#pragma  mark * Public Initializer Methods


// Initializes an |MSClientConnection| with the given client that sends the given
// request. NOTE: The request is not sent until |start| is called.
-(id)initWithRequest:(NSURLRequest *)request
              client:(MSClient *)client
          completion:(MSResponseBlock)completion;

// Initializes an |MSClientConnection| with the given client that sends the given
// request using certain MSFeatures.
-(id)initWithRequest:(NSURLRequest *)request
              client:(MSClient *)client
            features:(MSFeatures)features
          completion:(MSResponseBlock)completion;


#pragma mark * Public Start Methods


// Sends the request.
-(void) start;

// Sends the request without using the client's filters
-(void) startWithoutFilters;


#pragma mark * Public Response Handling Methods


// Determines is a response was successful or not based on the HTTP
// status code.  If not successful, an error is provided.
-(BOOL) isSuccessfulResponse:(NSHTTPURLResponse *)response
                        data:(NSData *)data
                     orError:(NSError **)error;

// Reads the content of the response using the client's serializer. Returns
// and error if there is a failure during deserialization of the content.
-(id) itemFromData:(NSData *)data
            response:(NSHTTPURLResponse *)response
            ensureDictionary:(BOOL)ensureDictionary
            orError:(NSError **)error;

// Given an error, adds the connection's request and the optional response
// to the error.
-(void) addRequestAndResponse:(NSHTTPURLResponse *)response
                      toError:(NSError **)error;

@end
