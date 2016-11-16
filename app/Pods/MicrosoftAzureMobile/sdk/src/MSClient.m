// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSClientInternal.h"
#import "MSTable.h"
#import "MSClientConnection.h"
#import "MSLogin.h"
#import "MSUser.h"
#import "MSAPIRequest.h"
#import "MSAPIConnection.h"
#import "MSJSONSerializer.h"
#import "MSSyncContextInternal.h"
#import "MSSyncTable.h"
#import "MSPush.h"
#import "MSConnectionDelegate.h"

#pragma mark * MSClient Private Interface


@interface MSClient ()

// Public readonly, private readwrite properties
@property (nonatomic, strong, readwrite) NSArray<id<MSFilter>> *filters;

// Private properties
@property (nonatomic, strong, readonly) MSLogin *login;

@end


#pragma mark * MSClient Implementation


@implementation MSClient

- (void) setSyncContext:(MSSyncContext *)syncContext
{
    _syncContext = syncContext;
    if (syncContext) {
        _syncContext.client = self;
    }
}

@synthesize installId = installId_;
-(NSString *) installId
{
    if(!installId_) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        installId_ = [defaults stringForKey:@"WindowsAzureMobileServicesInstallationId"];
        if(!installId_) {
            CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
            installId_ = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, newUUID);
            CFRelease(newUUID);
        
            //store the install ID so we don't generate a new one next time
            [defaults setObject:installId_ forKey:@"WindowsAzureMobileServicesInstallationId"];
            [defaults synchronize];
        }
    }
    
    return installId_;
}

#pragma mark * Public Static Constructor Methods


