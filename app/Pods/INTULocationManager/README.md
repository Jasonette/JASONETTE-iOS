# [![INTULocationManager](https://github.com/intuit/LocationManager/blob/master/Images/INTULocationManager.png?raw=true)](#)  
[![Build Status](http://img.shields.io/travis/intuit/LocationManager.svg?style=flat)](https://travis-ci.org/intuit/LocationManager) [![Test Coverage](http://img.shields.io/coveralls/intuit/LocationManager.svg?style=flat)](https://coveralls.io/r/intuit/LocationManager) [![Version](http://img.shields.io/cocoapods/v/INTULocationManager.svg?style=flat)](http://cocoapods.org/pods/INTULocationManager) [![Platform](http://img.shields.io/cocoapods/p/INTULocationManager.svg?style=flat)](http://cocoapods.org/pods/INTULocationManager) [![License](http://img.shields.io/cocoapods/l/INTULocationManager.svg?style=flat)](LICENSE)

INTULocationManager makes it easy to get the device's current location and heading on iOS. It is an Objective-C library that also works great in Swift.

INTULocationManager provides a block-based asynchronous API to request the current location, either once or continuously. It internally manages multiple simultaneous location and heading requests, and each one-time location request can specify its own desired accuracy level and timeout duration. INTULocationManager automatically starts location services when the first request comes in and stops location services as soon as all requests have been completed, all the while dynamically managing the power consumed by location services to reduce impact on battery life.

## What's wrong with CLLocationManager?
CLLocationManager requires you to manually detect and handle things like permissions, stale/inaccurate locations, errors, and more. CLLocationManager uses a more traditional delegate pattern instead of the modern block-based callback pattern. And while it works fine to track changes in the user's location over time (such as for turn-by-turn navigation), it is extremely cumbersome to correctly request a single location update (such as to determine the user's current city to get a weather forecast, or to autofill an address from the current location).

INTULocationManager makes it easy to request both the device's current location, either once or continuously, as well as the device's continuous heading. The API is extremely simple for both one-time location requests and recurring subscriptions to location updates. For one-time location requests, you can specify how accurate of a location you need, and how long you're willing to wait to get it. Significant location change monitoring is also supported. INTULocationManager is power efficient and conserves the device's battery by automatically determining and using the most efficient Core Location accuracy settings, and by automatically powering down location services (e.g. GPS or compass) as soon as they are no longer needed.

## Installation
*INTULocationManager requires iOS 6.0 or later.*

### Using [CocoaPods](http://cocoapods.org)

1.	Add the pod `INTULocationManager` to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html).

  ```ruby
  pod 'INTULocationManager'
  ```

1.	Run `pod install` from Terminal, then open your app's `.xcworkspace` file to launch Xcode.
1.	Import the `INTULocationManager.h` header.
  * With `use_frameworks!` in your Podfile
    * Swift: `import INTULocationManager`
    * Objective-C: `#import <INTULocationManager/INTULocationManager.h>` (or with Modules enabled: `@import INTULocationManager;`)
  * Without `use_frameworks!` in your Podfile
    * Swift: Add `#import "INTULocationManager.h"` to your bridging header.
    * Objective-C: `#import "INTULocationManager.h"`

### Using [Carthage](https://github.com/Carthage/Carthage)

1. Add the `intuit/LocationManager` project to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

  ```ogdl
  github "intuit/LocationManager"
  ```

1. Run `carthage update`, then follow the [additional steps required](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) to add the iOS and/or Mac frameworks into your project.
1. Import the INTULocationManager framework/module.
  * Swift: `import INTULocationManager`
  * Objective-C: `#import <INTULocationManager/INTULocationManager.h>` (or with Modules enabled: `@import INTULocationManager;`)

### Manually from GitHub

1. Download all the files in the [INTULocationManager subdirectory](LocationManager/INTULocationManager).
1. Add the source files to your Xcode project (drag and drop is easiest).
1. Import the `INTULocationManager.h` header.
  * Swift: Add `#import "INTULocationManager.h"` to your bridging header.
  * Objective-C: `#import "INTULocationManager.h"`

## Usage

### Requesting Permission to Access Location Services
INTULocationManager automatically handles obtaining permission to access location services when you issue a location request and the user has not already granted your app permission to access location services.

#### iOS 6 & 7
For iOS 6 & 7, it is recommended that you provide a description for how your app uses location services by setting a string for the key [`NSLocationUsageDescription`](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW27) in your app's `Info.plist` file.

