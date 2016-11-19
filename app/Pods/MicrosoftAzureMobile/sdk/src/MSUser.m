// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSUser.h"


#pragma mark * MSUser Implementation


@implementation MSUser

@synthesize userId = userId_;
@synthesize mobileServiceAuthenticationToken = mobileServiceAuthenticationToken_;


#pragma mark * Public Initializer Methods


-(id) initWithUserId:(NSString *)userId
{
    self = [super init];
    if(self)
    {
        userId_ = userId;
    }
    return self;
}


#pragma mark * NSCopying Methods


-(id) copyWithZone:(NSZone *)zone
{
    MSUser *user = [[MSUser allocWithZone:zone] initWithUserId:self.userId];
    user.mobileServiceAuthenticationToken = self.mobileServiceAuthenticationToken;
    
    return user;
}

@end
