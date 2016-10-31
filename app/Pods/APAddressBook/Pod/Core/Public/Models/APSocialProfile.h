//
//  APSocialContact.h
//  APAddressBook
//
//  Created by David on 2014-08-01.
//  Copyright (c) 2014 David Muzi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APTypes.h"

@interface APSocialProfile : NSObject

@property (nonatomic, assign) APSocialNetworkType socialNetwork;
@property (nullable, nonatomic, strong) NSString *username;
@property (nullable, nonatomic, strong) NSString *userIdentifier;
@property (nullable, nonatomic, strong) NSURL *url;

@end
