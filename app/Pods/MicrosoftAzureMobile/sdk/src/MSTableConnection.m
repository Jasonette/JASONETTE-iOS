// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSTableConnection.h"
#import "MSSerializer.h"
#import "MSQueryResult.h"
#import "MSClientInternal.h"
#import "MSTableRequest.h"
#import "MSTable.h"

// next link is the format "http://contoso.com; rel=next"
static NSString *const nextLinkPattern = @"^(.*?);\\s*rel\\s*=\\s*(\\w+)\\s*"; // $1; rel = $2

#pragma mark * MSTableConnection Implementation


@implementation MSTableConnection

@synthesize table = table_;


#pragma mark * Public Static Constructors


+(MSTableConnection *) connectionWithItemRequest:(MSTableItemRequest *)request
                                      completion:(MSItemBlock)completion
{
    // We'll use the conection in the response block below but won't set
    // it until the init at the end, so we need to use __block
    __block MSTableConnection *connection = nil;
    
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
                
                if (!error)
                {
                    item = [connection itemFromData:data
                                           response:response
                                   ensureDictionary:YES
                                            orError:&error];
                } else if (response && response.statusCode == 412) {
                    error = [self handleConflictResponse:response data:data connection:connection];
                }
                
                if (response && item && !error) {                    
                    // Add version to item is header is present
                    NSString *version = [[response allHeaderFields] objectForKey:@"Etag"];
                    if (version) {
                        if(version.length > 1 && [version characterAtIndex:0] == '\"' && [version characterAtIndex:version.length-1] == '\"') {
                            NSRange range = { 1, version.length - 2 };
                            version = [version substringWithRange:range];
                        }
                        [item setValue:[version stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""] forKey:MSSystemColumnVersion];
                    }
                }
            }
            
            [connection addRequestAndResponse:response toError:&error];
            completion(item, error);
            connection = nil;
        };
    }
    
    // Now create the connection with the MSResponseBlock
    connection = [[MSTableConnection alloc] initWithTableRequest:request
                                                      completion:responseCompletion];
    return connection;
}

+(MSTableConnection *) connectionWithDeleteRequest:(MSTableDeleteRequest *)request
                                        completion:(MSDeleteBlock)completion
{
    // We'll use the conection in the response block below but won't set
    // it until the init at the end, so we need to use __block
    __block MSTableConnection *connection = nil;
    
    // Create an HTTP response block that will invoke the MSDeleteBlock
    MSResponseBlock responseCompletion = nil;
    
    if (completion) {
    
        responseCompletion =
        ^(NSHTTPURLResponse *response, NSData *data, NSError *error)
        {
            
            if (!error) {
                [connection isSuccessfulResponse:response
                                        data:data
                                         orError:&error];
                
                if (error && response && response.statusCode == 412) {
                    error = [self handleConflictResponse:response data:data connection:connection];
                }
            }
            
            if (error) {
                [connection addRequestAndResponse:response toError:&error];
                completion(nil, error);
            }
            else {
                completion(request.itemId, nil);
            }
            connection = nil;
        };
    }
    
    // Now create the connection with the MSResponseBlock
    connection = [[MSTableConnection alloc] initWithTableRequest:request
                                                      completion:responseCompletion];
    return connection;

}
                                      
+(MSTableConnection *) connectionWithReadRequest:(MSTableReadQueryRequest *)request
                                      completion:(MSReadQueryBlock)completion
{
    // We'll use the conection in the response block below but won't set
    // it until the init at the end, so we need to use __block
    __block MSTableConnection *connection = nil;
    
    // Create an HTTP response block that will invoke the MSReadQueryBlock
    MSResponseBlock responseCompletion = nil;
    
    if (completion) {
    
        responseCompletion =
        ^(NSHTTPURLResponse *response, NSData *data, NSError *error)
        {
            NSArray *items = nil;
            NSInteger totalCount = -1;
            
            if (!error) {
                
                [connection isSuccessfulResponse:response
                                        data:data
                                         orError:&error];
                if (!error) {
                    totalCount = [connection items:&items
                                          fromData:data
                                      withResponse:response
                                           orError:&error];
                }
            }
            
            [connection addRequestAndResponse:response toError:&error];

            NSString *nextLink = [MSTableConnection parseNextLink:response];
        
            MSQueryResult *result = [[MSQueryResult alloc] initWithItems:items totalCount:totalCount nextLink:nextLink];
            completion(result, error);
            connection = nil;
        };
    }
    
    // Now create the connection with the MSSuccessBlock
    connection = [[MSTableConnection alloc] initWithTableRequest:request
                                                      completion:responseCompletion];
    return connection;
}

# pragma mark * Private Static Methods

+(NSString*) parseNextLink:(NSHTTPURLResponse *) response
{
    NSString *nextLink = nil;
    
    NSString *link = response.allHeaderFields[@"Link"];
    if (link) {
        NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:nextLinkPattern
                                                                               options:0
                                                                               error:nil];
        
        if (regEx) {
            NSTextCheckingResult *match = [regEx firstMatchInString:link options:0 range:NSMakeRange(0, link.length)];
            if (match) {
                NSString *linkUri = [link substringWithRange:[match rangeAtIndex:1]];
                NSString *linkRel = [link substringWithRange:[match rangeAtIndex:2]];
                if ([linkRel isEqualToString:@"next"]){
                    nextLink = linkUri;
                }
            }
        }
    }
    
    return nextLink;
}

+ (NSError *)handleConflictResponse:(NSHTTPURLResponse *)response data:(NSData *)data connection:(MSTableConnection *)connection
{
    NSError *error;
    NSError *serverItemError;
    NSDictionary *serverItem = [connection itemFromData:data
                                               response:response
                                       ensureDictionary:YES
                                                orError:&serverItemError];
    
    // Only override default error if response was a valid item
    if (!serverItemError) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"The server's version did not match the passed version",
                                    MSErrorServerItemKey: serverItem };
        error = [NSError errorWithDomain:MSErrorDomain code:MSErrorPreconditionFailed userInfo:userInfo];
    }
    return error;
}


# pragma mark * Private Init Methods


-(id) initWithTableRequest:(MSTableRequest *)request
                 completion:(MSResponseBlock)completion
{
    self = [super initWithRequest:request
                       client:request.table.client
                        completion:completion];
    
    if (self) {
        table_ = request.table;
    }
    
    return self;
}


# pragma mark * Private Methods


-(NSInteger) items:(NSArray **)items
                fromData:(NSData *)data
                withResponse:(NSHTTPURLResponse *)response
                orError:(NSError **)error
{
    // Try to deserialize the data
    NSInteger totalCount = [self.client.serializer totalCountAndItems:items
                                                             fromData:data
                                                              orError:error];
    
    // If there was an error, add the request and response
    if (error && *error) {
        [self addRequestAndResponse:response toError:error];
    }
    
    return totalCount;
}

+(void) removeSystemColumn:(NSString *)systemColumnName fromItem:(NSMutableDictionary *)item ifNotInQuery:(NSString *)query
{
    NSString *shortName = [systemColumnName substringFromIndex:2]; // Remove "__"
    if (item[systemColumnName] != nil) {
        if (!query || [query rangeOfString:shortName options:NSCaseInsensitiveSearch].location == NSNotFound) {
            [item removeObjectForKey:systemColumnName];
        }
    }
}

@end
