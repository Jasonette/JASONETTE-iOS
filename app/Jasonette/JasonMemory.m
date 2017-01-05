//
//  JasonMemory.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonMemory.h"

@implementation JasonMemory
+ (JasonMemory*)client
{
    static dispatch_once_t predicate = 0;
    static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}
- (id)init {
    if (self = [super init]) {
        self._register = [[NSDictionary alloc] init];
        self._stack = [[NSDictionary alloc] init];
        self._caller = [[NSDictionary alloc] init];
        self.locked = NO;
    }
    return self;
}
- (void)setRegister:(id)value forKey: (NSString *)key{
    if(![key isEqualToString:@"$jason"]){
        NSMutableDictionary *temp_register = [self._register mutableCopy];
        temp_register[key] = value;
        self._register = temp_register;
    }
}
- (void)pop{
    // pops the stack so self.current_stack contains the next action to execute
    NSDictionary *callback = self._stack[@"success"];
    if(callback){
        self._stack = callback;
    } else {
        self._stack = @{};
    }
}
- (void)exception{
    NSDictionary *failure = self._stack[@"error"];
    if(failure){
        self._stack = failure;
    } else {
        self._stack = @{};
    }
}
@end
