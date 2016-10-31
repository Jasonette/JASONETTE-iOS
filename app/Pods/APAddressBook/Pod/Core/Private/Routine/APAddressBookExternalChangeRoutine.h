//
//  APAddressBookExternalChangeRoutine
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APAddressBookBaseRoutine.h"
#import "APAddressBookExternalChangeDelegate.h"

@interface APAddressBookExternalChangeRoutine : APAddressBookBaseRoutine

@property (nonatomic, weak) NSObject <APAddressBookExternalChangeDelegate> *delegate;

@end