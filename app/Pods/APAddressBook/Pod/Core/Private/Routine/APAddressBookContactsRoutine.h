//
//  APAddressBookContactsRoutine 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "APAddressBookBaseRoutine.h"
#import "APTypes.h"

@class APContact;

@interface APAddressBookContactsRoutine : APAddressBookBaseRoutine

- (NSArray *)allContactsWithContactFieldMask:(APContactField)fieldMask;
- (APContact *)contactByRecordID:(NSNumber *)recordID withFieldMask:(APContactField)fieldMask;
- (UIImage *)imageWithRecordID:(NSNumber *)recordID;

@end