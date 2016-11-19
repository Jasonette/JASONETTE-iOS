// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSAPIRequest.h"
#import "MSURLBuilder.h"
#import "MSSDKFeatures.h"
#import "MSClientInternal.h"

#pragma mark * MSAPIRequest Implementation


@implementation MSAPIRequest


#pragma mark * Public Static Constructors


+(MSAPIRequest *) requestToinvokeAPI:(NSString *)APIName
                              client:(MSClient *)client
                                data:(NSData *)data
                          HTTPMethod:(NSString *)method
                          parameters:(NSDictionary *)parameters
                             headers:(NSDictionary *)headers
                          completion:(MSAPIDataBlock)completion
{
    return [MSAPIRequest requestToinvokeAPI:APIName client:client data:data HTTPMethod:method parameters:parameters headers:headers features:MSFeatureApiGeneric completion:completion];
}

+(MSAPIRequest *) requestToinvokeAPI:(NSString *)APIName
                              client:(MSClient *)client
                                body:(id)body
                          HTTPMethod:(NSString *)method
                          parameters:(NSDictionary *)parameters
                             headers:(NSDictionary *)headers
                          completion:(MSAPIBlock)completion
{
    MSAPIRequest *request = nil;
    NSError *error = nil;
    
    // Create the body or capture the error from serialization
    NSData *data = nil;
    if (body) {
        data = [client.serializer dataFromItem:body
                                     idAllowed:YES
                              ensureDictionary:NO
                        removeSystemProperties:NO
                                       orError:&error];
    }

    // If there was an error, call the completion and make sure
    // to return nil for the request
    if (error) {
        if (completion) {
            completion(nil, nil, error);
        }
    }
    else {
        request = [MSAPIRequest requestToinvokeAPI:APIName
                                            client:client
                                              data:data
                                        HTTPMethod:method
                                        parameters:parameters
                                           headers:headers
                                          features:MSFeatureApiJson
                                        completion:completion];
    }
    
    return request;
}

#pragma mark * Private Static Constructor

+(MSAPIRequest *) requestToinvokeAPI:(NSString *)APIName
                              client:(MSClient *)client
                                data:(NSData *)data
                          HTTPMethod:(NSString *)method
                          parameters:(NSDictionary *)parameters
                             headers:(NSDictionary *)headers
                            features:(MSFeatures)features
                          completion:(MSAPIDataBlock)completion
{
    MSAPIRequest *request = nil;
    NSError *error = nil;

    // Create the URL
    NSURL *url = [MSURLBuilder URLForApi:client
                                 APIName:APIName
                              parameters:parameters
                                 orError:&error];

    // If there was an error, call the completion and make sure
    // to return nil for the request
    if (error) {
        if (completion) {
            completion(nil, nil, error);
        }
    }
    else {
        if (parameters && [parameters count]) {
            features |= MSFeatureQueryParameters;
        }

        // Create the request
        request = [[MSAPIRequest alloc] initWithURL:url];

        // Set the body
        request.HTTPBody = data;

        // Set the user-defined headers properties
        [request setAllHTTPHeaderFields:headers];

        if (![headers objectForKey:MSFeaturesHeaderName]) {
            NSString *featuresHeader = [MSSDKFeatures httpHeaderForFeatures:features];
            if (featuresHeader) {
                [request setValue:featuresHeader forHTTPHeaderField:MSFeaturesHeaderName];
            }
        }

        // Set the method and headers
        request.HTTPMethod = [method uppercaseString];
        if (!request.HTTPMethod) {
            request.HTTPMethod = @"POST";
        }
    }

    return request;
}


#pragma mark * Private Initializer Method


-(id) initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    
    return self;
}

@end
