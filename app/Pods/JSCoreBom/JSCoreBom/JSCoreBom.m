#import "JSCoreBom.h"
#import "ModuleXMLHttpRequest.h"
#import "ModuleConsole.h"

@implementation JSCoreBom

+(instancetype)shared
{
    static dispatch_once_t pred;
    static JSCoreBom* sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[JSCoreBom alloc] init];
    });
    return sharedInstance;
}

-(void)extend:(JSContext *)context { return [self extend:context logHandler:nil]; }
-(void)extend:(JSContext*)context logHandler:(void (^)(NSString*,NSArray*,NSString*))logHandler;
{
    context[@"setTimeout"] = ^(JSValue* function, JSValue* timeout) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([timeout toInt32] * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [function callWithArguments:@[]];
        });
    };
    
    context[@"XMLHttpRequest"] = [ModuleXMLHttpRequest class];
    context[@"console"] = [[ModuleConsole alloc] initWithLogHandler:logHandler];
}

@end
