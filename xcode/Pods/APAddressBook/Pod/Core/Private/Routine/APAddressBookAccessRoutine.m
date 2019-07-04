//
//  APAddressBookAccessRoutine
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <AddressBook/ABAddressBook.h>
#import "APAddressBookAccessRoutine.h"
#import "APAddressBookRefWrapper.h"

@implementation APAddressBookAccessRoutine

#pragma mark - public

+ (APAddressBookAccess)accessStatus
{
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    switch (status)
    {
        case kABAuthorizationStatusDenied:
        case kABAuthorizationStatusRestricted:
            return APAddressBookAccessDenied;

        case kABAuthorizationStatusAuthorized:
            return APAddressBookAccessGranted;

        default:
            return APAddressBookAccessUnknown;
    }
}

- (void)requestAccessWithCompletion:(void (^)(BOOL granted, NSError *error))completionBlock
{
    if (!self.wrapper.error)
    {
        ABAddressBookRequestAccessWithCompletion(self.wrapper.ref, ^(bool granted, CFErrorRef error)
        {
            completionBlock ? completionBlock(granted, (__bridge NSError *)error) : nil;
        });
    }
    else
    {
        completionBlock ? completionBlock(NO, self.wrapper.error) : nil;
    }
}

@end