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
    ABAddressBookRequestAccessWithCompletion(self.wrapper.ref, ^(bool granted, CFErrorRef errorRef)
    {
        NSError *error = (__bridge NSError *)errorRef;
        if (!error && !granted)
        {
            error = self.accessDeniedError;
        }
        completionBlock ? completionBlock(granted, error) : nil;
    });
}

#pragma mark - Private

- (NSError *)accessDeniedError
{
    NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey:
                               @"Address book access has been denied by user"};
    return [[NSError alloc] initWithDomain:@"APAddressBookErrorDomain" code:101 userInfo:userInfo];
}

@end