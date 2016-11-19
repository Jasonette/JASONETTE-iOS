// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class MSClient;
@class MSTable;
@class MSQuery;

#pragma  mark * MSURLBuilder Public Interface


// The |MSURLBuilder| class encapsulates the logic for building the
// appropriate URLs for the Mobile Service requests.
@interface MSURLBuilder : NSObject

#pragma  mark * Public URL Builder Methods

// Returns a URL for the table.
+(NSURL *)URLForTable:(MSTable *)table
            parameters:(NSDictionary *)parameters
            orError:(NSError **)error;

// Returns a URL for a particular item in the table.
+(NSURL *)URLForTable:(MSTable *)table
            itemIdString:(NSString *)itemId
            parameters:(NSDictionary *)parameters
            orError:(NSError **)error;

// Returns a URL for querying a table with the given query.
+(NSURL *)URLForTable:(MSTable *)table
                query:(NSString *)query;

// Returns a URL for the custom API.
+(NSURL *)URLForApi:(MSClient *)client
            APIName:(NSString *)APIName
            parameters:(NSDictionary *)parameters
            orError:(NSError **)error;

// Returns a query string from an |MSQuery| instance
+(NSString *)queryStringFromQuery:(MSQuery *)query
                          orError:(NSError **)error;

+(NSURL *) URLByAppendingQueryParameters:(NSDictionary *)queryParameters
                                   toURL:(NSURL *)url;
@end
