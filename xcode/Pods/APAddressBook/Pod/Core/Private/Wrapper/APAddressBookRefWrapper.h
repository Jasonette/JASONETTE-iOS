//
//  APAddressBookRefWrapper 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface APAddressBookRefWrapper : NSObject

@property (nonatomic, readonly) ABAddressBookRef ref;
@property (nonatomic, readonly) NSError *error;

@end

#pragma clang diagnostic pop