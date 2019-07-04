//
//  APAddressBookAccessRoutine
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APAddressBookBaseRoutine.h"
#import "APTypes.h"

@interface APAddressBookAccessRoutine : APAddressBookBaseRoutine

- (void)requestAccessWithCompletion:(void (^)(BOOL granted, NSError *error))completionBlock;
+ (APAddressBookAccess)accessStatus;

@end