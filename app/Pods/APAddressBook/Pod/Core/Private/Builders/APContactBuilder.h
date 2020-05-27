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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@class APContact;

@interface APContactBuilder : NSObject

- (APContact *)contactWithRecordRef:(ABRecordRef)recordRef fieldMask:(APContactField)fieldMask;

@end

#pragma clang diagnostic pop