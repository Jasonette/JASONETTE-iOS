# Extensions

*Jasonette* is easily extendable. You can add your own
native code `actions`, `components` or `services` and call them using JSON.

> More Examples

[https://github.com/jasonelle/docs/tree/develop/examples/jasonette/extensions](https://github.com/jasonelle/docs/tree/develop/examples/jasonette/extensions)

## The jr.json

This file contains the configuration that *Jasonette* needs
to detect the extension.

Example:

[https://github.com/jasonelle/docs/tree/develop/examples/jasonette/extensions/ios/vibration-action](https://github.com/jasonelle/docs/tree/develop/examples/jasonette/extensions/ios/vibration-action)

```json
{
  "version": "0.1.0",
  "name": "vibration",
  "classname": "JasonVibrationAction",
  "platform": "ios",
  "language" : "objective-c",
  "author" : "Jasonelle",
  "href" : "https://jasonelle.com",
  "license" : "MIT",
  "description": "$vibration.activate makes the device vibrate."
}
```

At the minimum it must have two properties:

- `name`: is the one who defines how Jasonette will identify
this component.


In the example is `vibration`. The json object will be `$vibration`.


- `classname`: tells which file will be used for this action.


This is used in *Jasonette* to load the class. It must follow
the pattern `Jason<Name>Action` for actions and `Jason<Name>Component`
for components.

It's a good practice to include a `test.json` with a sample app
that uses your action/component.

> `name` and `classname` could be different for the same component.
> is important that they not conflict with other actions
> or components.


## Creating Extensions

You can create extensions with native *Objective-C* or *Swift*.

If you are using Swift for an Extension use the `@objc()` annotation.

```
@objc(MySwiftClass)
class MySwiftClass {
    // ...
}
```

Extensions must be childs of the parent class `JasonAction` or `JasonComponent`.

### Jason

The `Jason` is the main singleton for executing actions and other
operations.

#### call

Use `Jason.client.call` to trigger an action related to
an element. The element should decide when to call this action.

```objc
[[Jason client] call:json[@"action"]];
```

> You can also call using params

```objc
[[Jason client]
    call:json[@"action"]
    with:@{ @"$jason": payload }];
```

> Or type your json directly

```objc

[[Jason client] call:@{
                 @"type": @"$href",
                 @"options": userInfo[@"href"]
            }];
```

#### go

Use `Jason.client.go` to load a view inside a `file://` or `http[s]://`
url.

```objc
[[Jason client] go:userInfo[@"href"]];
```

#### getVC

Obtain the current `JasonViewController` object.

```objc
[[[Jason client] getVC];
```


### JasonAction

Defines actions that could be performed using the `action` property.

```json
{
    "action" : {
        "type": "$myaction"
    }
}
```

> Interface:
> The action must be child of `JasonAction` and follow the naming convention.

```objc
#import "JasonAction.h"
@interface JasonMyCustomAction : JasonAction

@end
```

> Implementation:
> Each method will be available as `$myaction.mymethod`
> in this case would be `$myaction.get`

```objc
- (void) get {
    NSLog(@"Hello");
}
```

#### Methods

All the input and output must be using the `Jason` class
using the `client` singleton.

Example

```objc
[[Jason client] success:@{ @"coord": coord }];
```

##### options

The dictionary `self.options` contains all the params provided in
the json file.

```objc
NSString * name = self.options[@"name"];
```

##### success

Call `Jason.client.success` method to return a value. And execute
the `success` callback in the json. The params provided would be
available inside the `$jason` property.

```objc
[[Jason client] success:@{}];
```

##### error

Call `Jason.client.error` method to execute the `error` callback in the json.

```objc
[[Jason client] error];
```

#### Example: JasonVibrationAction

> JasonVibrationAction.h

```objc

#import "JasonAction.h"

@interface JasonVibrationAction : JasonAction

@end
```

> JasonVibrationAction.m

```objc

#import "JasonVibrationAction.h"
#import "JasonOptionHelper.h"

#import <AVFoundation/AVFoundation.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

// AudioServicesPlaySystemSound (1352) works for iPhones regardless of silent switch position
int const kForceVibrationId = 1352;

@implementation JasonVibrationAction

// use this as $vibration.activate
- (void) activate
{
    BOOL forceVibration = [self.options[@"force"] boolValue];
    
    int vibrationId = kSystemSoundID_Vibrate;
    
    if (forceVibration && [[UIDevice currentDevice].model
                           isEqualToString:@"iPhone"])
    {
        vibrationId = kForceVibrationId;
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0"))
    {

        AudioServicesPlayAlertSoundWithCompletion(vibrationId, nil);
    }
    else
    {
        AudioServicesPlayAlertSound(vibrationId);
    }

    [[Jason client] success];
}

@end
```

### JasonComponent

A component is an `UIView` that could be rendered by the `JasonComponentFactory`.

```json
{
    "type" : "mycomponent"
}
```

> Interface:
> The component must be child of `JasonComponent` and follow the naming convention.

```objc
#import "JasonComponent.h"
@interface JasonMyCustomComponent : JasonComponent

@end
```

> Implementation:
> The component must implement the following method

```objc
+ (UIView *) build:(UIView *)component
    withJSON:(NSDictionary *)json
    withOptions:(NSDictionary *)options;
```

#### Properties

- `component`: Should be returned with all the styles and options applied.
- `json`: Contains the properties `name`, `action` and `style`.
- `options`: Contains the params.

##### component can't be nil

Component param can't be `nil`. always check and build the component
if needed.

```objc
if (!component)
{
    component = [[UIView alloc] init];
}
```

#### Methods

Most information is stored in the params of the implementation. Some of the following methods can become handy.

##### stylize

Use the `stylize` to apply common styles configuration
to the component.

```objc
[self stylize:json component:component];
```

> Call this method before applying your custom styles.

##### updateForm

Use the `updateForm` method to return values to the json.
Use a `NSDictionary` with the component `name` to the set values.

```objc
[self updateForm:@{ json[@"name"]: newValue }];
```


##### Target Actions

Is recommended to use the Target-Action to listen to component events.

[https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Target-Action/Target-Action.html](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Target-Action/Target-Action.html)

```objc

// Remove then add to ensure uniqueness
[component removeTarget:self action:@selector(myselector:) forControlEvents:UIControlEventValueChanged];

[component addTarget:self action:@selector(myselector:) forControlEvents:UIControlEventValueChanged];
```

Create custom handlers and use `Jason.client.call` to
trigger the action associated with the component.


#### Example: JasonSpaceComponent

> JasonSpaceComponent.h

```objc
#import "JasonComponent.h"
#import "JasonHelper.h"

@interface JasonSpaceComponent : JasonComponent
@end
```

> JasonSpaceComponent.m

```objc
#import "JasonSpaceComponent.h"

@implementation JasonSpaceComponent
+ (UIView *) build:(UIView *)component withJSON:(NSDictionary *)json withOptions:(NSDictionary *)options {

    if (!component)
    {
        component = [[UIView alloc] init];
    }
    if ([options[@"parent"] isEqualToString:@"vertical"])
    {
        [component setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisVertical];
    }
    else if ([options[@"parent"] isEqualToString:@"horizontal"])
    {
        [component setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisHorizontal];
    }
    component.translatesAutoresizingMaskIntoConstraints = false;

    // Apply Common Style
    [self stylize:json component:component];

    return component;
}

@end
```

### JasonService

A service is a special extension that will not be deallocated
when the view changes. They are similar to daemons that runs
in background processes.

Some services are: `$agent`, `$websocket`, `$vision` and `$push`.

They do not need to extend a base class. But they must implement
the `initialize:` method called in the `AppDelegate`. And follow
the naming convention `Jason<Name>Service`.

```objc
- (void) initialize:(NSDictionary *)launchOptions;
```

#### Accessing a Service

For accessing a service object use the `Jason.client.services` property.
This could be used inside an `action` or `component` that interacts
with the service.

```objc
JasonPushService * service = [Jason client].services[@"JasonPushService"];
```

#### Example: JasonVisionService and JasonVisionAction

> JasonVisionService.h

```objc
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Jason.h"
#import "JasonMemory.h"

@interface JasonVisionService : NSObject <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, assign) BOOL is_open;

@end
```

> JasonVisionService.m

```objc
#import "JasonVisionService.h"
#import "JasonLogger.h"

@implementation JasonVisionService
- (void) initialize:(NSDictionary *)launchOptions
{
    self.is_open = NO;
    DTLogDebug(@"initialize");
}

- (void) captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {

    if (!self.is_open)
    {
        return;
    }

    NSDictionary * events = [[[Jason client] getVC] valueForKey:@"events"];
    if (![JasonMemory client].executing)
    {
        for (AVMetadataObject * metadata in metadataObjects)
        {
            AVMetadataMachineReadableCodeObject * transformed = (AVMetadataMachineReadableCodeObject *) metadata;
            self.is_open = NO;
            [[Jason client] call:events[@"$vision.onscan"] with:@{
                 @"$jason": @{
                     @"content": transformed.stringValue,
                     @"type": transformed.type
                     //                   @"corners": transformed.corners,
                     //                   @"bounds": @{
                     //                       @"left": [NSNumber numberWithFloat: transformed.bounds.origin.x],
                     //                       @"top": [NSNumber numberWithFloat: transformed.bounds.origin.y],
                     //                       @"width": [NSNumber numberWithFloat: transformed.bounds.size.width],
                     //                       @"height": [NSNumber numberWithFloat: transformed.bounds.size.height]
                     //                   }
                 }
            }];
            return;
        }
    }
}

@end
```

> JasonVisionAction.m

```objc
#import "JasonAction.h"
#import "JasonVisionService.h"
#import "Jason.h"

@interface JasonVisionAction : JasonAction

@end
```

> JasonVisionAction.m

```objc
#import "JasonVisionAction.h"

@implementation JasonVisionAction

// $vision.scan
- (void) scan {
    JasonVisionService * service = [Jason client].services[@"JasonVisionService"];

    service.is_open = YES;
    [[Jason client] success];
}
@end
```