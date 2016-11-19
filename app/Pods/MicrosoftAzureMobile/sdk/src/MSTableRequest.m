// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSTableRequest.h"
#import "MSURLBuilder.h"
#import "MSSDKFeatures.h"
#import "MSClientInternal.h"
#import "MSTable.h"

#pragma mark * HTTP Method String Constants


static NSString *const httpGet = @"GET";
static NSString *const httpPatch = @"PATCH";
static NSString *const httpPost = @"POST";
static NSString *const httpDelete = @"DELETE";


#pragma mark * MSTableRequest Private Interface


@interface MSTableRequest ()

// Public readonly and private readwrite properties 
@property (nonatomic, readwrite)             MSTableRequestType requestType;

// Private initalizer method
-(id) initWithURL:(NSURL *)url
        withTable:(MSTable *)table;

-(void) setIfMatchVersion:(NSString *)version;

+(NSString *) versionFromItem:(NSDictionary *)item ItemId:(NSString *)itemId;

@end


#pragma mark * MSTableItemRequest Private Interface


@interface MSTableItemRequest ()

// Public readonly and private readwrite properties
@property (nonatomic, strong, readwrite)     id item;
@property (nonatomic, strong, readwrite)     id itemId;

@end


#pragma mark * MSTableDeleteRequest Private Interface


@interface MSTableDeleteRequest ()

// Public readonly and private readwrite properties
@property (nonatomic, strong, readwrite)     id item;
@property (nonatomic, strong, readwrite)     id itemId;

@end


#pragma mark * MSTableReadQueryRequest Private Interface


@interface MSTableReadQueryRequest ()

// Public readonly and private readwrite properties
@property (nonatomic, copy, readwrite)       NSString *queryString;

@end


#pragma mark * MSTableRequest Implementation


@implementation MSTableRequest

@synthesize requestType = requestType_;
@synthesize table = table_;


#pragma mark * Private Initializer Method


-(id) initWithURL:(NSURL *)url
            withTable:(MSTable *)table
{
    self = [super initWithURL:url];
    if (self) {
        table_ = table;
    }
    
    return self;
}


#pragma mark * Private Class Methods


-(void) setIfMatchVersion:(NSString *)version
 {
    if (version == nil) {
        return;
    }
    
    NSString *validHeaderVersion = [NSString stringWithFormat:@"\"%@\"",
                                    [version stringByReplacingOccurrencesOfString:@"\""
                                                                       withString:@"\\\""]];
    
    [self addValue:validHeaderVersion forHTTPHeaderField:@"If-Match"];
}


#pragma mark - Private Static Helper Functions

+(NSString *) versionFromItem:(NSDictionary *)item ItemId:(id)itemId
{
    if([itemId isKindOfClass:[NSString class]]) {
        id version = item[MSSystemColumnVersion];
        if ([version isKindOfClass:[NSString class]]) {
            return version;
        }
    }
    
    return nil;
}


#pragma mark * Public Static Constructors


+(MSTableItemRequest *) requestToInsertItem:(id)item
                                      table:(MSTable *)table
                                 parameters:(NSDictionary *)parameters
                                   features:(MSFeatures)features
                                 completion:(MSItemBlock)completion
{
    MSTableItemRequest *request = nil;
    NSError *error = nil;

    // Create the URL
    NSURL *url = [MSURLBuilder URLForTable:table
                                 parameters:parameters
                                    orError:&error];
    if (!error) {
        // Create the request
        request = [[MSTableItemRequest alloc] initWithURL:url
                                                withTable:table];
        
        // Create the body or capture the error from serialization
        NSData *data = [table.client.serializer dataFromItem:item
                                                   idAllowed:NO
                                            ensureDictionary:YES
                                      removeSystemProperties:NO
                                                     orError:&error];
        if (!error) {
            // Set the body
            request.HTTPBody = data;
            
            // Set the additionl properties
            request.requestType = MSTableInsertRequestType;
            request.item = item;
            
            // Set the method and headers
            request.HTTPMethod = httpPost;

            // Set features header if necessary
            [self addFeaturesHeaderForRequest:request queryParameters:parameters features:features];
        }
    }
    
    // If there was an error, call the completion and make sure
    // to return nil for the request
    if (error) {
        request = nil;
        if (completion) {
            completion(nil, error);
        }
    }
    
    return request;
}

+(MSTableItemRequest *) requestToUpdateItem:(id)item
                                      table:(MSTable *)table
                                 parameters:(NSDictionary *)parameters
                                   features:(MSFeatures)features
                                 completion:(MSItemBlock)completion