+(MSClient *) clientWithApplicationURLString:(NSString *)urlString
{
    // NSURL will be nil for non-percent escaped url strings so we have to percent escape here
    NSMutableCharacterSet *set = [[NSCharacterSet URLPathAllowedCharacterSet] mutableCopy];
    [set formUnionWithCharacterSet:[NSCharacterSet URLHostAllowedCharacterSet]];
    [set formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *appUrlStringEncoded = [urlString stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSURL *url = [NSURL URLWithString:appUrlStringEncoded];
    
    return [MSClient clientWithApplicationURL:url];
    
}

+(MSClient *) clientWithApplicationURL:(NSURL *)url
{
    return [[MSClient alloc] initWithApplicationURL:url];
}

#pragma mark * Public Initializer Methods


-(id) initWithApplicationURL:(NSURL *)url
{
    self = [super init];
    if(self)
    {
        _applicationURL = url;
        _login = [[MSLogin alloc] initWithClient:self];
        _push = [[MSPush alloc] initWithClient:self];
        _connectionDelegate = [[MSConnectionDelegate alloc] initWithClient:self];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:configuration
                                                    delegate:self.connectionDelegate
                                               delegateQueue:nil];
    }
    return self;
}

@synthesize loginHost = _loginHost;
-(void) setLoginHost:(NSURL *)loginHost
{
    if (loginHost.path.length > 0) {
        @throw [NSException exceptionWithName:@"InvalidLoginHost"
                                       reason:[NSString stringWithFormat:@"Login host should not include a path portion"]
                                     userInfo:nil];
    }

    if (![loginHost.scheme isEqualToString:@"https"]) {
        @throw [NSException exceptionWithName:@"InvalidLoginHost"
                                       reason:[NSString stringWithFormat:@"Login host must use the https scheme"]
                                     userInfo:nil];
    }
    
    _loginHost = loginHost;
}

-(NSURL *)loginHost
{
    if (_loginHost == nil) {
        NSString *host = [self.applicationURL.host stringByAddingPercentEncodingWithAllowedCharacters:
                                [NSCharacterSet URLHostAllowedCharacterSet]];
        
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", host]];
    }
    
    return _loginHost;
}

@synthesize loginPrefix = _loginPrefix;
- (void) setLoginPrefix:(NSString *)loginPrefix
{
    _loginPrefix = [loginPrefix stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
}

-(NSString *) loginPrefix
{
    if (!_loginPrefix) {
        _loginPrefix = @".auth/login";
    }
    return _loginPrefix;
}

- (NSURL *) loginURL
{
    return [self.loginHost URLByAppendingPathComponent:self.loginPrefix];
}


#pragma mark * Public Filter Methods


-(MSClient *) clientWithFilter:(id<MSFilter>)filter
{
    // Create a deep copy of the client (except for the filters)
    MSClient *newClient = [self copy];
    
    // Filter clients should inherit the same sync context
    newClient.syncContext = self.syncContext;
    
    // Either copy or create a new filters array
    NSMutableArray *filters = [self.filters mutableCopy];
    if (!filters) {
        filters = [NSMutableArray arrayWithCapacity:1];
    }
    
    // Add the filter to the filters array
    [filters addObject:filter];
    
    // Set the new filters on the copied client
    newClient.filters = filters;
    
    newClient.connectionDelegateQueue = self.connectionDelegateQueue;
    
    return newClient;
}


#pragma mark * Public Authentication Methods


#if TARGET_OS_IPHONE
-(void) loginWithProvider:(NSString *)provider
             controller:(UIViewController *)controller
                 animated:(BOOL)animated
               completion:(nullable MSClientLoginBlock)completion
{
    return [self.login loginWithProvider:provider
                              parameters:nil
                              controller:controller
                                animated:animated
                              completion:completion];
}

-(void)loginWithProvider:(nonnull NSString *)provider
              parameters:(nullable NSDictionary *)parameters
              controller:(nonnull UIViewController *)controller
                animated:(BOOL)animated
              completion:(nullable MSClientLoginBlock)completion
{
    return [self.login loginWithProvider:provider
                              parameters:parameters
                              controller:controller
                                animated:animated
                              completion:completion];
}

-(MSLoginController *) loginViewControllerWithProvider:(NSString *)provider
                                      completion:(nullable MSClientLoginBlock)completion
{
    return [self.login loginViewControllerWithProvider:provider
                                            parameters:nil
                                            completion:completion];
}
#endif

-(void) loginWithProvider:(NSString *)provider
                token:(NSDictionary *)token
               completion:(MSClientLoginBlock)completion;
{
   return [self.login loginWithProvider:provider
                              token:token
                             completion:completion];
}

-(void)logoutWithCompletion:(nullable MSClientLogoutBlock)completion;
{
    self.currentUser = nil;
    
    // TODO: Rewrite to actually call the server and invalidate the token
    if (completion) {
        completion(nil);
    }
}

-(void)refreshUserWithCompletion:(nullable MSClientLoginBlock)completion
{
    return [self.login refreshUserWithCompletion:completion];
}

#pragma mark * Public Table Constructor Methods

-(MSTable *) tableWithName:(NSString *)tableName
{
    return [[MSTable alloc] initWithName:tableName client:self];
}

-(MSTable *) getTable:(NSString *)tableName
{
    return [self tableWithName:tableName];
}

-(MSSyncTable *) syncTableWithName:(NSString *)tableName
{
    return [[MSSyncTable alloc] initWithName:tableName client:self];
}

#pragma mark * Public invokeAPI Methods


-(void)invokeAPI:(NSString *)APIName
            body:(id)body
      HTTPMethod:(NSString *)method
      parameters:(NSDictionary *)parameters
         headers:(NSDictionary *)headers
      completion:(MSAPIBlock)completion
{
    // Create the request
    MSAPIRequest *request = [MSAPIRequest requestToinvokeAPI:APIName
                                                      client:self
                                                        body:body
                                                  HTTPMethod:method
                                                  parameters:parameters
                                                     headers:headers
                                                  completion:completion];
    // Send the request
    if (request) {
        MSAPIConnection *connection =
            [MSAPIConnection connectionWithApiRequest:request
                                               client:self
                                               completion:completion];
        [connection start];
    }
}

-(void)invokeAPI:(NSString *)APIName
            data:(NSData *)data
      HTTPMethod:(NSString *)method
      parameters:(NSDictionary *)parameters
         headers:(NSDictionary *)headers
      completion:(MSAPIDataBlock)completion
{
    // Create the request
    MSAPIRequest *request = [MSAPIRequest requestToinvokeAPI:APIName
                                                      client:self
                                                        data:data
                                                  HTTPMethod:method
                                                  parameters:parameters
                                                     headers:headers
                                                  completion:completion];
    // Send the request
    if (request) {
        MSAPIConnection *connection =
        [MSAPIConnection connectionWithApiDataRequest:request
                                               client:self
                                       completion:completion];
        [connection start];
    }
}


#pragma mark * NSCopying Methods


-(id) copyWithZone:(NSZone *)zone
{
    MSClient *client = [[MSClient allocWithZone:zone] initWithApplicationURL:self.applicationURL];
    
    client.currentUser = [self.currentUser copyWithZone:zone];
    client.filters = [self.filters copyWithZone:zone];

    return client;
}


#pragma mark * Private Methods


-(id<MSSerializer>) serializer
{
    // Just use a hard coded reference to MSJSONSerializer
    return [MSJSONSerializer JSONSerializer];
}

- (void)setConnectionDelegateQueue:(NSOperationQueue *)connectionDelegateQueue
{
    if (connectionDelegateQueue != _connectionDelegateQueue)
    {
        _connectionDelegateQueue = connectionDelegateQueue;
        // Pass the queue through to the connection delegate so the completion handler gets called on this queue
        self.connectionDelegate.completionQueue = connectionDelegateQueue;
    }
}

@end
