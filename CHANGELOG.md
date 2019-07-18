# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Sentimental Versioning](http://sentimentalversioning.org/).

## [2.0.0] Next Release

This version is the current in development.

### Added

- New Logger for Native Code. Makes easier to Spot Errors. See [xcode/Jasonette/Logger/README.md](xcode/Jasonette/Logger/README.md) For more details.

- Added `JasonNetworking.h` to enable configuring `AFHTTPSessionManager` and `AFJSONResponseSerializer`.

- Docs on how to implement extensions.

- Added [`uncrustify`](http://uncrustify.sourceforge.net/) config for code style standarization.

- Added new option in `href` to load a `web` with `reader mode`.
Based on the code by `@seletz`.

```json
{
    "options": {
        "reader": true
    }
}
```

- Added `$orientation` system event
that triggers when the orientation changes.

### Changed

- Bumped to minimum iOS version `9.0`.

- Improved `JasonComponentFactory.h` to take in consideration `Swift` extensions.

- Establish `AppDelegate.h` as main *App Delegate* instead of `JasonAppDelegate.h`. The later will serve as a wrapper.

- Improved Code Organization.

### Fixed

- Fixed Crash on parsing local json files with wrong syntax.

- Fixed Crash when no `$jason` property is present in json.

- Fixed Crash when url contained html content in a json expected return.

- Fixed Blank Screen when no `url` is found in `settings.plist`.

- Fixed Blank Screen if you click a `Tab Item` more than once.

- Fixed `WKWebView` orientation change not working. Based on the code by `@ricardojlpinto`.

### Updated

- Updated to `AFNetworking` 3.2.1 (was 3.1.0).

- Updated to `UICKeyChainStore` 2.1.2 (was 2.1.0).

- Updated to `IQAudioRecorderController` 1.2.3 (was 1.2.0).

- Updated to `SBJsonWriter` 5.0.0 (was 4.0.2).

- Updated to `libPhoneNumber-iOS` 0.9.15 (was 0.8.13).

- Updated to `JDStatusBarNotification` 1.6.0 (was 1.5.3).

- Updated to `APAddressBook` 0.3.2 (was 0.2.3).

- Updated to `MBProgressHUD` 1.1.0 (was 1.0.0).

- Updated to `NSGIF` 1.2.4 (was 1.2).

- Updated to `NSHash` 1.2.0 (was 1.1.0).

- Updated to `DTCoreText` 1.6.22 (was 1.6.17).

- Updated to `DTFoundation` 1.7.13 (was 1.7.10).

### Removed

- Nothing

### Notes

This version is a complete overhaul focusing on 
modularization of the code and update of the libraries, improving the quality of the framework, maintaining the same json api.

### People

Huge thanks to the following persons that helped in this release:

- [Adán Miranda](https://github.com/takakeiji): Helped with some guidance over iOS code.

- `BSG`: Detected layout error in WKWebViews in iOS >= 11.

- `John Mark`: Wrote a great tutorial in Bubble.is forums.

- [Devs Chile](https://devschile.cl): Chilean commmunity of developers.

## [1.0](https://github.com/jasonelle/jasonelle/releases/tag/v1.0)

First version of the *Jasonette* Mobile Framework.
