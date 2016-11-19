// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSConnectionDelegate.h"
#import "MSClient.h"
#import "NSURLSessionTask+Completion.h"

@implementation MSConnectionDelegate

# pragma mark * Public Initializer Methods

- (instancetype)initWithClient:(MSClient *)client
{
    if (self = [super init]) {
        self.client = client;
    }
    return self;
}

# pragma mark * NSURLSessionDataDelegate Methods

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    // We don't want to cache anything
    completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [dataTask.data appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSURLRequest *newRequest = nil;
    
    // Only follow redirects to the Microsoft Azure Mobile Service and not
    // to other hosts
    NSString *requestHost = request.URL.host;
    NSString *applicationHost = self.client.applicationURL.host;
    if ([applicationHost isEqualToString:requestHost])
    {
        newRequest = request;
    }
    
    completionHandler(newRequest);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    MSResponseBlock completion = task.completion;
    if (completion)
    {
        // Default to main queue if no explicit queue has been set
        NSOperationQueue *callQueue = self.completionQueue ?: [NSOperationQueue mainQueue];
        
        // Convert data so we pass an immutable version to the completion handler
        NSData *data = [NSData dataWithData:task.data];
        [callQueue addOperationWithBlock:^{
            completion((NSHTTPURLResponse *)task.response, data, error);
        }];
        [self cleanup:task];
    }
}

- (void)cleanup:(NSURLSessionTask *)task
{
    task.completion = nil;
    task.data = nil;
}

@end
