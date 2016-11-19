// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSClientConnection.h"
#import "MSBlockDefinitions.h"

@class MSTable;
@class MSTableItemRequest;
@class MSTableDeleteRequest;
@class MSTableReadQueryRequest;

#pragma  mark * MSTableConnection Public Interface


// The |MSTableConnection| class is a subclass of the |MSClientConnection|
// that takes |MSTableRequest| instances and the appropriate |MS*SuccessBlock|
// instances for calling back into when the response is received.
@interface MSTableConnection : MSClientConnection


#pragma mark * Public Readonly Properties


// The table associated with the connection.
@property (nonatomic, strong, readonly)     MSTable *table;


#pragma  mark * Public Static Constructor Methods


// Creates a connection for an update, insert, or readWithId request.
// NOTE: The request is not sent until |start| is called.
+(MSTableConnection *)connectionWithItemRequest:(MSTableItemRequest *)request
                                     completion:(MSItemBlock)completion;

// Creates a connection for a delete request. NOTE: The request is not sent
// until |start| is called.
+(MSTableConnection *)connectionWithDeleteRequest:(MSTableDeleteRequest *)request
                                       completion:(MSDeleteBlock)completion;

// Creates a connection for read with query request. NOTE: The request is not
// sent until |start| is called.
+(MSTableConnection *)connectionWithReadRequest:(MSTableReadQueryRequest *)request
                                     completion:(MSReadQueryBlock)completion;

@end
