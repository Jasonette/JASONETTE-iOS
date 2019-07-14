//
//  NSArray+NBAdditions.h
//  libPhoneNumber
//
//  Created by Dave MacLachlan on 2/7/17.
//  Copyright © 2017 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (NBAdditions)
- (id)nb_safeObjectAtIndex:(NSUInteger)index class:(Class)clazz;
- (NSString *)nb_safeStringAtIndex:(NSUInteger)index;
- (NSNumber *)nb_safeNumberAtIndex:(NSUInteger)index;
- (NSArray *)nb_safeArrayAtIndex:(NSUInteger)index;
- (NSData *)nb_safeDataAtIndex:(NSUInteger)index;
@end
