// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#include "MSQuery.h"
#include "MSSDKFeatures.h"

@interface MSQuery ()

#pragma mark * Private Read Methods
///@name Executing the query with
///@{

/// Executes the query by sending a request to the Microsoft Azure Mobile Service.
-(void)readInternalWithFeatures:(MSFeatures)features completion:(MSReadQueryBlock)completion;

///@}

@end