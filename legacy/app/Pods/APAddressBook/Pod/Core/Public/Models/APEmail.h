//
//  APEmail.h
//  APAddressBook
//
//  Created by Sean Langley on 2015-03-18.
//  Copyright (c) 2015 Sean Langley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APEmail : NSObject

@property (nullable, nonatomic, strong) NSString *address;
@property (nullable, nonatomic, strong) NSString *originalLabel;
@property (nullable, nonatomic, strong) NSString *localizedLabel;

@end
