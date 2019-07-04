# JasonLogger

This file enables debugging in the native iOS code.

## How to Use.

This is a simple wrapper to `<DTFoundation/DTLog.h>`.

### 1) Import to Appdelegate

```objc
#import "JasonLogger.h"
#import <DTFoundation/DTLog.h>
```

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#if DEBUG
    [JasonLogger setupWithLogLevel:DTLogLevelDebug];
#else
#endif
    // ...
}
```

### 2) Use

Simply call the `DTLog` Functions.

```objc
#import <DTFoundation/DTLog.h>

// log macro for error level (0)
DTLogEmergency(format, ...)

// log macro for error level (1)
DTLogAlert(format, ...)
// log macro for error level (2)
DTLogCritical(format, ...)

// log macro for error level (3)
DTLogError(format, ...)

// log macro for error level (4)
DTLogWarning(format, ...)

// log macro for error level (5)
DTLogNotice(format, ...)

// log macro for info level (6)
DTLogInfo(format, ...)

// log macro for debug level (7)
DTLogDebug(format, ...)
```

> Example

```objc
    DTLogWarning(@"No type for component provided. %@", child);
```

## How to Customize

The `JasonLogger` simply creates a new handler for the `DTLog`.

```objc
+ (nonnull DTLogBlock) handler {
    DTLogBlock DTLogHandler = ^(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber, NSString *methodName, NSString *format, ...)
    {
        va_list args;
        va_start(args, format);
        
        [JasonLogger LogMessageWithLevel:logLevel
                                  format:format
                                    args:args
                                fileName:fileName
                              lineNumber:lineNumber];
        
        va_end(args);
    };
    
    return [DTLogHandler copy];
}
```

You could create a new logger handler that sends the format and arguments
to a server or other log libs.

Simply call

```objc
DTLogSetLoggerBlock(<your handler>);
```

With your handler in `AppDelegate`.

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#if DEBUG
    DTLogSetLoggerBlock(<your handler>);
#else
#endif
    // ...
}
```
