//
//  APAddressBookContactsRoutine 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "APAddressBookContactsRoutine.h"
#import "APAddressBookRefWrapper.h"
#import "APContactBuilder.h"
#import "APImageExtractor.h"
#import "APContact.h"

@interface APAddressBookContactsRoutine ()
@property (nonatomic, strong) APContactBuilder *builder;
@end

@implementation APAddressBookContactsRoutine

#pragma mark - life cycle

- (instancetype)initWithAddressBookRefWrapper:(APAddressBookRefWrapper *)wrapper
{
    self = [super initWithAddressBookRefWrapper:wrapper];
    self.builder = [[APContactBuilder alloc] init];
    return self;
}

#pragma mark - public

- (NSArray *)allContactsWithContactFieldMask:(APContactField)fieldMask
{
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    if (!self.wrapper.error)
    {
        CFArrayRef peopleArrayRef = ABAddressBookCopyArrayOfAllPeople(self.wrapper.ref);
        CFIndex count = CFArrayGetCount(peopleArrayRef);
        for (CFIndex i = 0; i < count; i++)
        {
            ABRecordRef recordRef = CFArrayGetValueAtIndex(peopleArrayRef, i);
            APContact *contact = [self.builder contactWithRecordRef:recordRef fieldMask:fieldMask];
            [contacts addObject:contact];
        }
        CFRelease(peopleArrayRef);
    }
    return contacts.count > 0 ? contacts.copy : nil;
}

- (APContact *)contactByRecordID:(NSNumber *)recordID withFieldMask:(APContactField)fieldMask
{
    if (!self.wrapper.error)
    {
        ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(self.wrapper.ref, recordID.intValue);
        return recordRef != NULL ? [self.builder contactWithRecordRef:recordRef fieldMask:fieldMask] : nil;
    }
    return nil;
}

- (UIImage *)imageWithRecordID:(NSNumber *)recordID
{
    if (!self.wrapper.error)
    {
        ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(self.wrapper.ref, recordID.intValue);
        return recordRef != NULL ? [APImageExtractor photoWithRecordRef:recordRef] : nil;
    }
    return nil;
}

@end