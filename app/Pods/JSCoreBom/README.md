# JSCoreBom
JavaScriptCore framework on iOS/OSX is missing some things from browser object model you get used to - setTimeout, XMLHttpRequest, etc. Also a lot of libraries requires to have such objects, for example [rx.js](https://github.com/Reactive-Extensions/RxJS/blob/v2.3.18/dist/rx.js#L1132) requires to have setTimeout.

This projects extends JSContext with native implementation of **some** functions of BOM using Objective-C

## How to use it?
Using cocoapods: `pod 'JSCoreBom', '~> 1.1'`.

Whenever you would like to extend JSContext with BOM function just use:
```
JSContext* context = [[JSContext alloc] init];
[[JSCoreBom shared] extendContext:context];
```

Then just use it:
```
[context evaluateScript:@"setTimeout(function(){ console.log('Hi in 5 seconds!')},5000"];
```

## What does it contain?

Name            					| Description                         | Status
---             					| ---                                 | ---
setTimeout      					| Implemented using dispatch_after    | Done
console.{info,log,debug,warn,error} | Would forward everything to NSLog   | Done
XmlHTTPRequest  					| Using NSUrlSession                  | Proto done

For logger you can specify custom log handler:
```
[[JSCoreBom shared] extend:context logHandler:^(NSString* logLevel, NSArray* params, NSString* formattedLogEntry) {
    if ([logLevel isEqualToString: @"log"])
    	[MyCustomLogger log:logEntry];
}];
```


## How does it work?
Like Apple [on a page 45 said to!](http://devstreaming.apple.com/videos/wwdc/2013/615xax5xpcdns8jyhaiszkz2p/615/615.pdf?dl=1)
```

JSContext* context = [[JSContext alloc] init];
context[@"setTimeout"] = ^(JSValue* function, JSValue* timeout) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([timeout toInt32] * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [function callWithArguments:@[]];
    });
};
```

## Known issues
XMLHttpRequest:
- Always sync call is made using NSURLConnection, not NSUrlSession yet
