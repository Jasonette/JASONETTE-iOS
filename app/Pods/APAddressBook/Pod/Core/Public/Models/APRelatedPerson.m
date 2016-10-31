//
//  APPhone.m
//  APAddressBook
//
//  Created by John Hobbs on 2/7/14.
//  Copyright (c) 2014 alterplay. All rights reserved.
//

#import "APRelatedPerson.h"

@implementation APRelatedPerson

#pragma mark - overrides

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@) - %@", self.localizedLabel, self.originalLabel, self.name];
}

@end