{
    MSTableItemRequest *request = nil;
    NSError *error = nil;
    id<MSSerializer> serializer = table.client.serializer;
    
    id itemId = [serializer itemIdFromItem:item orError:&error];
    if (!error) {
        // Ensure we can get a string from the item Id
        NSString *idString = [serializer stringFromItemId:itemId
                                                  orError:&error];
        
        if (!error) {
            // Create the URL
            NSURL *url = [MSURLBuilder URLForTable:table
                                       itemIdString:idString
                                         parameters:parameters
                                            orError:&error];
            if (!error) {
                // Create the request
                request = [[MSTableItemRequest alloc] initWithURL:url
                                                        withTable:table];
                request.itemId = itemId;
            
                // If string id, cache the version field as we strip it out during serialization
                NSString *version = [MSTableRequest versionFromItem:item ItemId:itemId];
                
                // Create the body or capture the error from serialization
                NSData *data = [serializer dataFromItem:item
                                              idAllowed:YES
                                       ensureDictionary:YES
                                 removeSystemProperties:YES
                                                orError:&error];
                if (!error) {
                    // Set the body
                    request.HTTPBody = data;
                    
                    // Set the properties
                    request.requestType = MSTableUpdateRequestType;
                    request.item = item;
                    
                    // Set the method and headers
                    request.HTTPMethod = httpPatch;
                    
                    // Version becomes an etag if passed
                    [request setIfMatchVersion:version];

                    // Set features header if necessary
                    [self addFeaturesHeaderForRequest:request queryParameters:parameters features:features];
                }
            }
        }
    }
    
    // If there was an error, call the completion and make sure
    // to return nil for the request
    if (error) {
        request = nil;
        if (completion) {
            completion(nil, error);
        }
    }
    
    return request;
}

+(MSTableDeleteRequest *) requestToDeleteItem:(id)item
                                        table:(MSTable *)table
                                   parameters:(NSDictionary *)parameters
                                     features:(MSFeatures)features
                                   completion:(MSDeleteBlock)completion
{
    MSTableDeleteRequest *request = nil;
    NSError *error = nil;
    
    // Ensure we can get the item Id
    id itemId = [table.client.serializer itemIdFromItem:item orError:&error];
    if (!error) {
        // If string id, cache the version field as we strip it out during serialization
        NSString *version = [MSTableRequest versionFromItem:item ItemId:itemId];
        
        // Get the request from the other constructor
        request = [MSTableRequest requestToDeleteItemWithId:itemId
                                                      table:table
                                                 parameters:parameters
                                                   features:MSFeatureNone
                                                 completion:completion];
        
        // Set the additional properties
        request.item = item;
        
        // Version becomes an etag if passed
        [request setIfMatchVersion:version];

        // Set features header if necessary
        [self addFeaturesHeaderForRequest:request queryParameters:parameters features:features];
    }
    
    // If there was an error, call the completion and make sure
    // to return nil for the request
    if (error) {
        request = nil;
        if (completion) {
            completion(nil, error);
        }
    }
    
    return request;
}

+(MSTableDeleteRequest *) requestToDeleteItemWithId:(id)itemId
                                              table:(MSTable *)table
                                         parameters:(NSDictionary *)parameters
                                           features:(MSFeatures)features
                                         completion:(MSDeleteBlock)completion
{
    MSTableDeleteRequest *request = nil;
    NSError *error = nil;
    
    // Ensure we can get the id as a string
    NSString *idString = [table.client.serializer stringFromItemId:itemId
                                                           orError:&error];
    if (!error) {
    
        // Create the URL
        NSURL *url = [MSURLBuilder URLForTable:table
                                   itemIdString:idString
                                     parameters:parameters
                                            orError:&error];
        if (!error) {
            
            // Create the request
            request = [[MSTableDeleteRequest alloc] initWithURL:url
                                                      withTable:table];
            
            // Set the additional properties
            request.requestType = MSTableDeleteRequestType;
            request.itemId = itemId;
            
            // Set the method and headers
            request.HTTPMethod = httpDelete;

            // Set features header if necessary
            [self addFeaturesHeaderForRequest:request queryParameters:parameters features:features];
        }
    }
    
    // If there was an error, call the completion and make sure
    // to return nil for the request
    if (error) {
        request = nil;
        if (completion) {
            completion(nil, error);
        }
    }
    
    return request;
}

