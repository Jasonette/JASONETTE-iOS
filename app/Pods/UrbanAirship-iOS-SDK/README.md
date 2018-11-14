# iOS Urban Airship SDK

The Urban Airship SDK for iOS provides a simple way to integrate Urban Airship
services into your iOS applications.

## Contributing Code

We accept pull requests! If you would like to submit a pull request, please fill out and submit a
Code Contribution Agreement (http://docs.urbanairship.com/contribution-agreement.html).

## Resources

- [AirshipKit Docs](http://docs.urbanairship.com/reference/libraries/ios/latest/)
- [AirshipAppExtensions Docs](http://docs.urbanairship.com/reference/libraries/ios-extensions/latest/)
- [Getting started guide](http://docs.urbanairship.com/platform/ios/)
- [Migration Guides](Documentation/Migration)
- [Sample Quickstart Guide](Sample/README.md)
- [Swift Sample Quickstart Guide](SwiftSample/README.md)

## Installation

Xcode 8.0+ is required for all projects and the static library. Projects must target >= iOS8.

### CocoaPods

Make sure you have the [CocoaPods](http://cocoapods.org) dependency manager installed. You can do so by executing the following command:

```sh
$ gem install cocoapods
```

Specify the UrbanAirship-iOS-SDK in your podfile with the use_frameworks! option:

```txt
use_frameworks!

# Urban Airship SDK
target "<Your Target Name>" do
  pod 'UrbanAirship-iOS-SDK'
end
```

Install using the following command:

```sh
$ pod install
```

In order to take advantage of iOS 10 notification attachments, you will need to create a notification service extension
alongside your main application. Most of the work is already done for you, but since this involves creating a new target there
are a few additional steps. First create a new "Notification Service Extension" target. Then add the UrbanAirship-iOS-AppExtensions
to the new target:

```txt
use_frameworks!

# Urban Airship SDK
target "<Your Service Extension Target Name>" do
  pod 'UrbanAirship-iOS-AppExtensions'
end
```

Install using the following command:

```sh
$ pod install
```

Then delete all the dummy source code for the new extension and have it inherit from UAMediaAttachmentExtension:

```
import AirshipAppExtensions

class NotificationService: UAMediaAttachmentExtension {

}
```

### Carthage

Make sure you have [Carthage](https://github.com/Carthage/Carthage) installed. Carthage can be installed using Homebrew with the following commands:
```sh
$ brew update
$ brew install carthage
```

Specify the Urban Airship iOS SDK in your cartfile:

```txt
github "urbanairship/ios-library"
```

Execute the following command in the same directory as the cartfile:

```sh
$ carthage update
```

In order to take advantage of iOS 10 notification attachments, you will need to create a notification service extension
alongside your main application. Most of the work is already done for you, but since this involves creating a new target there
are a few additional steps:

* Create a new iOS target in Xcode and select the "Notification Service Extension" type
* Drag the new AirshipAppExtensions.framework into your app project
* Link against AirshipAppExtensions.framework in your extension's Build Phases
* Add a Copy Files phase for AirshipAppExtensions.framework and select "Frameworks" as the destination
* Delete all dummy source code for your new extension
* Inherit from `UAMediaAttachmentExtension` in `NotificationService`

### Other Installation Methods

For other installation methods, please checkout - [Getting started guide](http://docs.urbanairship.com/platform/ios.html#installation).


## Quickstart

### Capabilities

Enable Push Notifications and Remote Notifications Background mode under the capabilties section for
the main application target.

### Adding an Airship Config File

The library uses a .plist configuration file named `AirshipConfig.plist` to manage your production and development
application profiles. Example copies of this file are available in all of the sample projects. Place this file
in your project and set the following values to the ones in your application at http://go.urbanairship.com.  To
view all the possible keys and values, see the [UAConfig class reference](http://docs.urbanairship.com/reference/libraries/ios/latest/Classes/UAConfig.html)

You can also edit the file as plain-text:

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>detectProvisioningMode</key>
      <true/>
      <key>developmentAppKey</key>
      <string>Your Development App Key</string>
      <key>developmentAppSecret</key>
      <string>Your Development App Secret</string>
      <key>productionAppKey</key>
      <string>Your Production App Key</string>
      <key>productionAppSecret</key>
      <string>Your Production App Secret</string>
    </dict>
    </plist>
```

The library will auto-detect the production mode when setting `detectProvisioningMode` to `true`.

Advanced users may add scripting or preprocessing logic to this .plist file to automate the switch from
development to production keys based on the build type.

### Call Takeoff

To enable push notifications, you will need to make several additions to your application delegate.

```obj-c
    - (BOOL)application:(UIApplication *)application
            didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

        // Your other application code.....

        // Set log level for debugging config loading (optional)
        // It will be set to the value in the loaded config upon takeOff
        [UAirship setLogLevel:UALogLevelTrace];

        // Populate AirshipConfig.plist with your app's info from https://go.urbanairship.com
        // or set runtime properties here.
        UAConfig *config = [UAConfig defaultConfig];

        // You can then programmatically override the plist values:
        // config.developmentAppKey = @"YourKey";
        // etc.

        // Call takeOff (which creates the UAirship singleton)
        [UAirship takeOff:config];

        // Print out the application configuration for debugging (optional)
        UA_LDEBUG(@"Config:\n%@", [config description]);

        // Set the icon badge to zero on startup (optional)
        [[UAirship push] resetBadge];

        // User notifications will not be enabled until userPushNotificationsEnabled is
        // set YES on UAPush. Once enabled, the setting will be persisted and the user
        // will be prompted to allow notifications. You should wait for a more appropriate
        // time to enable push to increase the likelihood that the user will accept
        // notifications.
        // [UAirship push].userPushNotificationsEnabled = YES;

        return YES;
    }
```

To enable push later on in your application:

```obj-c
    // Somewhere in the app, this will enable push (setting it to NO will disable push,
    // which will trigger the proper registration or de-registration code in the library).
    [UAirship push].userPushNotificationsEnabled = YES;
```

## SDK Development

Make sure you have the CocoaPods dependency manager installed. You can do so by executing the following command:

```sh
$ gem install cocoapods
```

Install the pods:

```sh
$ pod install
```

Open Airship.xcworkspace

```sh
$ open Airship.xcworkspace
```

Update the Samples AirshipConfig by copying`AirshipConfig.plist.sample` to `AirshipConfig.plist` and update
the app's credentials. You should now be able to build, run tests, and run the samples.

The distribution can be generated by running the build.sh script:

```sh
./scripts/build.sh
```

Jenkins will run `run_ci_tasks.sh` for every PR submitted. Jenkin's Xcode version can be
set by updating `jenkins-enviornment.properties` file.

## Third Party Packages

### Core Library

Third party Package | License   | Copyright / Creator
------------------- | --------- | -----------------------------------
Base64              | BSD       | Copyright 2009-2010 Matt Gallagher.

### Test Code

Third party Package | License   | Copyright / Creator
------------------- | --------- | -----------------------------------
JRSwizzle           | MIT       | Copyright 2012 Jonathan Rentzsch



