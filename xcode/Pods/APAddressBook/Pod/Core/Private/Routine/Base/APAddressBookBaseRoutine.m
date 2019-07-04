//
//  APAddressBookBaseRoutine 
//  AddressBook
//
//  Created by Alexey Belkevich on 21.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import "APAddressBookBaseRoutine.h"
#import "APAddressBookRefWrapper.h"

@interface APAddressBookBaseRoutine ()
@property (nonatomic, strong) APAddressBookRefWrapper *wrapper;
@end

@implementation APAddressBookBaseRoutine

#pragma mark - life cycle

- (instancetype)initWithAddressBookRefWrapper:(APAddressBookRefWrapper *)wrapper
{
    self = [super init];
    self.wrapper = wrapper;
    return self;
}

@end