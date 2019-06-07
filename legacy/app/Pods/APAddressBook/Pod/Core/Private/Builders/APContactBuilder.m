//
//  APContactBuilder 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import "APContactBuilder.h"
#import "APContactDataExtractor.h"
#import "APContact.h"
#import "APImageExtractor.h"

@interface APContactBuilder ()
@property (nonatomic, strong) APContactDataExtractor *extractor;
@end

@implementation APContactBuilder

#pragma mark - life cycle

- (instancetype)init
{
    self = [super init];
    self.extractor = [[APContactDataExtractor alloc] init];
    return self;
}

#pragma mark - public

- (APContact *)contactWithRecordRef:(ABRecordRef)recordRef fieldMask:(APContactField)fieldMask
{
    self.extractor.recordRef = recordRef;
    APContact *contact = [[APContact alloc] init];
    contact.recordID = @(ABRecordGetRecordID(recordRef));
    if (fieldMask & APContactFieldName)
    {
        contact.name = [self.extractor name];
    }
    if (fieldMask & APContactFieldJob)
    {
        contact.job = [self.extractor job];
    }
    if (fieldMask & APContactFieldThumbnail)
    {
        contact.thumbnail = [APImageExtractor thumbnailWithRecordRef:recordRef];
    }
    if (fieldMask & APContactFieldPhonesOnly || fieldMask & APContactFieldPhonesWithLabels)
    {
        contact.phones = [self.extractor phonesWithLabels:(fieldMask & APContactFieldPhonesWithLabels)];
    }
    if (fieldMask & APContactFieldEmailsOnly || fieldMask & APContactFieldEmailsWithLabels)
    {
        contact.emails = [self.extractor emailsWithLabels:(fieldMask & APContactFieldEmailsWithLabels)];
    }
    if (fieldMask & APContactFieldAddressesOnly || fieldMask & APContactFieldAddressesWithLabels)
    {
        contact.addresses = [self.extractor addressesWithLabels:(fieldMask & APContactFieldAddressesWithLabels)];
    }
    if (fieldMask & APContactFieldSocialProfiles)
    {
        contact.socialProfiles = [self.extractor socialProfiles];
    }
    if (fieldMask & APContactFieldBirthday)
    {
        contact.birthday = [self.extractor dateProperty:kABPersonBirthdayProperty];
    }
    if (fieldMask & APContactFieldWebsites)
    {
        contact.websites = [self.extractor arrayProperty:kABPersonURLProperty];
    }
    if (fieldMask & APContactFieldNote)
    {
        contact.note = [self.extractor stringProperty:kABPersonNoteProperty];
    }
    if (fieldMask & APContactFieldRelatedPersons)
    {
        contact.relatedPersons = [self.extractor relatedPersons];
    }
    if (fieldMask & APContactFieldLinkedRecordIDs)
    {
        contact.linkedRecordIDs = [self.extractor linkedRecordIDs];
    }
    if (fieldMask & APContactFieldSource)
    {
        contact.source = [self.extractor source];
    }
    if (fieldMask & APContactFieldDates)
    {
        contact.dates = [self.extractor dates];
    }
    if (fieldMask & APContactFieldRecordDate)
    {
        contact.recordDate = [self.extractor recordDate];
    }
    return contact;
}

@end