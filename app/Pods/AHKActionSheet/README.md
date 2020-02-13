# AHKActionSheet
[![License: MIT](https://img.shields.io/badge/license-MIT-red.svg?style=flat)](https://github.com/fastred/AHKActionSheet/blob/master/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/AHKActionSheet.svg?style=flat)](https://github.com/fastred/AHKActionSheet)

An alternative to the UIActionSheet with a block-based API and a customizable look. Inspired by the Spotify app. It looks a lot better live than on the GIF (because compression).

![Demo GIF](https://raw.githubusercontent.com/fastred/AHKActionSheet/master/example.gif)

## Features

 * Modern, iOS 7 look
 * Block-based API
 * Highly customizable
 * Gesture-driven navigation with two ways to hide the control: either quick flick down or swipe and release (at the position when the blur is starting to fade)
 * Use a simple label or a completely custom view above the buttons
 * Use with or without icons (text can be optionally centered)
 * Status bar style matches the one from the presenting controller

## Demo

Build and run the `AHKActionSheetExample` project in Xcode. `AHKViewController.m` file contains the important code used in the example.

## Requirements

 * iOS 6.0 and above
 * ARC
 * Optimized for iPhone

## Installation
### CocoaPods

AHKActionSheet is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "AHKActionSheet"
### Manual
Copy all files from `Classes/` directory to your project. Then, add `QuartzCore.framework` to your project.

## Usage
A simple example:

```obj-c
#import "AHKActionSheet.h"
...
AHKActionSheet *actionSheet = [[AHKActionSheet alloc] initWithTitle:nil];
[actionSheet addButtonWithTitle:@"Test" type:AHKActionSheetButtonTypeDefault handler:^(AHKActionSheet *as) {
    NSLog(@"Test tapped");
}];
[actionSheet show];
```

The view is customizable either directly or through a UIAppearance API. See the header file (`Classes/AHKActionSheet.h`) and the example project to learn more.

## Changelog

0.5.4

* Fix `cancelOnTapEmptyAreaEnabled` behavior

0.5.3

* Added `cancelOnTapEmptyAreaEnabled` property
* Updated the project to compile cleanly on Xcode 7

0.5.2

* Fixed visible cancel button even though its height was set to 0.

0.5.1

* Fixed issues with separators on iOS 8

0.5

* Fixed bugs on iOS 8

0.4.2

* Fixed incorrect orientation of the blurred snapshot on iOS 8

0.4.1

* Improved dismissal error handling

0.4.0

* Added a new button type: `AHKActionSheetButtonTypeDisabled`
* Added `cancelOnPanGestureEnabled` property, which allows you to disable:
  > Gesture-driven navigation with two ways to hide the control: either quick flick down or swipe and release (at the position when the blur is starting to fade)
* Internal scroll view's `bounces` is now disabled when `cancelOnPanGestureEnabled` is turned off and when the scroll view's `contentSize`'s height is smaller than the screen's height.

0.3.0

* Added iOS 6 support

0.2.0

* Added `animationDuration` property
* Added some basic unit tests
* Improved comments in the header file

0.1.3

* Ready for projects with [more warnings](https://github.com/boredzo/Warnings-xcconfig/wiki/Warnings-Explained) enabled

0.1.2

* `UIWindow` is now snapshotted instead of `UIViewController's` `view`

0.1.1

* Refactorings
* Bug fixes

0.1.0

* Initial release

## Author

Arkadiusz Holko:

* [Blog](http://holko.pl/)
* [@arekholko on Twitter](https://twitter.com/arekholko)
