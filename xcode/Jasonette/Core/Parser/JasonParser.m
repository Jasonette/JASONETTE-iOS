//
//  JasonParser.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonParser.h"
#import "JasonLogger.h"

@implementation JasonParser

- (void)format
{
    DTLogDebug (@"Loading Parser Format with Data %@", self.options);

    NSDictionary * data = self.options[@"data"];
    id schema = self.options[@"template"];

    if (data && data.count > 0) {
        NSString * path = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"js"];
        NSStringEncoding encoding;
        NSError * error = nil;
        NSString * js = [NSString stringWithContentsOfFile:path
                                              usedEncoding:&encoding
                                                     error:&error];

        JSContext * context = [[JSContext alloc] init];
        [context setExceptionHandler:^(JSContext * context, JSValue * value) {
                     DTLogWarning (@"%@", value);
                 }];

        [context evaluateScript:js];
        JSValue * parse = context[@"parser"][@"json"];
        JSValue * val = [parse callWithArguments:@[schema, data]];
        @try {
            if ([val isString]) {
                [[Jason client] success:@{ @"data": [val toString] }];
            } else if ([val toDictionary][@"0"]) {
                // Array check
                [[Jason client] success:@{ @"data": [val toArray] }];
            } else {
                [[Jason client] success:@{ @"data": [val toDictionary] }];
            }
        } @catch (NSException * e) {
            [[Jason client] success:@{ @"data": [val toDictionary] }];
        }
    } else {
        [[Jason client] success];
    }
}

+ (id)parse:(id)data
       with:(id)parser
{
    return [self parse:data type:@"json" with:parser];
}

+ (id)parse:(id)data
       type:(NSString *)type
       with:(id)parser
{
    DTLogInfo (@"Begin Parsing Document %@ %@", type, data);

    if (type && [[type lowercaseString] isEqualToString:@"html"]) {
        if (data && [data count] > 0) {
            NSString * str = data[@"$jason"];
            NSString * path = [[NSBundle mainBundle] pathForResource:@"st" ofType:@"js"];
            NSStringEncoding encoding;
            NSError * error = nil;
            NSString * js = [NSString stringWithContentsOfFile:path
                                                  usedEncoding:&encoding
                                                         error:&error];

            JSContext * context = [[JSContext alloc] init];
            [context setExceptionHandler:^(JSContext * context, JSValue * value) {
                         DTLogWarning (@"%@", value);
            }];

            [context evaluateScript:js];

            NSString * tojson_path = [[NSBundle mainBundle] pathForResource:@"xhtml" ofType:@"js"];
            js = [NSString stringWithContentsOfFile:tojson_path
                                       usedEncoding:&encoding
                                              error:&error];
            [context evaluateScript:js];


            JSValue * parse = context[@"to_json"];
            JSValue * val = [parse callWithArguments:@[@"html", parser, str]];
            @try {
                if ([val isString]) {
                    return [val toString];
                } else if ([val toDictionary][@"0"]) {
                    // Array check
                    return [val toArray];
                } else {
                    return [val toDictionary];
                }
            } @catch (NSException * e) {
                return [val toDictionary];
            }
        } else {
            return parser;
        }
    } else if (type && [[type lowercaseString] isEqualToString:@"xml"]) {
        if (data && [data count] > 0) {
            NSString * str = data[@"$jason"];
            NSString * path = [[NSBundle mainBundle] pathForResource:@"st" ofType:@"js"];
            NSStringEncoding encoding;
            NSError * error = nil;
            NSString * js = [NSString stringWithContentsOfFile:path
                                                  usedEncoding:&encoding
                                                         error:&error];

            JSContext * context = [[JSContext alloc] init];
            [context setExceptionHandler:^(JSContext * context, JSValue * value) {
                         DTLogWarning (@"%@", value);
                     }];

            [context evaluateScript:js];

            NSString * tojson_path = [[NSBundle mainBundle] pathForResource:@"xhtml" ofType:@"js"];
            js = [NSString stringWithContentsOfFile:tojson_path
                                       usedEncoding:&encoding
                                              error:&error];
            [context evaluateScript:js];


            JSValue * parse = context[@"to_json"];
            JSValue * val = [parse callWithArguments:@[@"xml", parser, str]];


            @try {
                if ([val isString]) {
                    return [val toString];
                } else if ([val toDictionary][@"0"]) {
                    // Array check
                    return [val toArray];
                } else {
                    return [val toDictionary];
                }
            } @catch (NSException * e) {
                return [val toDictionary];
            }
        } else {
            return parser;
        }
    } else {
        // default: json
//        if(data && [data count] > 0){
        if (data) {
            DTLogDebug (@"Loading st.js");
            NSString * path = [[NSBundle mainBundle] pathForResource:@"st" ofType:@"js"];
            NSStringEncoding encoding;
            NSError * error = nil;
            NSString * js = [NSString stringWithContentsOfFile:path
                                                  usedEncoding:&encoding
                                                         error:&error];

            if (error) {
                DTLogError (@"Could not Load st.js %@", error);
            }

            JSContext * context = [Jason client].jscontext;

            if (!context) {
                context = [[JSContext alloc] init];
            }

            NSDictionary * globals = [context.globalObject toDictionary];

            if (globals && globals.count > 0) {
                NSMutableDictionary * mutable_data = [data mutableCopy];

                for (NSString * key in globals) {
                    [mutable_data setValue:[context.globalObject
                                            objectForKeyedSubscript:key]
                                    forKey:key];
                }

                data = mutable_data;
            }

            [context setExceptionHandler:^(JSContext * context, JSValue * value) {
                         DTLogWarning (@"%@", value);
                     }];

            [context evaluateScript:@"var console = {}"];
            context[@"console"][@"log"] = ^(NSString * message) {
                DTLogDebug (@"JS: %@", message);
            };

            DTLogDebug (@"Applying st.js to json");

            [context evaluateScript:js];
            JSValue * parse = context[@"ST"][@"transform"];
            JSValue * val = [parse callWithArguments:@[parser, data]];

            DTLogDebug (@"Got Transformed JSON");

            @try {
                if ([val isString]) {
                    return [val toString];
                } else if ([val toDictionary][@"0"]) {
                    // Array check
                    return [val toArray];
                } else {
                    return [val toDictionary];
                }
            } @catch (NSException * e) {
                return [val toDictionary];
            }
        } else {
            return parser;
        }
    }
}

@end
