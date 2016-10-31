//
//  APContactDataExtractor 
//  AddressBook
//
//  Created by Alexey Belkevich on 22.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@class APName;
@class APJob;
@class APSource;
@class APRecordDate;

@interface APContactDataExtractor : NSObject

@property (nonatomic, assign) ABRecordRef recordRef;

- (APName *)name;
- (APJob *)job;
- (NSArray *)phonesWithLabels:(BOOL)needLabels;
- (NSArray *)emailsWithLabels:(BOOL)needLabels;
- (NSArray *)addressesWithLabels:(BOOL)labels;
- (NSArray *)socialProfiles;
- (NSArray *)relatedPersons;
- (NSArray *)linkedRecordIDs;
- (APSource *)source;
- (NSArray *)dates;
- (APRecordDate *)recordDate;
- (NSString *)stringProperty:(ABPropertyID)property;
- (NSArray *)arrayProperty:(ABPropertyID)property;
- (NSDate *)dateProperty:(ABPropertyID)property;

@end