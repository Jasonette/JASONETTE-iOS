//
//  APContactListBuilder 
//  AddressBook
//
//  Created by Alexey Belkevich on 06.10.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import "APContactListBuilder.h"
#import "APContact.h"

@implementation APContactListBuilder

#pragma mark - public

- (NSArray *)contactListWithAllContacts:(NSArray *)allContacts
{
    NSMutableArray *mutableContacts = allContacts.mutableCopy;
    [self filterContacts:mutableContacts];
    [self sortContacts:mutableContacts];
    return mutableContacts.copy;
}

#pragma mark - private

- (void)filterContacts:(NSMutableArray *)contacts
{
    if (self.filterBlock)
    {
        NSPredicate *predicate;
        predicate = [NSPredicate predicateWithBlock:^BOOL(APContact *contact, NSDictionary *bindings)
        {
            return self.filterBlock(contact);
        }];
        [contacts filterUsingPredicate:predicate];
    }
}

- (void)sortContacts:(NSMutableArray *)contacts
{
    if (self.sortDescriptors)
    {
        [contacts sortUsingDescriptors:self.sortDescriptors];
    }
}

@end