//
//  APSocialServiceHelper 
//  AddressBook
//
//  Created by Alexey Belkevich on 22.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APTypes.h"

@interface APSocialServiceHelper : NSObject

+ (APSocialNetworkType)socialNetworkTypeWithString:(NSString *)string;

@end