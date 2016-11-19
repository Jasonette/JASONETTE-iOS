// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSLoginSerializer.h"
#import "MSError.h"
#import "MSUser.h"

#pragma mark * MSLoginSerializer Implementation


@implementation MSLoginSerializer

static MSLoginSerializer *staticLoginSerializerSingleton;


#pragma mark * Public Static Singleton Constructor


+(MSLoginSerializer *) loginSerializer
{
    if (staticLoginSerializerSingleton == nil) {
        staticLoginSerializerSingleton = [[MSLoginSerializer alloc] init];
    }
    
    return  staticLoginSerializerSingleton;
}


#pragma mark * Public Serialization Methods


-(NSData *) dataFromToken:(id)token orError:(NSError **)error
{
    NSData *data = nil;
    NSError *localError = nil;
    
    // First, ensure there is an item...
    if (!token) {
        localError = [self errorForNilToken];
    }
    else {

        // Make sure the |NSJSONSerializer| can serialize it, otherwise
        // the |NSJSONSerializer| will throw an exception, which we don't
        // want--we'd rather return an error.
        if (![NSJSONSerialization isValidJSONObject:token]) {
            localError = [self errorForInvalidToken];
        }
        else {
            
            // If there is still an error serializing, |dataWithJSONObject|
            // will ensure that data the error is set and data is nil.
            data = [NSJSONSerialization dataWithJSONObject:token
                                                   options:0
                                                     error:error];
        }
    }
    
    if (localError && error) {
        *error = localError;
    }
    
    return data;
}


#pragma mark * Deserialization Methods


-(MSUser *) userFromData:(NSData *)data orError:(NSError **)error
{
    id userAsJson = nil;
    MSUser *user = nil;
    NSError *localError = nil;
    
    // Ensure there is data
    if (!data) {
        localError = [self errorForNilData];
    }
    else {
        
        // Try to deserialize the data; if it fails the error will be set
        // and userAsJson will be nil.
        userAsJson = [NSJSONSerialization JSONObjectWithData:data
                                                     options:NSJSONReadingAllowFragments
                                                       error:error];
        
        if (userAsJson) {
            
            // The JSON should have a userId and auth token strings
            id userId = [[userAsJson objectForKey:@"user"]
                         objectForKey:@"userId"];
            id authToken = [userAsJson objectForKey:@"authenticationToken"];
            
            if (![userId isKindOfClass:[NSString class]] ||
                ![authToken isKindOfClass:[NSString class]]) {
                localError = [self errorForInvalidUserJson];
            }
            else {
                user = [[MSUser alloc] initWithUserId:userId];
                if (user) {
                    user.mobileServiceAuthenticationToken = authToken;
                }
                else {
                    localError = [self errorForInvalidUserJson];
                }
            }
        }
    }
    
    if (localError && error) {
        *error = localError;
    }
    
    return user;
}


#pragma mark * Private NSError Generation Methods


-(NSError *) errorForNilToken
{
    return [self errorWithDescriptionKey:@"No token was provided."
                            andErrorCode:MSLoginExpectedToken];
}

-(NSError *) errorForInvalidToken
{
    return [self errorWithDescriptionKey:@"The token provided was not valid."
                            andErrorCode:MSLoginInvalidToken];
}

-(NSError *) errorForNilData
{
    return [self errorWithDescriptionKey:@"The server did return any data."
                            andErrorCode:MSExpectedBodyWithResponse];
}

-(NSError *) errorForInvalidUserJson
{
    return [self errorWithDescriptionKey:@"The token in the login response was invalid. The token must be a JSON object with both a userId and an authenticationToken."
                            andErrorCode:MSLoginInvalidResponseSyntax];
}

-(NSError *) errorWithDescriptionKey:(NSString *)descriptionKey
                        andErrorCode:(NSInteger)errorCode
{
    NSString *description = NSLocalizedString(descriptionKey, nil);
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey :description };
    
    return [NSError errorWithDomain:MSErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}

@end
