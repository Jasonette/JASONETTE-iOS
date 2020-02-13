//
//  APThread
//  APAddressBook
//
//  Created by Alexey Belkevich on 20.08.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APThread : NSThread

- (void)dispatchAsync:(void (^)(void))block;
- (void)dispatchSync:(void (^)(void))block;

@end
