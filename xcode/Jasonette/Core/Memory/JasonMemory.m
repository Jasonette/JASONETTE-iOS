//
//  JasonMemory.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonMemory.h"
#import "JasonLogger.h"

@implementation JasonMemory

+ (JasonMemory *)client
{
    // This follows the singleton pattern
    static dispatch_once_t predicate = 0;
    static id sharedObject = nil;

    dispatch_once (&predicate, ^{
        DTLogDebug (@"Initializing Internal Memory Client");
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (id)init
{
    if (self = [super init]) {
        self._register = @{};
        self._stack = @{};
        self._caller = @{};
        self.locked = NO;
    }

    return self;
}

- (void)setRegister:(id)value
             forKey:(NSString *)key
{
    if (![key isEqualToString:@"$jason"]) {
        DTLogDebug (@"Setting Register %@ for Key %@", value, key);
        NSMutableDictionary * temp_register = [self._register mutableCopy];
        temp_register[key] = value;
        self._register = temp_register;
    }
}

- (void)pop
{
    // pops the stack so self.current_stack contains the next action to execute
    NSDictionary * callback = self._stack[@"success"];

    self._stack = @{};

    if (callback) {
        DTLogDebug (@"Calling Next Action %@", callback);
        self._stack = callback;
    }
}

- (void)exception
{
    NSDictionary * failure = self._stack[@"error"];

    self._stack = @{};

    if (failure) {
        DTLogWarning (@"Got Failure %@", failure);
        self._stack = failure;
    }
}

@end
