/* Copyright 2017 Urban Airship and Contributors */

#import "UAURLRequestOperation+Internal.h"


@interface UAURLRequestOperation()

@property (nonatomic, copy) NSURLSessionTask *task;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, copy) void (^completionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);
@end

@implementation UAURLRequestOperation


- (instancetype)initWithRequest:(NSURLRequest *)request
                       sesssion:(NSURLSession *)session
              completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {

    self = [super init];
    if (self) {
        self.session = session;
        self.request = request;
        self.completionHandler = completionHandler;
    }
    return self;
}

+ (instancetype)operationWithRequest:(NSURLRequest *)request
                            session:(NSURLSession *)session
                   completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {

    return [[UAURLRequestOperation alloc] initWithRequest:request sesssion:session completionHandler:completionHandler];
}

- (void)startAsyncOperation {
    self.task = [self.session dataTaskWithRequest:self.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        @synchronized (self) {
            if (!self.isCancelled && self.completionHandler) {
                self.completionHandler(data, response, error);
            }
        }

        [self finish];
    }];

    [self.task resume];
}

- (void)finish {
    @synchronized (self) {
        self.task = nil;
        self.completionHandler = nil;
        self.request = nil;
        self.session = nil;
    }

    [super finish];
}

- (void)dealloc {
    [self.task cancel];
}

@end

