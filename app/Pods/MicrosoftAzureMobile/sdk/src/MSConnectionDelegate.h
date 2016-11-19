// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSClient;

// The |MSConnectionDelegate| is a private class that implements the
// |NSURLSessionDataDelegate| and surfaces success and error blocks. It
// is used only by the |MSClientConnection|.
@interface MSConnectionDelegate : NSObject <NSURLSessionDataDelegate>

- (instancetype)init NS_UNAVAILABLE;

/**
 Initialize the connection delegate for the client

 @param client The client instance for this delegate to be associated with
 */
- (instancetype)initWithClient:(MSClient *)client NS_DESIGNATED_INITIALIZER;

/**
 The client instance associated with the delegate
 */
@property (nonatomic, strong) MSClient *client;

@property (nonatomic, strong, nullable) NSOperationQueue *completionQueue;

@end

NS_ASSUME_NONNULL_END