+(MSTableItemRequest *) requestToUndeleteItem:(id)item
                                        table:(MSTable *)table
                                   parameters:(NSDictionary *)parameters
                                     features:(MSFeatures)features
                                   completion:(MSItemBlock)completion
{
    MSTableItemRequest *request = nil;
    NSError *error = nil;
    id<MSSerializer> serializer = table.client.serializer;
    
    // Ensure we can get the item Id
    id itemId = [serializer itemIdFromItem:item orError:&error];
    if (!error) {
        // Ensure we can get a string from the item Id
        NSString *idString = [serializer stringFromItemId:itemId
                                                  orError:&error];
        
        if (!error) {
            // Create the URL
            NSURL *url =  [MSURLBuilder URLForTable:table
                                       itemIdString:idString
                                         parameters:parameters
                                            orError:&error];
            
            if (!error) {
                // Create the request
                request = [[MSTableItemRequest alloc] initWithURL:url
                                                          withTable:table];
                
                // Set the additional properties
                request.requestType = MSTableUndeleteRequestType;
                request.itemId = itemId;
                
                // Set the method and headers
                request.HTTPMethod = httpPost;

                // Add the optional if-match header
                NSString *version = [MSTableRequest versionFromItem:item ItemId:itemId];
                [request setIfMatchVersion:version];

                // Set features header if necessary
                [self addFeaturesHeaderForRequest:request queryParameters:parameters features:features];
            }
        }
    }
    
    // If there was an error, call the completion and make sure
    // to return nil for the request
    if (error) {
        request = nil;
        if (completion) {
            completion(nil, error);
        }
    }
    
    return request;
}

+(MSTableItemRequest *) requestToReadWithId:(id)itemId
                                      table:(MSTable *)table
                                 parameters:(NSDictionary *)parameters
                                 completion:(MSItemBlock)completion
{
    MSTableItemRequest *request = nil;
    NSError *error = nil;
    
    // Ensure we can get the id as a string
    NSString *idString = [table.client.serializer stringFromItemId:itemId
                                                           orError:&error];
    if (!error) {

        // Create the URL
        NSURL *url =  [MSURLBuilder URLForTable:table
                                   itemIdString:idString
                                     parameters:parameters
                                        orError:&error];
        if (!error) {
            
            // Create the request
            request = [[MSTableItemRequest alloc] initWithURL:url
                                                    withTable:table];
            
            // Set the additional properties
            request.requestType = MSTableReadRequestType;
            request.itemId = itemId;
            
            // Set the method and headers
            request.HTTPMethod = httpGet;

            // Set features header if necessary
            [self addFeaturesHeaderForRequest:request queryParameters:parameters features:MSFeatureNone];
        }
    }
    
    // If there was an error, call the completion and make sure
    // to return nil for the request
    if (error) {
        request = nil;
        if (completion) {
            completion(nil, error);
        }
    }
    
    return request;
}

+(MSTableReadQueryRequest *) requestToReadItemsWithQuery:(NSString *)queryString
                                                   table:(MSTable *)table
                                                features:(MSFeatures)features
                                              completion:(MSReadQueryBlock)completion
{
    MSTableReadQueryRequest *request = nil;
    
    NSURL *url = [NSURL URLWithString:queryString];
    
    if (url && url.scheme && url.host) {
        // if it is valid absolute URL (e.g. nextLink) then take it as it is
        queryString = url.query;
        features |= MSFeatureReadWithLinkHeader;
    }
    else {
        // otherwise consider it to be query string and append it to table endpoint
        url = [MSURLBuilder URLForTable:table query:queryString];
    }
    
    // Create the request
    request = [[MSTableReadQueryRequest alloc] initWithURL:url
                                                 withTable:table];
    
    // Set the additional properties
    request.requestType = MSTableReadQueryRequestType;
    request.queryString = queryString;
    
    // Set the method and headers
    request.HTTPMethod = httpGet;

    // Set features header if necessary
    [self addFeaturesHeaderForRequest:request queryParameters:nil features:features];

    return request;
}

#pragma mark * Private Static Constructors

+ (NSString *)getVersionFromItem:(id)item itemId:(id)itemId
{
    // If string id, cache the version field as we strip it out during serialization
    NSString *version= nil;
    if([itemId isKindOfClass:[NSString class]]) {
        version = [item objectForKey:MSSystemColumnVersion];
    }
    return version;
}

+ (void)addFeaturesHeaderForRequest:(MSTableRequest *)request queryParameters:(NSDictionary *)parameters features:(MSFeatures)features {
    if ([[request allHTTPHeaderFields] objectForKey:@"If-Match"]) {
        features |= MSFeatureOpportunisticConcurrency;
    }
    if (parameters && [parameters count]) {
        features |= MSFeatureQueryParameters;
    }

    [request setValue:[MSSDKFeatures httpHeaderForFeatures:features] forHTTPHeaderField:MSFeaturesHeaderName];
}

@end


#pragma mark * MSTableItemRequest Implementation


@implementation MSTableItemRequest

@synthesize itemId = itemId_;
@synthesize item = item_;

@end


#pragma mark * MSTableDeleteRequest Implementation


@implementation MSTableDeleteRequest

@synthesize itemId = itemId_;
@synthesize item = item_;

@end


#pragma mark * MSTableReadQueryRequest Implementation


@implementation MSTableReadQueryRequest

@synthesize queryString = queryString_;

@end
