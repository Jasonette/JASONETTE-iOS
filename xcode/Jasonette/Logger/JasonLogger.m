//
//  JasonLogger.m
//  Jasonette
//
//  Created by Jasonelle Team on 04-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

// Improved NSLog function with https://stackoverflow.com/a/7517513
#define NSLog(FORMAT, ...) fprintf(stderr, "%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#import "JasonLogger.h"

static NSDictionary * kLevelNames = nil;

@implementation JasonLogger

+ (void) setupWithLogLevel: (DTLogLevel) level {
    
    DTLogSetLoggerBlock([JasonLogger handler]);
    DTLogSetLogLevel(level);
    
    kLevelNames = @{
        @(DTLogLevelDebug) : @"DEBUG",
        @(DTLogLevelInfo) : @"INFO",
        @(DTLogLevelAlert): @"ALERT",
        @(DTLogLevelNotice): @"NOTICE",
        @(DTLogLevelError): @"ERROR",
        @(DTLogLevelWarning): @"WARNING",
        @(DTLogLevelCritical): @"CRITICAL",
        @(DTLogLevelEmergency): @"EMERGENCY"
    };
}

+ (void) setupWithLogLevelDebug
{
    [JasonLogger setupWithLogLevel:DTLogLevelDebug];
}

+ (void) setupWithLogLevelInfo
{
    [JasonLogger setupWithLogLevel:DTLogLevelInfo];
}

+ (void) setupWithLogLevelWarning
{
    [JasonLogger setupWithLogLevel:DTLogLevelWarning];
}

+ (void) setupWithLogLevelError
{
    [JasonLogger setupWithLogLevel:DTLogLevelError];
}

+ (nonnull DTLogBlock) handler {
    
    DTLogBlock DTLogHandler = ^(NSUInteger logLevel,
                                NSString *fileName,
                                NSUInteger lineNumber,
                                NSString *methodName,
                                NSString *format,
                                ...)
    {
        va_list args;
        va_start(args, format);
        
        [JasonLogger LogMessageWithLevel:@{
                                    @"number": @(logLevel),
                                    @"name": kLevelNames[@(logLevel)]
                                }
                                format:format
                                args:args
                                fileName:fileName
                                lineNumber:lineNumber];
        
        va_end(args);
    };
    
    return [DTLogHandler copy];
}

+ (nonnull NSString *) LogMessageWithLevel: (NSDictionary *) logLevel
                                    format:(NSString *) format
                                    args:(va_list) args
                                  fileName:(NSString *) fileName
                                lineNumber:(NSUInteger) lineNumber
{
    
    NSString * message = [[NSString alloc] initWithFormat:format arguments:args];
    
    // Try to follow an approach similar to ratlog https://github.com/ratlog/ratlog-spec
    NSLog(@"[%@] file: %@ | line: %ld | %@", logLevel[@"name"], fileName, lineNumber, message);
    
    return message;
}

@end
