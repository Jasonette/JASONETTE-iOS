//
//  JasonConvertAction.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonConvertAction.h"

@implementation JasonConvertAction
- (void)string{
    NSString *dataString = self.options[@"data"];
    if(dataString && dataString.length > 0){
        NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [[Jason client] success:json];
    } else {
        [[Jason client] success:@{}];
    }
}
- (void)csv{
    if(self.options){
        NSString *data = self.options[@"data"];
        if(data && data.length > 0){
            NSMutableDictionary *o = [self.options mutableCopy];
            [o removeObjectForKey:@"data"];
            for(NSString *key in o){
                if([o[key] isEqualToString:@"true"]){
                    o[key] = @YES;
                }else if([o[key] isEqualToString:@"false"]){
                    o[key] = @NO;
                }
            }
            
            NSString *path = [[NSBundle mainBundle] pathForResource:@"csv" ofType:@"js"];
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

            JSValue *parse = context[@"csv"][@"run"];
            JSValue *val = [parse callWithArguments:@[data, o]];
            
            @try{
                if([val isString]){
                    [[Jason client] success: [val toString]];
                } else if([val toDictionary][@"0"]){
                    // Array check
                    [[Jason client] success:[val toArray]];
                } else {
                    [[Jason client] success:[val toDictionary]];
                }
            }
            @catch(NSException *e){
                [[Jason client] error];
            }
            
            
        } else {
            [[Jason client] success];
        }
    }
}

- (void)rss{
    if(self.options){
        NSString *data = self.options[@"data"];
        if(data && data.length > 0){
            NSMutableDictionary *o = [self.options mutableCopy];
            [o removeObjectForKey:@"data"];
            for(NSString *key in o){
                if([o[key] isEqualToString:@"true"]){
                    o[key] = @YES;
                }else if([o[key] isEqualToString:@"false"]){
                    o[key] = @NO;
                }
            }
            
            NSString *path = [[NSBundle mainBundle] pathForResource:@"rss" ofType:@"js"];
            NSStringEncoding encoding;
            NSError *error = nil;
            NSString *js = [NSString stringWithContentsOfFile:path
                                                   usedEncoding:&encoding
                                                          error:&error];
            
            JSContext *context = [[JSContext alloc] init];
            [[JSCoreBom shared] extend:context];

            [context setExceptionHandler:^(JSContext *context, JSValue *value) {
                NSLog(@"%@", value);
            }];
            context[@"callback"] = ^(JSValue *val){
                @try{
                    if([val isString]){
                        [[Jason client] success: [val toString]];
                    } else if([val toDictionary][@"0"]){
                        // Array check
                        [[Jason client] success: [val toArray]];
                    } else {
                        [[Jason client] success: [val toDictionary]];
                    }
                }
                @catch(NSException *e){
                    NSLog(@"Failed");
                    [[Jason client] error];
                }
            };
            [context evaluateScript:js];
            JSValue *parse = context[@"rss"][@"run"];
            [parse callWithArguments:@[data, o]];
            
        } else {
            [[Jason client] success];
        }
    }
}

@end
