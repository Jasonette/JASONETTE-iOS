//
//  APAddressBookExternalChangeDelegate
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol APAddressBookExternalChangeDelegate <NSObject>

- (void)addressBookDidChange;

@end