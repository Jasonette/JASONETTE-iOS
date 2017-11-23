# Valet

[![CI Status](https://travis-ci.org/square/Valet.svg?branch=master)](https://travis-ci.org/square/Valet)
[![Carthage Compatibility](https://img.shields.io/badge/carthage-✓-e2c245.svg)](https://github.com/Carthage/Carthage/)
[![Version](https://img.shields.io/cocoapods/v/Valet.svg)](http://cocoadocs.org/docsets/Valet)
[![License](https://img.shields.io/cocoapods/l/Valet.svg)](http://cocoadocs.org/docsets/Valet)
[![Platform](https://img.shields.io/cocoapods/p/Valet.svg)](http://cocoadocs.org/docsets/Valet)

Valet lets you securely store data in the iOS or OS X Keychain without knowing a thing about how the Keychain works. It’s easy. We promise.

## Getting Started

### CocoaPods

To install Valet in your iOS or OS X project, install with [CocoaPods](http://cocoapods.org)

on iOS:

```
platform :ios, '6.0'
pod 'Valet'
```

on OS X:

```
platform :osx, '10.10'
pod 'Valet'
```


### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Valet into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "Square/Valet"
```

Run `carthage` to build the framework and drag the built `Valet.framework` into your Xcode project.

### Submodules

Or manually checkout the submodule with `git submodule add git@github.com:Square/Valet.git`, drag Valet.xcodeproj to your project, and add Valet as a build dependency.

## Usage

### Basic Initialization

```objc
VALValet *myValet = [[VALValet alloc] initWithIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

To begin storing data securely using Valet, you need to create a VALValet instance with:

* An identifier – a string that is used to identify this Valet.
* An accessibility value – an enum ([VALAccessibility](Valet/VALValet.h)) that defines when you will be able to store and retrieve data.

This instance can be used to store and retrieve data securely, but only when the device is unlocked.

#### Choosing the Best Accessibility Value

The VALAccessibility enum is used to determine when your secrets can be accessed. It’s a good idea to use the strictest accessibility possible that will allow your app to function. For example, if your app does not run in the background you will want to ensure the secrets can only be read when the phone is unlocked by using `VALAccessibilityWhenUnlocked` or `VALAccessibilityWhenUnlockedThisDeviceOnly`.

### Reading and Writing

```objc
NSString *const username = @"Skroob";
[myValet setString:@"12345" forKey:username];
NSString *const myLuggageCombination = [myValet stringForKey:username];
```

Valet’s API for securely reading and writing data is similar to that of an NSMapTable; use `-setObject:forKey:` and `-setString:forKey:` to write objects and `-objectForKey:` and `-stringForKey:` to read objects. Valets created with a different class type, via a different initializer, or with a different identifier or accessibility attribute will not be able to read or modify values in `myValet`.

### Sharing Secrets Among Multiple Applications

```objc
VALValet *mySharedValet = [[VALValet alloc] initWithSharedAccessGroupIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

This instance can be used to store and retrieve data securely across any app written by the same developer with the value `Druidia` under the `keychain-access-groups` key in the app’s `Entitlements` file, when the device is unlocked. `myValet` and `mySharedValet` can not read or modify one another’s values because the two Valets were created with different initializers. You can use the `-initWithSharedAccessGroupIdentifier:accessibility:` initializer on any Valet class to allow for sharing secrets across applications written by the same developer.

### Sharing Secrets Across Devices with iCloud

```objc
VALSynchronizableValet *mySynchronizableValet = [[VALSynchronizableValet alloc] initWithIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

This instance can be used to store and retrieve data that can be retrieved by this app on other devices logged into the same iCloud account with iCloud Keychain enabled. `mySynchronizableValet` can not read or modify values in `myValet` or `mySharedValet` because `mySynchronizableValet` is of a different class type. If iCloud Keychain is not enabled on this device, secrets can still be read and written, but will not sync to other devices.

### Protecting Secrets with Touch ID or device Passcode

```objc
VALSecureEnclaveValet *mySecureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:@"Druidia" accessControl:VALAccessControlUserPresence];
```

This instance can be used to store and retrieve data in the Secure Enclave (available on iOS 8.0 and later and Mac OS 10.11 and later). Each time data is retrieved from this Valet, the user will be prompted to confirm their presence via Touch ID or by entering their device passcode. *If no passcode is set on the device, this instance will be unable to access or store data.* Data is removed from the Secure Enclave when the user removes a passcode from the device. Storing data using VALSecureEnclaveValet is the most secure way to store data on either iOS or Mac OS.

```objc
VALSinglePromptSecureEnclaveValet *mySecureEnclaveValet = [[VALSinglePromptSecureEnclaveValet alloc] initWithIdentifier:@"Druidia" accessControl:VALAccessControlUserPresence];
```

This instance also stores and retrieves data in the Secure Enclave, but does not require the user to confirm their presence each time data is retrieved. Instead, the user will be prompted to confirm their presence only on the first data retrieval. A `VALSinglePromptSecureEnclaveValet` instance can be forced to prompt the user on the next data retrieval by calling the instance method `requirePromptOnNextAccess`.

### Migrating Existing Keychain Values into Valet

Already using the Keychain and no longer want to maintain your own Keychain code? We feel you. That’s why we wrote `-migrateObjectsMatchingQuery:removeOnCompletion:`. This method allows you to migrate all your existing Keychain entries to a Valet instance in one line. Just pass in an NSDictionary with the `kSecClass`, `kSecAttrService`, and any other `kSecAttr*` attributes you use – we’ll migrate the data for you.

### Debugging

Valet guarantees it will never fail to write to or read from the keychain unless `canAccessKeychain` returns `NO`. There are only a few cases that can lead to the keychain being inaccessible:

1. Using the wrong `VALAccessibility` for your use case. Examples of improper use include using `VALAccessibilityWhenPasscodeSetThisDeviceOnly` when there is no passcode set on the device, or using `VALAccessibilityWhenUnlocked` when running in the background.
2. Initializing a Valet with `initWithSharedAccessGroupIdentifier:` when the shared access group identifier is not in your entitlements file.
3. Using `VALSecureEnclaveValet` on an iOS device that doesn't have a Secure Enclave. The Secure Enclave was introduced with the [A7 chip](https://www.apple.com/business/docs/iOS_Security_Guide.pdf), which [first appeared](https://en.wikipedia.org/wiki/Apple_A7#Products_that_include_the_Apple_A7) in the iPhone 5S, iPad Air, and iPad Mini 2.
4. Running your app in DEBUG from Xcode. Xcode sometimes does not properly sign your app, which causes a [failure to access keychain](https://github.com/square/Valet/issues/10#issuecomment-114408954) due to entitlements. If you run into this issue, just hit Run in Xcode again. This signing issue will not occur in properly signed (not DEBUG) builds.
5. Running your app on device or in the simulator with a debugger attached may also [cause an entitlements error](https://forums.developer.apple.com/thread/4743) to be returned when reading from or writing to the keychain. To work around this issue on device, run the app without the debugger attached. After running once without the debugger attached the keychain will usually behave properly for a few runs with the debugger attached before the process needs to be repeated.
6. Running your app or unit tests without the application-identifier entitlement. Xcode 8 introduced a requirement that all schemes must be signed with the application-identifier entitlement to access the keychain. To satisfy this requirement when running unit tests, your unit tests must be run inside of a host application.

## Requirements

* Xcode 6.3 or later. Earlier versions of Xcode require [Valet version 1.2.1](https://github.com/square/Valet/tree/1f587a82bed724e75c63f9254287016b51d31ced).
* iOS 6 or later.
* OS X 10.10 or later.

## Contributing

We’re glad you’re interested in Valet, and we’d love to see where you take it. Please read our [contributing guidelines](Contributing.md) prior to submitting a Pull Request.

Thanks, and please *do* take it for a joyride!
