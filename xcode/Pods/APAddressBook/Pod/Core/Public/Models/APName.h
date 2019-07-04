//
//  APName 
//  APAddressBook
//
//  Created by Alexey Belkevich on 05.10.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APName : NSObject

@property (nullable, nonatomic, strong) NSString *firstName;
@property (nullable, nonatomic, strong) NSString *lastName;
@property (nullable, nonatomic, strong) NSString *middleName;
@property (nullable, nonatomic, strong) NSString *compositeName;

@end