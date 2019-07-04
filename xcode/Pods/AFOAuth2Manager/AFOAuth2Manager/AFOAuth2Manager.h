// AFOAuth2Manager.h
//
// Copyright (c) 2012-2014 AFNetworking (http://afnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE

#import <Foundation/Foundation.h>
#import "AFOAuthCredential.h"
#import "AFHTTPRequestSerializer+OAuth2.h"
#import <AFNetworking/AFHTTPSessionManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface AFOAuth2Manager : AFHTTPSessionManager

///------------------------------------------
/// @name Accessing OAuth 2 Client Properties
///------------------------------------------

/**
 The service provider identifier used to store and retrieve OAuth credentials by `AFOAuthCredential`. Equivalent to the hostname of the client `baseURL`.
 */
@property (readonly, nonatomic, copy) NSString *serviceProviderIdentifier;

/**
 The client identifier issued by the authorization server, uniquely representing the registration information provided by the client.
 */
@property (readonly, nonatomic, copy) NSString *clientID;

/**
 Whether to encode client credentials in a Base64-encoded HTTP `Authorization` header, as opposed to the request body. Defaults to `YES`.
 */
@property (nonatomic, assign) BOOL useHTTPBasicAuthentication;

///------------------------------------------------
/// @name Creating and Initializing OAuth 2 Managers
///------------------------------------------------

/**
 Creates and initializes an `AFOAuth2Manager` object with the specified base URL, client identifier, and secret.

 @param url The base URL for the HTTP client. This argument must not be `nil`.
 @param clientID The client identifier issued by the authorization server, uniquely representing the registration information provided by the client. This argument must not be `nil`.
 @param secret The client secret.

 @return The newly-initialized OAuth 2 manager
 */
+ (instancetype)managerWithBaseURL:(NSURL *)url
                          clientID:(NSString *)clientID
                            secret:(NSString *)secret;

+ (instancetype)managerWithBaseURL:(NSURL *)url
              sessionConfiguration:(nullable NSURLSessionConfiguration *)configuration
                          clientID:(NSString *)clientID
                            secret:(NSString *)secret;

/**
 Initializes an `AFOAuth2Manager` object with the specified base URL, client identifier, and secret. The communication to to the server will use HTTP basic auth by default (use `-(id)initWithBaseURL:clientID:secret:withBasicAuth:` to change this).

 @param url The base URL for the HTTP manager. This argument must not be `nil`.
 @param clientID The client identifier issued by the authorization server, uniquely representing the registration information provided by the client. This argument must not be `nil`.
 @param secret The client secret.

 @return The newly-initialized OAuth 2 client
 */
- (id)initWithBaseURL:(NSURL *)url
             clientID:(NSString *)clientID
               secret:(NSString *)secret;

- (id)initWithBaseURL:(NSURL *)url
 sessionConfiguration:(nullable NSURLSessionConfiguration *)configuration
             clientID:(NSString *)clientID
               secret:(NSString *)secret;

///---------------------
/// @name Authenticating
///---------------------

/**
 Creates and enqueues an `NSURLSessionTask` to authenticate against the server using a specified username and password, with a designated scope.

 @param URLString The URL string used to create the request URL.
 @param username The username used for authentication
 @param password The password used for authentication
 @param scope The authorization scope
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                                 username:(NSString *)username
                                                 password:(NSString *)password
                                                    scope:(nullable NSString *)scope
                                                  success:(void (^)(AFOAuthCredential *credential))success
                                                  failure:(void (^)(NSError *error))failure;

/**
 Creates and enqueues an `NSURLSessionTask` to authenticate against the server with a designated scope.

 @param URLString The URL string used to create the request URL.
 @param scope The authorization scope
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                                    scope:(nullable NSString *)scope
                                                  success:(void (^)(AFOAuthCredential *credential))success
                                                  failure:(void (^)(NSError *error))failure;

/**
 Creates and enqueues an `NSURLSessionTask` to authenticate against the server using the specified refresh token.
 @param URLString The URL string used to create the request URL.
 @param refreshToken The OAuth refresh token
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                             refreshToken:(NSString *)refreshToken
                                                  success:(void (^)(AFOAuthCredential *credential))success
                                                  failure:(void (^)(NSError *error))failure;

/**
 Creates and enqueues an `NSURLSessionTask` to authenticate against the server with an authorization code, redirecting to a specified URI upon successful authentication.
 @param URLString The URL string used to create the request URL.
 @param code The authorization code
 @param uri The URI to redirect to after successful authentication
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                                     code:(NSString *)code
                                              redirectURI:(NSString *)uri
                                                  success:(void (^)(AFOAuthCredential *credential))success
                                                  failure:(void (^)(NSError *error))failure;

/**
 Creates and enqueues an `NSURLSessionTask` to authenticate against the server with the specified parameters.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                               parameters:(NSDictionary *)parameters
                                                  success:(void (^)(AFOAuthCredential *credential))success
                                                  failure:(void (^)(NSError *error))failure;

@end

///----------------
/// @name Constants
///----------------

/**
 ## Error Domains
 The following error domain is predefined.
 - `NSString * const AFOAuth2ErrorDomain`
 ## OAuth Grant Types
 OAuth 2.0 provides several grant types, covering several different use cases. The following grant type string constants are provided:
 `kAFOAuthCodeGrantType`: "authorization_code"
 `kAFOAuthClientCredentialsGrantType`: "client_credentials"
 `kAFOAuthPasswordCredentialsGrantType`: "password"
 `kAFOAuthRefreshGrantType`: "refresh_token"
 */
extern NSString * const AFOAuth2ErrorDomain;

extern NSString * const kAFOAuthCodeGrantType;
extern NSString * const kAFOAuthClientCredentialsGrantType;
extern NSString * const kAFOAuthPasswordCredentialsGrantType;
extern NSString * const kAFOAuthRefreshGrantType;

@compatibility_alias AFOAuth2Client AFOAuth2Manager;
@compatibility_alias AFOAuth2RequestOperationManager AFOAuth2Manager;

NS_ASSUME_NONNULL_END
