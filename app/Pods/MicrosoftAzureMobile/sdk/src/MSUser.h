// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


#pragma mark * MSUser Public Interface


/// The *MSUser* class represents an end user that can login to a Microsoft Azure
/// Mobile Service on a client device.
@interface MSUser : NSObject <NSCopying>

#pragma mark * Public Initializers

///@name Initializing the MSUser Object
///@{

/// Initializes an *MSUser* instance with the given user id.
/// @param userId Unique identifier for the user
-(nonnull instancetype)initWithUserId:(nullable NSString *)userId;

///@}


///@name Retrieving User Data
///@{

#pragma mark * Public Readonly Properties

/// The user id of the end user.
@property (nonatomic, copy, readonly, nullable)   NSString *userId;


#pragma mark * Public Readwrite Properties

/// A Microsoft Azure Mobile Services authentication token for the logged in
/// end user. If non-nil, the authentication token will be included in all
/// requests made to the Microsoft Azure Mobile Service, allowing the client to
/// perform all actions on the Microsoft Azure Mobile Service that require
/// authenticated-user level permissions.
@property (nonatomic, copy, nullable)         NSString *mobileServiceAuthenticationToken;

///@}

@end
