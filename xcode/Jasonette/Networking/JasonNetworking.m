//
//  JasonNetworking.m
//  Jasonette
//
//  Created by Jasonelle Team on 05-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import "JasonNetworking.h"
#import "JasonLogger.h"

static AFHTTPSessionManager * _sessionManager;
static AFJSONResponseSerializer * _responseSerializer;
static NSArray * _acceptedContentTypes;
static NSDictionary * _headers;

@implementation JasonNetworking

+ (nonnull AFHTTPSessionManager *) manager
{
    if(!_sessionManager)
    {
        _sessionManager = [AFHTTPSessionManager manager];
    }
    
    return _sessionManager;
}

+ (void) setSessionManager: (AFHTTPSessionManager *) manager
{
    if(!manager)
    {
        DTLogWarning(@"AFHTTPSessionManager not found");
    }
    
    _sessionManager = manager;
}

+ (nonnull AFJSONResponseSerializer *) serializer
{
    if(!_responseSerializer)
    {
        _responseSerializer = [AFJSONResponseSerializer serializer];
    }
    
    return _responseSerializer;
}

+ (void) setResponseSerializer: (AFJSONResponseSerializer *) serializer
{
    if(!serializer)
    {
        DTLogWarning(@"AFJSONResponseSerializer not found");
    }
    _responseSerializer = serializer;
}

+ (nonnull NSArray *) acceptedContentTypes
{
    if(!_acceptedContentTypes)
    {
        _acceptedContentTypes = @[];
    }
    
    return _acceptedContentTypes;
}

+ (void) setAcceptedContentTypes : (nonnull NSArray *) types
{
    if(!types || [types count] <= 0)
    {
        DTLogWarning(@"Setting Empty Content Types");
    }
    
    _acceptedContentTypes = types;
}

+ (nonnull NSDictionary *) headers
{
    if(!_headers)
    {
        _headers = @{};
    }
    
    return _headers;
}

+ (void) setHeaders : (nonnull NSDictionary *) headers
{
    if(!headers)
    {
        DTLogWarning(@"Setting Empty Headers");
    }
    
    _headers = headers;
}

@end
