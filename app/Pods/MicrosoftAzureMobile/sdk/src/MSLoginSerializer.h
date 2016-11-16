// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class MSUser;

#pragma mark * MSLoginSerializer Public Interface


// The |MSLoginSerializer| is used for serializing authentication tokens and
// deserializing |MSUser| instances for login sceanarios.
@interface MSLoginSerializer : NSObject


#pragma mark * Static Singleton Constructor


// A singleton instance of the MSLoginSerializer.
+(MSLoginSerializer *)loginSerializer;


#pragma mark * Serialization Methods


// Called to serialize an authentication token. May return nil if there was an
// error, in which case |error| will be set to a non-nil value.
-(NSData *)dataFromToken:(id)token orError:(NSError **)error;


#pragma mark * Deserialization Methods


// Called to deserialize an |MSUser| instance. May return nil if there was an
// error, in which case |error| will be set to a non-nil value.
-(MSUser *)userFromData:(NSData *)data orError:(NSError **)error;

@end
