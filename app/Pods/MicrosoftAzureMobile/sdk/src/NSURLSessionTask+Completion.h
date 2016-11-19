// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@interface NSURLSessionTask(Completion)

/**
 Completion block to be executed on task being completed
 */
@property (nonatomic) MSResponseBlock completion;

/**
 Data instance used for appending when receiving new data through task
 */
@property (nonatomic) NSMutableData *data;
@end
