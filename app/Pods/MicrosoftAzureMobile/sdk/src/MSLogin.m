// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSLogin.h"
#import "MSLoginSerializer.h"
#import "MSJSONSerializer.h"
#import "MSClientConnection.h"
#import "MSClient.h"
#import "MSClientInternal.h"
#import "MSSDKFeatures.h"
#import "MSUser.h"

#if TARGET_OS_IPHONE
#import "MSLoginController.h"
#endif

#pragma mark * MSLogin Private Interface


@interface MSLogin ()

// Private properties
@property (nonatomic, strong, readonly)     id<MSSerializer> serializer;

@end


#pragma mark * MSLogin Implementation


@implementation MSLogin

@synthesize client = client_;


#pragma  mark * Public Initializer Methods


-(id) initWithClient:(MSClient *)client
{
    self = [super init];
    if (self) {
        client_ = client;
    }
    
    return self;
}


#pragma  mark * Public Login Methods

#if TARGET_OS_IPHONE
-(void) loginWithProvider:(NSString *)provider
               parameters:(nullable NSDictionary *)parameters
               controller:(UIViewController *)controller
                 animated:(BOOL)animated
               completion:(nullable MSClientLoginBlock)completion
{
    __block MSLoginController *loginController = nil;
    __block MSUser *localUser = nil;
    __block NSError *localError = nil;
    __block int allDoneCount = 0;
  
    void (^callCompletionIfAllDone)() = ^{
        allDoneCount++;
        if (allDoneCount == 2) {
            // Its possible for this to be triggered to close in the completion block of the present
            // controller call, for example when there is no network connection.
            // In order to avoid an error with the presentation animation still finishing, put the
            // dismiss call onto the main queue and let this block finish running.
            dispatch_async(dispatch_get_main_queue(), ^{
                [controller dismissViewControllerAnimated:animated completion:^{
                    if (completion) {
                        completion(localUser, localError);
                    }
                    localUser = nil;
                    localError = nil;
                    loginController = nil;
                }];
            });
        }
    };
    
    // Create a completion block that will dismiss the controller, and then
    // in the controller dismissal completion, call the completion that was
    // passed in by the caller.  This ensures that if the dismissal is animated
    // the LoginViewController has fuly disappeared from view before the
    // final completion is called.
    MSClientLoginBlock loginCompletion = ^(MSUser *user, NSError *error){
        localUser = user;
        localError = error;
        callCompletionIfAllDone();
    };
    
    provider = [self normalizeProvider:provider];
    loginController = [self loginViewControllerWithProvider:provider
                                                 parameters:parameters
                                                 completion:loginCompletion];
    
    // On iPhone this will do nothing, but on iPad it will present a smaller
    // view that looks much better for login
    loginController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    dispatch_async(dispatch_get_main_queue(),^{
        [controller presentViewController:loginController
                                 animated:animated
                               completion:callCompletionIfAllDone];
    });
}

-(MSLoginController *) loginViewControllerWithProvider:(NSString *)provider
                                            parameters:(nullable NSDictionary *)parameters
                                            completion:(nullable MSClientLoginBlock)completion
{
    provider = [self normalizeProvider:provider];
    return [[MSLoginController alloc] initWithClient:self.client
                                            provider:provider
                                          parameters:parameters
                                          completion:completion];
}

#endif

-(void) loginWithProvider:(NSString *)provider
                token:(NSDictionary *)token
               completion:(nullable MSClientLoginBlock)completion
{
    // Create the request
    NSError *error = nil;
    provider = [self normalizeProvider:provider];
    NSURLRequest *request = [self requestForProvider:provider
                                            andToken:token
                                             orError:&error];
    
    // If creating the request failed, call the completion block,
    // otherwise, send the login request
    if (error) {
        if (completion) {
            completion(nil, error);
        }
    }
    else {
        
        // Create the response completion block
        MSResponseBlock responseCompletion = nil;
        if (completion) {
            
            responseCompletion = 
            ^(NSHTTPURLResponse *response, NSData *data, NSError *responseError)
            {
                MSUser *user = nil;
                
                if (!responseError) {
                    if (response.statusCode >= 400) {
                        responseError = [self.serializer errorFromData:data
                                                              MIMEType:response.MIMEType];
                    }
                    else {
                        user = [[MSLoginSerializer loginSerializer]
                                userFromData:data
                                orError:&responseError];
                        
                        if (user) {
                            self.client.currentUser = user;
                        }
                    }
                }
                
                completion(user, responseError);
            };
        }
        
        // Create the connection and start it
        MSClientConnection *connection = [[MSClientConnection alloc]
                                                initWithRequest:request
                                                client:self.client
                                                completion:responseCompletion];
        [connection startWithoutFilters];
    }
}

