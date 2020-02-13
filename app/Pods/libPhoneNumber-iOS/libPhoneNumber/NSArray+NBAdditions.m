//
//  NSArray+NBAdditions.m
//  libPhoneNumber
//
//  Created by Dave MacLachlan on 2/7/17.
//  Copyright © 2017 ohtalk.me. All rights reserved.
//

#import "NSArray+NBAdditions.h"

@implementation NSArray (NBAdditions)

- (id)nb_safeObjectAtIndex:(NSUInteger)index class:(Class)clazz {
  if (index >= self.count) {
    return nil;
  }
  id res = [self objectAtIndex:index];
  if (![res isKindOfClass:clazz]) {
    return nil;
  }
  return res;
}

    - (NSString *)nb_safeStringAtIndex : (NSUInteger)index {
  return [self nb_safeObjectAtIndex:index class:[NSString class]];
}

- (NSNumber *)nb_safeNumberAtIndex:(NSUInteger)index {
  return [self nb_safeObjectAtIndex:index class:[NSNumber class]];
}
- (NSArray *)nb_safeArrayAtIndex:(NSUInteger)index {
  return [self nb_safeObjectAtIndex:index class:[NSArray class]];
}

- (NSData *)nb_safeDataAtIndex:(NSUInteger)index {
  return [self nb_safeObjectAtIndex:index class:[NSData class]];
}

@end
