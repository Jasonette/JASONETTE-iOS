/* Copyright 2017 Urban Airship and Contributors */

#import "UAAPIClient+Internal.h"
#import "UARequestSession+Internal.h"

#import "UAConfig.h"
#import "UAirship.h"

@interface UAAPIClient()
@property (nonatomic, strong) UAConfig *config;
@property (nonatomic, strong) UARequestSession *session;
@end

@implementation UAAPIClient

- (instancetype)initWithConfig:(UAConfig *)config session:(UARequestSession *)session {
    self = [super init];

    if (self) {
        self.config = config;
        self.session = session;
    }

    return self;
}

- (void)cancelAllRequests {
    [self.session cancelAllRequests];
}

- (void)dealloc {
    [self.session cancelAllRequests];
}

@end
