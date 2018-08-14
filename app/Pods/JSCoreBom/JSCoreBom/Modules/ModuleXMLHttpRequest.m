#import "ModuleXMLHttpRequest.h"

@implementation ModuleXMLHttpRequest
{
    NSString* _method;
    NSString* _url;
    BOOL _async;
    JSManagedValue* _onLoad;
    JSManagedValue* _onError;
}

@synthesize responseText;

-(void)open:(NSString*)httpMethod :(NSString*)url :(bool)async;
{
    _method = httpMethod;
    _url = url;
    _async = async;
}

-(void)setOnload:(JSValue *)onload
{
    _onLoad = [JSManagedValue managedValueWithValue:onload];
    [[[JSContext currentContext] virtualMachine] addManagedReference:_onLoad withOwner:self];
}

-(JSValue*)onload { return _onLoad.value; }

-(void)setOnerror:(JSValue *)onerror
{
    _onError = [JSManagedValue managedValueWithValue:onerror];
    [[[JSContext currentContext] virtualMachine] addManagedReference:_onError withOwner:self];
}
-(JSValue*)onerror { return _onError.value; }

-(void)send
{
    NSMutableURLRequest* req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_url]];
    req.HTTPMethod = _method;

    NSURLResponse* response;
    NSError* error;
    NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    self.responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if (!error && _onLoad)
        [[_onLoad.value invokeMethod:@"bind" withArguments:@[self]] callWithArguments:NULL];
    else if (error && _onError)
        [[_onError.value invokeMethod:@"bind" withArguments:@[self]] callWithArguments:@[[JSValue valueWithNewErrorFromMessage:error.localizedDescription inContext:[JSContext currentContext]]]];
}

@end
