// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@class MSClient;
@protocol MSSerializer;

#pragma mark * MSAPIRequest Public Interface


// The |MSAPIRequest| class represents a request to invoke a user-defined
// API of a Microsoft Azure Mobile Service.
@interface MSAPIRequest : NSMutableURLRequest


#pragma mark * Public Readonly Properties


// The client associated with this table.
//@property (nonatomic, strong, readonly)         MSClient *client;

// The serializer used to serialize the data for the request and/or deserialize
// the data in the respective response.
@property (nonatomic, strong, readonly)     id<MSSerializer> serializer;

// The user-defined parameters to be included in the request query string.
@property (nonatomic, strong, readonly)     NSDictionary *parameters;


#pragma  mark * Public Static Constructor Methods


// Creates a request to insert the item into the given table.
+(MSAPIRequest *) requestToinvokeAPI:(NSString *)APIName
                              client:(MSClient *)client
                                data:(NSData *)data
                          HTTPMethod:(NSString *)method
                          parameters:(NSDictionary *)parameters
                             headers:(NSDictionary *)headers
                          completion:(MSAPIDataBlock)completion;

// Creates a request to insert the item into the given table.
+(MSAPIRequest *) requestToinvokeAPI:(NSString *)APIName
                                  client:(MSClient *)client
                                    body:(id)body
                              HTTPMethod:(NSString *)method
                              parameters:(NSDictionary *)parameters
                                 headers:(NSDictionary *)headers
                              completion:(MSAPIBlock)completion;

@end
