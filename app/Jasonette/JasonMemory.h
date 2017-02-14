//
//  JasonMemory.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface JasonMemory : NSObject
@property (nonatomic, strong) NSDictionary *_stack;
@property (nonatomic, strong) NSDictionary *_register;
@property (nonatomic, strong) NSDictionary *_caller;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) BOOL need_to_exec;
@property (nonatomic, assign) BOOL executing;
+ (JasonMemory*)client;
- (void)pop;
- (void)exception;
- (void)setRegister:(id)value forKey: (NSString *)key;

@end
