//
//  APContactListBuilder 
//  AddressBook
//
//  Created by Alexey Belkevich on 06.10.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class APContact;

@interface APContactListBuilder : NSObject

@property (nonatomic, strong) BOOL (^filterBlock)(APContact *contact);
@property (nonatomic, strong) NSArray *sortDescriptors;

- (NSArray *)contactListWithAllContacts:(NSArray *)allContacts;

@end