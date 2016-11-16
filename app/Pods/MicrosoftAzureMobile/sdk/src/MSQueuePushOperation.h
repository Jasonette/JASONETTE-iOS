// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@class MSSyncContext;

/// Performs all actions associated with a push operation including, sending each operation to
/// the server, processing errors, and triggering the appropriate calls to the delegate, datasource,
/// and callbacks
@interface MSQueuePushOperation : NSOperation {
    BOOL executing_;
    BOOL finished_;
}

- (id) initWithSyncContext:(MSSyncContext *)syncContext
             dispatchQueue:(dispatch_queue_t)dispatchQueue
             callbackQueue:(NSOperationQueue *)callbackQueue
                completion:(MSSyncBlock)completion;

@end