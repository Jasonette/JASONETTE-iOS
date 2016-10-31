#import <JavaScriptCore/JavaScriptCore.h>

@protocol ExportConsole <JSExport>

@property (readonly) JSValue* log;
@property (readonly) JSValue* debug;
@property (readonly) JSValue* error;
@property (readonly) JSValue* info;
@property (readonly) JSValue* warn;

-(void)__write:(NSString*)logLevel :(NSArray*)params;

@end

@interface ModuleConsole : NSObject <ExportConsole>

-(instancetype)initWithLogHandler:(void (^)(NSString*,NSArray*,NSString*))logHandler;

@end
