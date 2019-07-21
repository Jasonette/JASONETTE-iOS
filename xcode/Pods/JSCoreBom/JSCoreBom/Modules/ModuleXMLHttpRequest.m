#import "ModuleXMLHttpRequest.h"

@implementation ModuleXMLHttpRequest
{
    NSString* _method;
    NSString* _url;
    NSMutableDictionary* _headers;
    BOOL _async;
    JSManagedValue* _onLoad;
    JSManagedValue* _onReadyStateChange;
    JSManagedValue* _onError;
}

@synthesize responseText;
@synthesize readyState;
@synthesize status;

-(void)open:(NSString*)httpMethod :(NSString*)url :(bool)async;
{
    _method = httpMethod;
    _url = url;
    _async = async;
    readyState = 1;
}

-(void)setRequestHeader:(NSString *)key :(NSString *)value
{
    _headers[key] = value;
}

-(void)setOnload:(JSValue *)onload
{
    _onLoad = [JSManagedValue managedValueWithValue:onload];
    [[[JSContext currentContext] virtualMachine] addManagedReference:_onLoad withOwner:self];
}

-(JSValue*)onload { return _onLoad.value; }

-(void)setOnreadystatechange:(JSValue *)onReadyStateChange
{
    _onReadyStateChange = [JSManagedValue managedValueWithValue:onReadyStateChange];
    [[[JSContext currentContext] virtualMachine] addManagedReference:_onReadyStateChange withOwner:self];
}

-(JSValue*)onreadystatechange { return _onReadyStateChange.value; }


-(void)setOnerror:(JSValue *)onerror
{
    _onError = [JSManagedValue managedValueWithValue:onerror];
    [[[JSContext currentContext] virtualMachine] addManagedReference:_onError withOwner:self];
}
-(JSValue*)onerror { return _onError.value; }

-(void)send
{
    readyState = 2;
    NSMutableURLRequest* req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_url]];
    req.HTTPMethod = _method;
    
    for (NSString *items in _headers.allKeys) {
        [req setValue:_headers[items] forHTTPHeaderField:items];
    }

    NSHTTPURLResponse* response;
    NSError* error;
    readyState = 3;
    NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    self.responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    status = [response statusCode];
    readyState = 4;
    if (!error) {
        if (_onLoad) {
            [[_onLoad.value invokeMethod:@"bind" withArguments:@[self]] callWithArguments:NULL];
        } else if (_onReadyStateChange) {
            [[_onReadyStateChange.value invokeMethod:@"bind" withArguments:@[self]] callWithArguments:NULL];
        }
    } else if (error && _onError)
        [[_onError.value invokeMethod:@"bind" withArguments:@[self]] callWithArguments:@[[JSValue valueWithNewErrorFromMessage:error.localizedDescription inContext:[JSContext currentContext]]]];
}

@end
