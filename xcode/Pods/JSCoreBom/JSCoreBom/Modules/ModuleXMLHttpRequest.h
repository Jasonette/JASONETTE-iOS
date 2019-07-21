#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol ExportXMLHttpRequest <JSExport>

@property NSString* responseText;
@property JSValue* onload;
@property JSValue* onreadystatechange;
@property JSValue* onerror;
@property NSInteger readyState;
@property NSInteger status;

-(instancetype)init;

-(void)open:(NSString*)httpMethod :(NSString*)url :(bool)async;
-(void)send;
-(void)setRequestHeader:(NSString*)key :(NSString*)value;

@end

@interface ModuleXMLHttpRequest: NSObject <ExportXMLHttpRequest>

@end