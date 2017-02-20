//
//  JasonParser.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonParser.h"
#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@implementation JasonParser
- (void)format{
    NSDictionary *data = self.options[@"data"];
    id schema = self.options[@"template"];
    if(data && data.count > 0){
        NSString *path = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"js"];
        NSStringEncoding encoding;
        NSError *error = nil;
        NSString *js = [NSString stringWithContentsOfFile:path
                                               usedEncoding:&encoding
                                                      error:&error];
        
        JSContext *context = [[JSContext alloc] init];
        [context setExceptionHandler:^(JSContext *context, JSValue *value) {
            NSLog(@"%@", value);
        }];

        [context evaluateScript:js];
        JSValue *parse = context[@"parser"][@"json"];
        JSValue *val = [parse callWithArguments:@[schema, data]];
        @try{
            if([val isString]){
                [[Jason client] success: @{@"data": [val toString]}];
            } else if([val toDictionary][@"0"]){
                // Array check
                [[Jason client] success: @{@"data": [val toArray]}];
            } else {
                [[Jason client] success: @{@"data": [val toDictionary]}];
            }
        }
        @catch(NSException *e){
            [[Jason client] success: @{@"data": [val toDictionary]}];
        }
    } else {
        [[Jason client] success];
    }
}
+ (id)parse: (id)data with: (id)parser{
    return [self parse:data type:@"json" with:parser];
}
+ (id)parse: (id)data type: (NSString *) type with: (id)parser{
    if(type && [[type lowercaseString] isEqualToString:@"html"]){
        if(data && [data count] > 0){
            NSString *str = data[@"$jason"];
            NSString *path = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"js"];
            NSStringEncoding encoding;
            NSError *error = nil;
            NSString *js = [NSString stringWithContentsOfFile:path
                                                   usedEncoding:&encoding
                                                          error:&error];
            
            JSContext *context = [[JSContext alloc] init];
            [context setExceptionHandler:^(JSContext *context, JSValue *value) {
                NSLog(@"%@", value);
            }];

            [context evaluateScript:js];
            JSValue *parse = context[@"parser"][@"html"];
            JSValue *val = [parse callWithArguments:@[parser, str]];
            @try{
                if([val isString]){
                    return [val toString];
                } else if([val toDictionary][@"0"]){
                    // Array check
                    return [val toArray];
                } else {
                    return [val toDictionary];
                }
            }
            @catch(NSException *e){
                return [val toDictionary];
            }
            
        } else {
            return parser;
        }
    } else if(type && [[type lowercaseString] isEqualToString:@"xml"]){
        if(data && [data count] > 0){
            NSString *str = data[@"$jason"];
            NSString *path = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"js"];
            NSStringEncoding encoding;
            NSError *error = nil;
            NSString *js = [NSString stringWithContentsOfFile:path
                                                   usedEncoding:&encoding
                                                          error:&error];
            
            JSContext *context = [[JSContext alloc] init];
            [context setExceptionHandler:^(JSContext *context, JSValue *value) {
                NSLog(@"%@", value);
            }];

            [context evaluateScript:js];
            JSValue *parse = context[@"parser"][@"xml"];
            JSValue *val = [parse callWithArguments:@[parser, str]];
            @try{
                if([val isString]){
                    return [val toString];
                } else if([val toDictionary][@"0"]){
                    // Array check
                    return [val toArray];
                } else {
                    return [val toDictionary];
                }
            }
            @catch(NSException *e){
                return [val toDictionary];
            }
            
        } else {
            return parser;
        }
    } else {
       // default: json
//        if(data && [data count] > 0){
        if(data){
            NSString *path = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"js"];
            NSStringEncoding encoding;
            NSError *error = nil;
            NSString *js = [NSString stringWithContentsOfFile:path
                                                   usedEncoding:&encoding
                                                          error:&error];
            
            JSContext *context = [[JSContext alloc] init];
            [context setExceptionHandler:^(JSContext *context, JSValue *value) {
                NSLog(@"%@", value);
            }];
            
            [context evaluateScript:@"var console = {}"];
            context[@"console"][@"log"] = ^(NSString *message) {
                NSLog(@"Javascript log: %@",message);
            };


            [context evaluateScript:js];
            JSValue *parse = context[@"parser"][@"json"];
            JSValue *val = [parse callWithArguments:@[parser, data]];
            
            @try{
                if([val isString]){
                    return [val toString];
                } else if([val toDictionary][@"0"]){
                    // Array check
                    return [val toArray];
                } else {
                    return [val toDictionary];
                }
            }
            @catch(NSException *e){
                return [val toDictionary];
            }
            
        } else {
            return parser;
        }
    }
}
@end
