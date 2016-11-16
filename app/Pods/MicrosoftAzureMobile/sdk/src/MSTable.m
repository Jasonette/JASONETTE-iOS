// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSClientInternal.h"
#import "MSTable.h"
#import "MSQuery.h"
#import "MSJSONSerializer.h"
#import "MSTableRequest.h"
#import "MSTableConnection.h"
#import "MSSDKFeatures.h"
#import "MSTableInternal.h"

#pragma mark * MSTable Implementation

NSString *const MSSystemColumnId = @"id";
NSString *const MSSystemColumnCreatedAt = @"createdAt";
NSString *const MSSystemColumnUpdatedAt = @"updatedAt";
NSString *const MSSystemColumnVersion = @"version";
NSString *const MSSystemColumnDeleted = @"deleted";

@implementation MSTable

@synthesize client = client_;
@synthesize name = name_;
@synthesize features = features_;

#pragma mark * Public Initializer Methods


-(id) initWithName:(NSString *)tableName client:(MSClient *)client;
{    
    self = [super init];
    if (self)
    {
        client_ = client;
        name_ = tableName;
        features_ = MSFeatureNone;
    }
    return self;
}


#pragma mark * Public Insert, Update, Delete Methods


-(void) insert:(NSDictionary *)item completion:(MSItemBlock)completion
{
    [self insert:item parameters:nil completion:completion];
}

-(void) insert:(NSDictionary *)item
    parameters:(NSDictionary *)parameters
    completion:(MSItemBlock)completion
{
    // Create the request
    MSTableItemRequest *request = [MSTableRequest
                                   requestToInsertItem:item
                                   table:self
                                   parameters:parameters
                                   features:self.features
                                   completion:completion];
    // Send the request
    if (request) {
        MSTableConnection *connection =
            [MSTableConnection connectionWithItemRequest:request
                                              completion:completion];
        [connection start];
    }
}

-(void) update:(NSDictionary *)item completion:(MSItemBlock)completion
{
    [self update:item parameters:nil completion:completion];
}

-(void) update:(NSDictionary *)item
    parameters:(NSDictionary *)parameters
    completion:(MSItemBlock)completion
{    
    MSTableItemRequest *request = [MSTableRequest
                                   requestToUpdateItem:item
                                   table:self
                                   parameters:parameters
                                   features:self.features
                                   completion:completion];
    
    // Send the request
    if (request) {        
        MSTableConnection *connection =
            [MSTableConnection connectionWithItemRequest:request
                                              completion:completion];
        [connection start];
    }
}

-(void) delete:(NSDictionary *)item completion:(MSDeleteBlock)completion
{
    [self delete:item parameters:nil completion:completion];
}

-(void) delete:(NSDictionary *)item
    parameters:(NSDictionary *)parameters
    completion:(MSDeleteBlock)completion
{
    // Create the request
    MSTableDeleteRequest *request = [MSTableRequest
                                     requestToDeleteItem:item
                                     table:self
                                     parameters:parameters
                                     features:self.features
                                     completion:completion];
    // Send the request
    if (request) {
        MSTableConnection *connection =
            [MSTableConnection connectionWithDeleteRequest:request
                                                completion:completion];
        [connection start];
    }
}

-(void) deleteWithId:(id)itemId completion:(MSDeleteBlock)completion
{
    [self deleteWithId:itemId parameters:nil completion:completion];
}

-(void) deleteWithId:(id)itemId
          parameters:(NSDictionary *)parameters
          completion:(MSDeleteBlock)completion
{
    // Create the request
    MSTableDeleteRequest *request = [MSTableRequest
                                     requestToDeleteItemWithId:itemId
                                     table:self
                                     parameters:parameters
                                     features:self.features
                                     completion:completion];
    // Send the request
    if (request) {
        MSTableConnection *connection = 
            [MSTableConnection connectionWithDeleteRequest:request
                                                completion:completion];
        [connection start];
    }
}

-(void)undelete:(NSDictionary *)item completion:(MSItemBlock)completion
{
    [self undelete:item parameters:nil completion:completion];
}

-(void)undelete:(NSDictionary *)item
        parameters:(NSDictionary *)parameters
        completion:(MSItemBlock)completion
{
    // Create the request
    MSTableItemRequest *request = [MSTableRequest
                                     requestToUndeleteItem:item
                                     table:self
                                     parameters:parameters
                                   features:self.features
                                     completion:completion];
                                     
    // Send the request
    if (request) {
        MSTableConnection *connection =
        [MSTableConnection connectionWithItemRequest:request
                                          completion:completion];
        [connection start];
    }
    
}


#pragma mark * Public Read Methods


-(void) readWithId:(id)itemId completion:(MSItemBlock)completion
{
    [self readWithId:itemId parameters:nil completion:completion];
}

-(void) readWithId:(id)itemId
        parameters:(NSDictionary *)parameters
        completion:(MSItemBlock)completion
{
    // Create the request
    MSTableItemRequest *request = [MSTableRequest
                                   requestToReadWithId:itemId
                                   table:self
                                   parameters:parameters
                                   completion:completion];
    // Send the request
    if (request) {
        MSTableConnection *connection =
            [MSTableConnection connectionWithItemRequest:request
                                              completion:completion];
        [connection start];
    }
}

-(void) readWithQueryString:(NSString *)queryString
                 completion:(MSReadQueryBlock)completion
{
    return [self readWithQueryStringInternal:queryString features:MSFeatureTableReadRaw completion:completion];
}

-(void)readWithQueryStringInternal:(NSString *)queryString
                          features:(MSFeatures)features
                        completion:(MSReadQueryBlock)completion {
    // Create the request
    MSTableReadQueryRequest *request = [MSTableRequest
                                        requestToReadItemsWithQuery:queryString
                                        table:self
                                        features:features
                                        completion:completion];
    // Send the request
    if (request) {
        MSTableConnection *connection =
        [MSTableConnection connectionWithReadRequest:request
                                          completion:completion];
        [connection start];
    }
}

-(void) readWithCompletion:(MSReadQueryBlock)completion
{
    // Read without a query string
    [self readWithQueryStringInternal:nil features:self.features completion:completion];
}

-(void) readWithPredicate:(NSPredicate *) predicate
            completion:(MSReadQueryBlock)completion
{
    // Create the query from the predicate
    MSQuery *query = [self queryWithPredicate:predicate];
    
    // Call read on the query
    [query readWithCompletion:completion];
}


#pragma mark * Public Query Methods


-(MSQuery *) query
{
    return [[MSQuery alloc] initWithTable:self];
}

-(MSQuery *) queryWithPredicate:(NSPredicate *)predicate
{
    return [[MSQuery alloc] initWithTable:self predicate:predicate];
}

@end
