// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface MSQueryResult : NSObject

///@name Properties
///@{

/// The result from a successful read
@property (nonatomic, strong, readonly, nullable)           NSArray<NSDictionary *> *items;

/// there was not an error, then the *items* array will always be non-nil
/// If the query included a
/// request for the total count of items on the server (not just those returned
/// in *items* array), the *totalCount* will have this value; otherwise
/// *totalCount* will be -1.
@property (nonatomic, assign, readonly)         NSInteger totalCount;

/// if returned from the server, it will contain the link to next page of results
@property (nonatomic, strong, readonly, nullable)
    NSString *nextLink;
///@}

#pragma mark * Public Initializers

///@name Initializing the MSTable Object
///@{

/// Initializes an *MSTable* instance with the given name and client.
-(nonnull instancetype)initWithItems:(nullable NSArray<NSDictionary *> *)items
        totalCount:(NSInteger) totalCount
        nextLink: (nullable NSString *) nextLink;

///@}

@end
