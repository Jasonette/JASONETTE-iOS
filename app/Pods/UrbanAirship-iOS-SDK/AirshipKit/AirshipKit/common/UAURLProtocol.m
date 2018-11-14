/* Copyright 2017 Urban Airship and Contributors */

#import "UAURLProtocol.h"
#import "UAirship.h"
#import "UAConfig.h"

@interface UAURLProtocol()
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@end

@implementation UAURLProtocol

static NSMutableSet *cachableURLs_ = nil;
static NSURLCache *cache_ = nil;

+ (void) load {
    cachableURLs_ = [NSMutableSet set];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // Reject non GET requests
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        return NO;
    }

    // Reject any non HTTP or HTTPS requests
    if (![request.URL.scheme isEqualToString:@"http"] && ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }

    // Make sure its cachabable URL
    return [[self cachableURLs] containsObject:request.URL] || [[self cachableURLs] containsObject:request.mainDocumentURL];
}

+ (NSMutableSet *)cachableURLs {
    return cachableURLs_;
}

+ (NSURLCache *)cache {
    static dispatch_once_t onceToken_;
    dispatch_once(&onceToken_, ^{
        cache_ = [[NSURLCache alloc] initWithMemoryCapacity:kUACacheMemorySizeInBytes
                                               diskCapacity:[UAirship shared].config.cacheDiskSizeInMB * 1024 * 1024
                                                   diskPath:@"UAURLCache"];
    });

    return cache_;
}

+ (void)clearCache {
    [[self cache] removeAllCachedResponses];
}

+ (void)addCachableURL:(NSURL *)url {
    [[self cachableURLs] addObject:url];
}

+ (void)removeCachableURL:(NSURL *)url {
    [[self cachableURLs] removeObject:url];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    __weak UAURLProtocol *weakSelf = self;

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.URLCache = [UAURLProtocol cache];
    config.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    self.dataTask = [session dataTaskWithRequest:self.request
                           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                               UAURLProtocol *strongSelf = weakSelf;

                               if (error) {
                                   // Try to force it to load from cache
                                   if (![self loadFromCache]) {
                                       [strongSelf.client URLProtocol:strongSelf didFailWithError:error];
                                   }

                                   return;
                               }

                               [self finishRequestWithResponse:response responseData:data];
                           }];

    [self.dataTask resume];
}

- (void)stopLoading {
    [self.dataTask cancel];
}

- (BOOL)loadFromCache {
    NSCachedURLResponse *cachedResponse = [[UAURLProtocol cache] cachedResponseForRequest:self.request];
    if (cachedResponse) {
        UA_LTRACE(@"Loading response from cache.");
        [self finishRequestWithResponse:cachedResponse.response responseData:cachedResponse.data];
        return YES;
    }

    return NO;
}

- (void)finishRequestWithResponse:(NSURLResponse *)response responseData:(NSData *)data {
    // NSURLCacheStorageNotAllowed - we handle the caching
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

@end
