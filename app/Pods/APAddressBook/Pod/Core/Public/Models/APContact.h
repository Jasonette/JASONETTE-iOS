//
//  APContact.h
//  APAddressBook
//
//  Created by Alexey Belkevich on 1/10/14.
//  Copyright (c) 2014 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "APName.h"
#import "APJob.h"
#import "APPhone.h"
#import "APEmail.h"
#import "APAddress.h"
#import "APSocialProfile.h"
#import "APRelatedPerson.h"
#import "APSource.h"
#import "APRecordDate.h"
#import "APContactDate.h"

@interface APContact : NSObject

@property (nonnull, nonatomic, strong) NSNumber *recordID;
@property (nullable, nonatomic, strong) APName *name;
@property (nullable, nonatomic, strong) APJob *job;
@property (nullable, nonatomic, strong) UIImage *thumbnail;
@property (nullable, nonatomic, strong) NSArray <APPhone *> *phones;
@property (nullable, nonatomic, strong) NSArray <APEmail *> *emails;
@property (nullable, nonatomic, strong) NSArray <APAddress *> *addresses;
@property (nullable, nonatomic, strong) NSArray <APSocialProfile *> *socialProfiles;
@property (nullable, nonatomic, strong) NSDate *birthday;
@property (nullable, nonatomic, strong) NSString *note;
@property (nullable, nonatomic, strong) NSArray <NSString *> *websites;
@property (nullable, nonatomic, strong) NSArray <APRelatedPerson *> *relatedPersons;
@property (nullable, nonatomic, strong) NSArray <NSNumber *> *linkedRecordIDs;
@property (nullable, nonatomic, strong) APSource *source;
@property (nullable, nonatomic, strong) NSArray <APContactDate *> *dates;
@property (nullable, nonatomic, strong) APRecordDate *recordDate;

@end
