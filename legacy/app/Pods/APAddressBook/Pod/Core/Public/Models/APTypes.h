//
//  APTypes.h
//  APAddressBook
//
//  Created by Alexey Belkevich on 1/11/14.
//  Copyright (c) 2014 alterplay. All rights reserved.
//

#import "APDeprecated.h"

typedef NS_ENUM(NSUInteger, APAddressBookAccess)
{
    APAddressBookAccessUnknown = 0,
    APAddressBookAccessGranted = 1,
    APAddressBookAccessDenied  = 2
};

typedef NS_OPTIONS(NSUInteger, APContactField)
{
    APContactFieldName                  = 1 << 0,
    APContactFieldJob                   = 1 << 1,
    APContactFieldThumbnail             = 1 << 2,
    APContactFieldPhonesOnly            = 1 << 3,
    APContactFieldPhonesWithLabels      = 1 << 4,
    APContactFieldEmailsOnly            = 1 << 5,
    APContactFieldEmailsWithLabels      = 1 << 6,
    APContactFieldAddressesWithLabels   = 1 << 7,
    APContactFieldAddressesOnly         = 1 << 8,
    APContactFieldAddresses AP_DEPRECATED('APContactFieldAddressesOnly') = APContactFieldAddressesOnly,
    APContactFieldSocialProfiles        = 1 << 9,
    APContactFieldBirthday              = 1 << 10,
    APContactFieldWebsites              = 1 << 11,
    APContactFieldNote                  = 1 << 12,
    APContactFieldRelatedPersons        = 1 << 13,
    APContactFieldLinkedRecordIDs       = 1 << 14,
    APContactFieldSource                = 1 << 15,
    APContactFieldDates                 = 1 << 16,
    APContactFieldRecordDate            = 1 << 17,
    APContactFieldDefault               = APContactFieldName | APContactFieldPhonesOnly,
    APContactFieldAll                   = 0xFFFFFFFF
};

typedef NS_ENUM(NSUInteger, APSocialNetworkType)
{
    APSocialNetworkUnknown = 0,
    APSocialNetworkFacebook = 1,
    APSocialNetworkTwitter = 2,
    APSocialNetworkLinkedIn = 3,
    APSocialNetworkFlickr = 4,
    APSocialNetworkGameCenter = 5
};