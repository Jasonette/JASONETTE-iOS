// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSClient.h"
#import "MSSerializer.h"

@class MSConnectionDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface MSClient ()

// The serailizer to use with the client
@property (nonatomic, strong, readonly)         id<MSSerializer> serializer;
// The installation id used to track unique users of the sdk
@property (nonatomic, strong, readonly)         NSString* installId;

- (NSURL *) loginURL;

/**
 Connection delegate to manage data tasks with the urlSession
 */
@property (nonatomic, strong) MSConnectionDelegate *connectionDelegate;

/**
 Session instance to be used for all data tasks for this client instance
 */
@property (nonatomic, strong) NSURLSession *urlSession;

@end

NS_ASSUME_NONNULL_END
