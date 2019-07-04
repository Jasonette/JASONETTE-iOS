#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol ExportXMLHttpRequest <JSExport>

@property NSString* responseText;
@property JSValue* onload;
@property JSValue* onerror;

-(instancetype)init;

-(void)open:(NSString*)httpMethod :(NSString*)url :(bool)async;
-(void)send;

@end

@interface ModuleXMLHttpRequest: NSObject <ExportXMLHttpRequest>

@end