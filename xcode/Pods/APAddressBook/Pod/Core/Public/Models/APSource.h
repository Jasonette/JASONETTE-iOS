//
//  APSource 
//  APAddressBook
//
//  Created by Alexey Belkevich on 23.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APSource : NSObject

@property (nonnull, nonatomic, strong) NSString *sourceType;
@property (nonnull, nonatomic, strong) NSNumber *sourceID;

@end