//
//  APAddressBookRefWrapper 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface APAddressBookRefWrapper : NSObject

@property (nonatomic, readonly) ABAddressBookRef ref;
@property (nonatomic, readonly) NSError *error;

@end