#### iOS 8
Starting with iOS 8, you **must** provide a description for how your app uses location services by setting a string for the key [`NSLocationWhenInUseUsageDescription`](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW26) or [`NSLocationAlwaysUsageDescription`](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW18) in your app's `Info.plist` file. INTULocationManager determines which level of permissions to request based on which description key is present. You should only request the minimum permission level that your app requires, therefore it is recommended that you use the "When In Use" level unless you require more access. If you provide values for both description keys, the more permissive "Always" level is requested.

### Getting the Current Location (once)
To get the device's current location, use the method `requestLocationWithDesiredAccuracy:timeout:block:`.

The `desiredAccuracy` parameter specifies how **accurate and recent** of a location you need. The possible values are:
```objective-c
INTULocationAccuracyCity          // 5000 meters or better, received within the last 10 minutes  -- lowest accuracy
INTULocationAccuracyNeighborhood  // 1000 meters or better, received within the last 5 minutes
INTULocationAccuracyBlock         // 100 meters or better, received within the last 1 minute
INTULocationAccuracyHouse         // 15 meters or better, received within the last 15 seconds
INTULocationAccuracyRoom          // 5 meters or better, received within the last 5 seconds      -- highest accuracy
```

The `timeout` parameter specifies how long you are willing to wait for a location with the accuracy you requested. The timeout guarantees that your block will execute within this period of time, either with a location of at least the accuracy you requested (`INTULocationStatusSuccess`), or with whatever location could be determined before the timeout interval was up (`INTULocationStatusTimedOut`). Pass `0.0` for no timeout *(not recommended)*.

