//
//  APImageExtractor 
//  AddressBook
//
//  Created by Alexey Belkevich on 29.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


@interface APImageExtractor : NSObject

+ (UIImage *)thumbnailWithRecordRef:(ABRecordRef)recordRef;
+ (UIImage *)photoWithRecordRef:(ABRecordRef)recordRef;

@end

#pragma clang diagnostic pop