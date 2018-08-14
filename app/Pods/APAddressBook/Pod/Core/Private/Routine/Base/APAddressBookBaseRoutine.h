//
//  APAddressBookBaseRoutine 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class APAddressBookRefWrapper;

@interface APAddressBookBaseRoutine : NSObject

@property (nonatomic, readonly) APAddressBookRefWrapper *wrapper;

- (instancetype)initWithAddressBookRefWrapper:(APAddressBookRefWrapper *)wrapper;

@end