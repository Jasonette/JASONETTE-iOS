// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#include "MSTable.h"
#include "MSSDKFeatures.h"

@interface MSTable ()

/// Features headers which should be sent for all requests from this table
@property (nonatomic) MSFeatures features;

/// Sends a request to the Microsoft Azure Mobile Service to return all items
/// from the table that meet the conditions of the given query, adding a features
/// header used for telemetry on the features used by this SDK.
-(void)readWithQueryStringInternal:(NSString *)queryString
                          features:(MSFeatures)features
                        completion:(MSReadQueryBlock)completion;

@end