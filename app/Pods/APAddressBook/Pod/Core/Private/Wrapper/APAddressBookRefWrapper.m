//
//  APAddressBookRefWrapper 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import "APAddressBookRefWrapper.h"

@interface APAddressBookRefWrapper ()
{
    ABAddressBookRef ref;
}
@property (nonatomic, strong) NSError *error;
@end

@implementation APAddressBookRefWrapper

#pragma mark - life cycle

- (id)init
{
    self = [super init];
    CFErrorRef error = NULL;
    ref = ABAddressBookCreateWithOptions(NULL, &error);
    if (error)
    {
        self.error = (__bridge NSError *)(error);
    }
    return self;
}

- (void)dealloc
{
    if (ref)
    {
        CFRelease(ref);
    }
}

#pragma mark - properties

- (ABAddressBookRef)ref
{
    return ref;
}

@end