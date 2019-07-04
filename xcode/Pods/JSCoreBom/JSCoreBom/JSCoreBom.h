#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface JSCoreBom : NSObject

+(JSCoreBom*)shared;
-(void)extend:(JSContext*)context;
-(void)extend:(JSContext*)context logHandler:(void (^)(NSString* logLevel,NSArray* params,NSString* formatedLogEntry))logHandler;

@end
