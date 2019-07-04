//
//  JasonLogger.m
//  Jasonette
//
//  Created by Jasonelle Team on 04-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

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

+ (nonnull DTLogBlock) handler {
    DTLogBlock DTLogHandler = ^(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber, NSString *methodName, NSString *format, ...)
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
    
    NSLog(@"%@ | %@ | %ld | %@", logLevel[@"name"], fileName, lineNumber, message);
    
    return message;
}

@end
