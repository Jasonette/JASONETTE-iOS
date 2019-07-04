#import "ModuleConsole.h"

@implementation ModuleConsole
{
    NSMutableDictionary* _wrappers;
    void (^_logHandler)(NSString*,NSArray*,NSString*);
}

-(instancetype)initWithLogHandler:(void (^)(NSString*,NSArray*,NSString*))logHandler
{
    if (self = [super init])
    {
        _logHandler = logHandler;
        _wrappers = [@{} mutableCopy];
    }
    return self;
}

-(JSValue*)wrapperForLogLevel:(NSString*)logLevel
{
    if (!_wrappers[logLevel])
    {
        NSString* cmd = [NSString stringWithFormat:@"c = function() { console.__write('%@', Array.prototype.slice.call(arguments, 0)) }", logLevel];
        _wrappers[logLevel] = [[JSContext currentContext] evaluateScript:cmd];
    }

    return _wrappers[logLevel];
}

-(JSValue*)log   { return [self wrapperForLogLevel:@"log"]; }
-(JSValue*)debug { return [self wrapperForLogLevel:@"debug"]; }
-(JSValue*)error { return [self wrapperForLogLevel:@"error"]; }
-(JSValue*)info  { return [self wrapperForLogLevel:@"info"]; }
-(JSValue*)warn  { return [self wrapperForLogLevel:@"warn"]; }

-(void)__write:(NSString*)logLevel :(NSArray*)params
{
    NSString* formatedLogEntry = @"";
    
    if (params.count == 1)
        formatedLogEntry = [NSString stringWithFormat:@"%@",params[0]];
    else if (![params[0] isKindOfClass:NSString.class] ||
             ![((NSString*)params[0]) containsString:@"%"])
        formatedLogEntry = [NSString stringWithFormat:@"%@",params];
    else
    {
        NSString* format = params[0];
        __block NSString* output = @"";
        NSMutableArray* formatParams = [[params subarrayWithRange:NSMakeRange(1, params.count-1)] mutableCopy];
        __block BOOL isOperator = NO;
        
        [format enumerateSubstringsInRange:NSMakeRange(0, format.length)
                                   options:NSStringEnumerationByComposedCharacterSequences
                                usingBlock:^(NSString *symbol, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            if ([symbol isEqualToString:@"%"])
                isOperator = YES;
            else if (isOperator)
            {
                if ([symbol isEqualToString:@"s"] ||    // TODO: Should we actually implement format templates?
                    [symbol isEqualToString:@"d"] ||
                    [symbol isEqualToString:@"i"] ||
                    [symbol isEqualToString:@"f"] ||
                    [symbol isEqualToString:@"o"] ||
                    [symbol isEqualToString:@"O"] ||
                    [symbol isEqualToString:@"c"])
                    output = [output stringByAppendingFormat:@"%@", [formatParams firstObject]];
                
                [formatParams removeObjectAtIndex:0];
                isOperator = NO;
            }
            else
                output = [output stringByAppendingString:symbol];
        }];
        
        formatedLogEntry  = [NSString stringWithFormat:@"%@%@",output,formatParams.count ? formatParams : @""];
    }
    
    if (_logHandler)
        _logHandler(logLevel,params,formatedLogEntry);
    else
        NSLog(@"%@",formatedLogEntry);
}


@end
