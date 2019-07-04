//
//  APThread
//  APAddressBook
//
//  Created by Alexey Belkevich on 20.08.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import "APThread.h"

@implementation APThread

#pragma mark - public

- (void)dispatchAsync:(void (^)())block
{
    [self performSelector:@selector(performBlock:) onThread:self withObject:block waitUntilDone:NO];
}

- (void)dispatchSync:(void (^)())block
{
    [self performSelector:@selector(performBlock:) onThread:self withObject:block waitUntilDone:YES];
}

#pragma mark - override

- (void)main
{
    while (!self.cancelled)
    {
        @autoreleasepool
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
        }
        
    }
}

#pragma mark - private

- (void)performBlock:(void (^)())block
{
    block();
}

@end