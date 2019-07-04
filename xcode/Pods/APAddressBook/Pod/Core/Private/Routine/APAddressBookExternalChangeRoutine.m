//
//  APAddressBookExternalChangeRoutine
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "APAddressBookExternalChangeRoutine.h"
#import "APAddressBookRefWrapper.h"

void APAddressBookExternalChangeCallback(ABAddressBookRef addressBookRef, CFDictionaryRef __unused info, void *context);

@implementation APAddressBookExternalChangeRoutine

#pragma mark - life cycle

- (instancetype)initWithAddressBookRefWrapper:(APAddressBookRefWrapper *)wrapper
{
    self = [super initWithAddressBookRefWrapper:wrapper];
    if (!wrapper.error)
    {
        [self registerExternalChangeCallback];
    }
    return self;
}

- (void)dealloc
{
    if (!self.wrapper.error)
    {
        [self unregisterExternalChangeCallback];
    }
}

#pragma mark - private

- (void)registerExternalChangeCallback
{
    ABAddressBookRegisterExternalChangeCallback(self.wrapper.ref, APAddressBookExternalChangeCallback,
                                                (__bridge void *)(self));
}

- (void)unregisterExternalChangeCallback
{
    ABAddressBookUnregisterExternalChangeCallback(self.wrapper.ref, APAddressBookExternalChangeCallback,
                                                  (__bridge void *)(self));
}

#pragma mark - external change callback

void APAddressBookExternalChangeCallback(ABAddressBookRef addressBookRef, CFDictionaryRef __unused info, void *context)
{
    ABAddressBookRevert(addressBookRef);
    APAddressBookExternalChangeRoutine *routine = (__bridge APAddressBookExternalChangeRoutine *)(context);
    [routine.delegate addressBookDidChange];
}

@end