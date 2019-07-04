//
//  APContactBuilder 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/ABRecord.h>
#import "APTypes.h"

@class APContact;

@interface APContactBuilder : NSObject

- (APContact *)contactWithRecordRef:(ABRecordRef)recordRef fieldMask:(APContactField)fieldMask;

@end