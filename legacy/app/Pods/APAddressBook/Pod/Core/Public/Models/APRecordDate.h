//
//  APRecordDate
//  APAddressBook
//
//  Created by Alexey Belkevich on 05.10.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APRecordDate : NSObject

@property (nonnull, nonatomic, strong) NSDate *creationDate;
@property (nonnull, nonatomic, strong) NSDate *modificationDate;

@end