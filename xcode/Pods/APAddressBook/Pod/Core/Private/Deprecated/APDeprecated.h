//
//  APDeprecated.h
//  AddressBook
//
//  Created by Alexey Belkevich on 05.01.16.
//  Copyright (c) 2016 alterplay. All rights reserved.
//

#define AP_DEPRECATED(_useInstead) __attribute__((deprecated("Use " #_useInstead " instead")))