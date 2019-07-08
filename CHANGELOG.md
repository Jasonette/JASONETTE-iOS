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

### Changed

- Improved `JasonComponentFactory.h` to take in consideration `Swift` extensions.

- Establish `AppDelegate.h` as main *App Delegate* instead of `JasonAppDelegate.h`. The later will serve as a wrapper.

- Improved Code Organization.

### Fixed

- Fixed Crash on parsing local json files with wrong syntax.
- Fixed Crash when no `$jason` property is present in json.
- Fixed Crash when url contained html content in a json expected return.
- Fixed Blank Screen when no `url` is found in `settings.plist`.
- Fixed Blank Screen if you click a `Tab Item` more than once.


### Removed

### Notes

This version is a complete overhaul focusing on 
modularization of the code and update of the libraries, improving the quality of the framework, maintaining the same json api.

## [1.0](https://github.com/jasonelle/jasonelle/releases/tag/v1.0)

First version of the *Jasonette* Mobile Framework.