-(void)refreshUserWithCompletion:(nullable MSClientLoginBlock)completion
{
    // Create the request
    NSURL *URL = [self.client.loginHost URLByAppendingPathComponent:@".auth/refresh"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    MSResponseBlock responseCompletion = nil;
    if (completion) {
        // Define a response completion block if required
        responseCompletion = ^(NSHTTPURLResponse *response, NSData *data, NSError *responseError)
        {
            MSUser *user = nil;
            if (!responseError) {
                if (response.statusCode == 200) {
                    user = [[MSLoginSerializer loginSerializer] userFromData:data orError:&responseError];
                    if (!responseError) {
                        self.client.currentUser.mobileServiceAuthenticationToken = user.mobileServiceAuthenticationToken;
                    }
                }
                else {
                    NSError *internalError = [self.serializer errorFromData:data MIMEType:response.MIMEType];
                    switch (response.statusCode) {
                        case 400:
                            responseError = [self errorWithDescription:@"Refresh failed with a 400 Bad Request error. The identity provider does not support refresh, or the user is not logged in with sufficient permission."
                                        code:MSRefreshBadRequest
                                        internalError:internalError];
                            break;
                        case 401:
                            responseError = [self errorWithDescription:@"Refresh failed with a 401 Unauthorized error. Credentials are no longer valid."
                                        code:MSRefreshUnauthorized
                                        internalError:internalError];
                            break;
                        case 403:
                            responseError = [self errorWithDescription:@"Refresh failed with a 403 Forbidden error. The refresh token was revoked or expired."
                                        code:MSRefreshForbidden
                                        internalError:internalError];
                            break;
                        default:
                            responseError = [self errorWithDescription:@"Refresh failed with an unexpected error."
                                        code:MSRefreshUnexpectedError
                                        internalError:internalError];
                            break;
                    }
                }
            }
            completion(user, responseError);
        };
    }
    
    // Create the connection and start it
    MSClientConnection *connection = [[MSClientConnection alloc]
                                      initWithRequest:request
                                      client:self.client
                                      features:MSFeatureRefreshToken
                                      completion:responseCompletion];
    [connection start];
}

#pragma mark * Private Serializer Property Accessor Methods
    
    
-(id<MSSerializer>) serializer
{
    // Just use a hard coded reference to MSJSONSerializer
    return [MSJSONSerializer JSONSerializer];
}


#pragma mark * Private Methods


-(NSString *) normalizeProvider:(NSString *)provider {
    // Microsoft Azure Active Directory can be specified either in
    // full or with the 'aad' abbreviation. The service REST API
    // expects 'aad' only.
    if ([[provider lowercaseString] isEqualToString:@"windowsazureactivedirectory"]) {
        return @"aad";
    } else {
        return provider;
    }
}

-(NSURLRequest *) requestForProvider:(NSString *)provider
                            andToken:(NSDictionary *)token
                             orError:(NSError **)error
{
    NSMutableURLRequest *request = nil;
    NSData *requestBody = [[MSLoginSerializer loginSerializer] dataFromToken:token
                                                                     orError:error];
    if (requestBody) {
        NSURL *URL = [self.client.loginURL URLByAppendingPathComponent:provider];

        request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        request.HTTPBody = requestBody;
    }
    
    return request;
}


#pragma mark * Private NSError Generation Methods


- (NSError *) errorWithDescription:(NSString *)description code:(NSInteger)code internalError:(NSError *)error
{
    NSMutableDictionary *userInfo = [@{ NSLocalizedDescriptionKey: description } mutableCopy];
    
    if (error) {
        [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    }
    
    return [NSError errorWithDomain:MSErrorDomain code:code userInfo:userInfo];
}

@end