By default, the timeout countdown begins as soon as the `requestLocationWithDesiredAccuracy:timeout:block:` method is called. However, there is another variant of this method that includes a `delayUntilAuthorized:` parameter, which allows you to pass `YES` to delay the start of the timeout countdown until the user has responded to the system location services permissions prompt (if the user hasn't allowed or denied the app access yet).

Here's an example:
```objective-c
INTULocationManager *locMgr = [INTULocationManager sharedInstance];
[locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyCity
                                   timeout:10.0
                      delayUntilAuthorized:YES	// This parameter is optional, defaults to NO if omitted
                                     block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                         if (status == INTULocationStatusSuccess) {
                                             // Request succeeded, meaning achievedAccuracy is at least the requested accuracy, and
                                             // currentLocation contains the device's current location.
                                         }
                                         else if (status == INTULocationStatusTimedOut) {
                                             // Wasn't able to locate the user with the requested accuracy within the timeout interval.
                                             // However, currentLocation contains the best location available (if any) as of right now,
                                             // and achievedAccuracy has info on the accuracy/recency of the location in currentLocation.
                                         }
                                         else {
                                             // An error occurred, more info is available by looking at the specific status returned.
                                         }
                                     }];
```

### Subscribing to Continuous Location Updates
To subscribe to continuous location updates, use the method `subscribeToLocationUpdatesWithBlock:`. This method instructs location services to use the highest accuracy available (which also requires the most power). The block will execute indefinitely (even across errors, until canceled), once for every new updated location regardless of its accuracy.

If you do not need the highest possible accuracy level, you should instead use `subscribeToLocationUpdatesWithDesiredAccuracy:block:`. This method takes the desired accuracy level and uses it to control how much power is used by location services, with lower accuracy levels like Neighborhood and City requiring less power. Note that INTULocationManager will automatically manage the system location services accuracy level, including when there are multiple active location requests/subscriptions with different desired accuracies.

If an error occurs, the block will execute with a status other than `INTULocationStatusSuccess`, and the subscription will be kept alive.

Here's an example:
```objective-c
INTULocationManager *locMgr = [INTULocationManager sharedInstance];
[locMgr subscribeToLocationUpdatesWithDesiredAccuracy:INTULocationAccuracyHouse
                                                block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                                    if (status == INTULocationStatusSuccess) {
                                                        // A new updated location is available in currentLocation, and achievedAccuracy indicates how accurate this particular location is.
                                                    }
                                                    else {
                                                        // An error occurred, more info is available by looking at the specific status returned. The subscription has been kept alive.
                                                    }
                                                }];
```

### Subscribing to Significant Location Changes
To subscribe to significant location changes, use the method `subscribeToSignificantLocationChangesWithBlock:`. This instructs location services to begin monitoring for significant location changes, which is very power efficient. The block will execute indefinitely (until canceled), once for every new updated location regardless of its accuracy. Note that if there are other simultaneously active location requests or subscriptions, the block will execute for every location update (not just for significant location changes). If you intend to take action only when the location has changed significantly, you should implement custom filtering based on the distance & time from the last received location.

If an error occurs, the block will execute with a status other than `INTULocationStatusSuccess`, and the subscription will be kept alive.

Here's an example:
```objective-c
INTULocationManager *locMgr = [INTULocationManager sharedInstance];
[locMgr subscribeToSignificantLocationChangesWithBlock:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
    if (status == INTULocationStatusSuccess) {
		// A new updated location is available in currentLocation, and achievedAccuracy indicates how accurate this particular location is.
    }
    else {
        // An error occurred, more info is available by looking at the specific status returned. The subscription has been kept alive.
    }
}];
```

If your app has acquired the "Always" location services authorization and your app is terminated with at least one active significant location change subscription, your app may be launched in the background when the system detects a significant location change. Note that when the app terminates, all of your active location requests & subscriptions with INTULocationManager are canceled. Therefore, when the app launches due to a significant location change, you should immediately use INTULocationManager to set up a new subscription for significant location changes in order to receive the location information.

Here is an example of how to handle being launched in the background due to a significant location change:
```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // If you start monitoring significant location changes and your app is subsequently terminated, the system automatically relaunches the app into the background if a new event arrives.
    // Upon relaunch, you must still subscribe to significant location changes to continue receiving location events. 
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
        INTULocationManager *locMgr = [INTULocationManager sharedInstance];
        [locMgr subscribeToSignificantLocationChangesWithBlock:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
            // This block will be executed with the details of the significant location change that triggered the background app launch,
            // and will continue to execute for any future significant location change events as well (unless canceled).
        }];
    }
    return YES;
}
```

### Managing Active Requests or Subscriptions
When issuing a location request, you can optionally store the request ID, which allows you to force complete or cancel the request at any time:
```objective-c
INTULocationManager *locMgr = [INTULocationManager sharedInstance];
INTULocationRequestID requestID = [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyHouse
                                                                     timeout:5.0
                                                                       block:locationRequestBlock];

// Force the request to complete early, like a manual timeout (will execute the block)
[[INTULocationManager sharedInstance] forceCompleteLocationRequest:requestID];

// Cancel the request (won't execute the block)
[[INTULocationManager sharedInstance] cancelLocationRequest:requestID];
```

Note that subscriptions never timeout; calling `forceCompleteLocationRequest:` on a subscription will simply cancel it.

### Subscribing to Continuous Heading Updates
To subscribe to continuous heading updates, use the method `subscribeToHeadingUpdatesWithBlock:`. This method does not set any default heading filter value, but you can do so using the `headingFilter` property on the manager instance. It also does not filter based on accuracy of the result, but rather leaves it up to you to check the returned `CLHeading` object's `headingAccuracy` property to determine whether or not it is acceptable. 

The block will execute indefinitely (until canceled), once for every new updated heading regardless of its accuracy. Note that if heading requests are removed or canceled, the manager will automatically stop updating the device heading in order to preserve battery life.

If an error occurs, the block will execute with a status other than `INTUHeadingStatusSuccess`, and the subscription will only be automatically canceled if the device doesn't have heading support (i.e. for status `INTUHeadingStatusUnavailable`).

Here's an example:
```objective-c
INTULocationManager *locMgr = [INTULocationManager sharedInstance];
[locMgr subscribeToHeadingUpdatesWithBlock:^(CLHeading *heading, INTUHeadingStatus status) {
    if (status == INTUHeadingStatusSuccess) {
        // An updated heading is available
        NSLog(@"'Heading updates' subscription block called with Current Heading:\n%@", heading);
    } else {
        // An error occurred, more info is available by looking at the specific status returned. The subscription will be canceled only if the device doesn't have heading support.
    }
}];
```

## Example Project
Open the [project](LocationManager) included in the repository (requires Xcode 6 and iOS 8.0 or later). It contains a `LocationManagerExample` scheme that will run a simple demo app. Please note that it can run in the iOS Simulator, but you need to go to the iOS Simulator's **Debug > Location** menu once running the app to simulate a location (the default is **None**).

## Issues & Contributions
Please [open an issue here on GitHub](https://github.com/intuit/LocationManager/issues/new) if you have a problem, suggestion, or other comment.

Pull requests are welcome and encouraged! There are no official guidelines, but please try to be consistent with the existing code style.

## License
INTULocationManager is provided under the MIT license.

# INTU on GitHub
Check out more [iOS and OS X open source projects from Intuit](https://github.com/search?utf8=✓&q=user%3Aintuit+language%3Aobjective-c&type=Repositories&ref=searchresults)!
