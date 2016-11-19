// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSClientConnection.h"
#import "MSUserAgentBuilder.h"
#import "MSFilter.h"
#import "MSUser.h"
#import "MSClientInternal.h"
#import "MSSDKFeatures.h"
#import <objc/runtime.h>
#import "NSURLSessionTask+Completion.h"

#pragma mark * NSURLSessionTask(Completion) implementation

@implementation NSURLSessionTask(Completion)
@dynamic completion;
@dynamic data;

- (MSResponseBlock)completion
{
    return objc_getAssociatedObject(self, @selector(completion));
}

- (void)setCompletion:(MSResponseBlock)completion
{
    objc_setAssociatedObject(self, @selector(completion), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSMutableData *)data
{
    NSMutableData *_data = objc_getAssociatedObject(self, @selector(data));
    if (!_data) {
        _data = [NSMutableData data];
        // Call the explicit setter so the setAssociatedObject method gets called to retain the data
        self.data = _data;
    }
    
    return _data;
}

- (void)setData:(NSMutableData *)data
{
    objc_setAssociatedObject(self, @selector(data), data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark * HTTP Header String Constants


static NSString *const contentTypeHeader = @"Content-Type";
static NSString *const userAgentHeader = @"User-Agent";
static NSString *const zumoVersionHeader = @"X-ZUMO-VERSION";
static NSString *const zumoApiVersionHeader = @"ZUMO-API-VERSION";
static NSString *const jsonContentType = @"application/json";
static NSString *const xZumoAuth = @"X-ZUMO-AUTH";
static NSString *const xZumoInstallId = @"X-ZUMO-INSTALLATION-ID";

#pragma mark * MSClientConnection Implementation


@implementation MSClientConnection

static NSOperationQueue *delegateQueue;

@synthesize client = client_;
@synthesize request = request_;
@synthesize completion = completion_;

# pragma mark * Public Initializer Methods

-(id) initWithRequest:(NSURLRequest *)request
               client:(MSClient *)client
           completion:(MSResponseBlock)completion
{
    return [self initWithRequest:request client:client features:MSFeatureNone completion:completion];
}

-(id) initWithRequest:(NSURLRequest *)request
               client:(MSClient *)client
             features:(MSFeatures)features
           completion:(MSResponseBlock)completion
{
    self = [super init];
    if (self) {
        client_ = client;
        request_ = [MSClientConnection configureHeadersOnRequest:request
                                                      withClient:client
                                                    withFeatures:features];
        completion_ = [completion copy];
    }
    
    return self;
}

#pragma mark * Public Start Methods


-(void) start
{
    [MSClientConnection invokeNextFilter:self.client.filters
                              withClient:self.client
                             withRequest:self.request
                              completion:self.completion];
}

-(void) startWithoutFilters
{
    [MSClientConnection invokeNextFilter:nil
                              withClient:self.client
                             withRequest:self.request
                              completion:self.completion];
}


#pragma mark * Public Response Handling Methods


-(BOOL) isSuccessfulResponse:(NSHTTPURLResponse *)response
                        data:(NSData *)data
                     orError:(NSError **)error
{
    // Success is determined just by the HTTP status code
    BOOL isSuccessful = response.statusCode < 400;
    
    if (!isSuccessful && self.completion && error) {
        // Read the error message from the response body
        *error =[self.client.serializer errorFromData:data
                                             MIMEType:response.MIMEType];
        [self addRequestAndResponse:response toError:error];
    }
    
    return isSuccessful;
}

-(id) itemFromData:(NSData *)data
          response:(NSHTTPURLResponse *)response
          ensureDictionary:(BOOL)ensureDictionary
          orError:(NSError **)error
{
    // Try to deserialize the data
    id item = [self.client.serializer itemFromData:data
                                  withOriginalItem:nil
                                  ensureDictionary:ensureDictionary
                                           orError:error];
    
    // If there was an error, add the request and response
    if (error && *error) {
        [self addRequestAndResponse:response toError:error];
    }
    
    return item;
}


-(void) addRequestAndResponse:(NSHTTPURLResponse *)response
                      toError:(NSError **)error
{
    if (error && *error) {
        // Create a new error with request and the response in the userInfo...
        NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
        [userInfo setObject:self.request forKey:MSErrorRequestKey];
        
        if (response) {
            [userInfo setObject:response forKey:MSErrorResponseKey];
        }
        
        *error = [NSError errorWithDomain:(*error).domain
                                     code:(*error).code
                                 userInfo:userInfo];
    }
}


# pragma mark * Private Static Methods


+(void) invokeNextFilter:(NSArray<id<MSFilter>> *)filters
              withClient:(MSClient *)client
             withRequest:(NSURLRequest *)request
               completion:(MSFilterResponseBlock)completion
{
    if (!filters || filters.count == 0) {
		// No filters to invoke so use |NSURLSessionDataTask | to actually
		// send the request.
		
		NSURLSessionDataTask *task = [client.urlSession dataTaskWithRequest:request];
        task.completion = completion;
        
		[task resume];
    }
    else {
        
        // Since we have at least one more filter, construct the nextBlock
        // for it and then invoke the filter
        id<MSFilter> nextFilter = [filters objectAtIndex:0];
        NSArray<id<MSFilter>> *nextFilters = [filters subarrayWithRange:
                                NSMakeRange(1, filters.count - 1)];
    
        MSFilterNextBlock onNext =
        [^(NSURLRequest *onNextRequest,
           MSFilterResponseBlock onNextResponse)
        {
            [MSClientConnection invokeNextFilter:nextFilters
                                      withClient:client
                                     withRequest:onNextRequest
                                      completion:onNextResponse];                                    
        } copy];
        
        [nextFilter handleRequest:request
                           next:onNext
                       response:completion];
    }
}

+(NSURLRequest *) configureHeadersOnRequest:(NSURLRequest *)request
                                 withClient:(MSClient *)client
                                withFeatures:(MSFeatures)features
{
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    NSString *requestHost = request.URL.host;
    NSString *applicationHost = client.applicationURL.host;
    if ([applicationHost isEqualToString:requestHost])
    {
        // Add the authentication header if the user is logged in
        if (client.currentUser &&
            client.currentUser.mobileServiceAuthenticationToken) {
            [mutableRequest
             setValue:client.currentUser.mobileServiceAuthenticationToken
             forHTTPHeaderField:xZumoAuth];
        }
        
        // Set the User Agent header
        NSString *userAgentValue = [MSUserAgentBuilder userAgent];
        [mutableRequest setValue:userAgentValue
              forHTTPHeaderField:userAgentHeader];
        
        // Set the Zumo Version Header
        [mutableRequest setValue:userAgentValue
              forHTTPHeaderField:zumoVersionHeader];
        
        // Set the Zumo API Version Header for table, api, push, etc requests only
        // Exemptions will need added if later on we use a wrapping MSLoginRequest object
        if (![request isMemberOfClass:[NSURLRequest class]]) {
            [mutableRequest setValue:@"2.0.0" forHTTPHeaderField:zumoApiVersionHeader];
        }
        
        // Set the installation id header
        [mutableRequest setValue:client.installId forHTTPHeaderField:xZumoInstallId];
        
        if ([request HTTPBody] &&
             ![request valueForHTTPHeaderField:contentTypeHeader]) {
            // Set the content type header
            [mutableRequest setValue:jsonContentType
                  forHTTPHeaderField:contentTypeHeader];
        }
    }
    
    [mutableRequest setValue:[MSSDKFeatures httpHeaderForFeatures:features] forHTTPHeaderField:MSFeaturesHeaderName];
    
    return mutableRequest;
}


@end
