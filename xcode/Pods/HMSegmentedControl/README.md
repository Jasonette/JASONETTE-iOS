HMSegmentedControl
===

[![CocoaPods](https://img.shields.io/cocoapods/dt/HMSegmentedControl.svg?maxAge=2592000)](https://cocoapods.org/pods/HMSegmentedControl)
[![Pod Version](http://img.shields.io/cocoapods/v/HMSegmentedControl.svg?style=flat)](http://cocoadocs.org/docsets/HMSegmentedControl)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Pod Platform](http://img.shields.io/cocoapods/p/HMSegmentedControl.svg?style=flat)](http://cocoadocs.org/docsets/HMSegmentedControl)
[![Pod License](http://img.shields.io/cocoapods/l/HMSegmentedControl.svg?style=flat)](http://opensource.org/licenses/MIT)

A drop-in replacement for UISegmentedControl mimicking the style of the segmented control used in Google Currents and various other Google products.

# Features
- Supports both text and images
- Support horizontal scrolling
- Supports advanced title styling with text attributes for font, color, kerning, shadow, etc.
- Supports selection indicator both on top and bottom
- Supports blocks
- Works with ARC and iOS >= 7

# Installation

### CocoaPods
The easiest way of installing HMSegmentedControl is via [CocoaPods](http://cocoapods.org/). 

```
pod 'HMSegmentedControl'
```

### Old-fashioned way

- Add `HMSegmentedControl.h` and `HMSegmentedControl.m` to your project.
- Add `QuartzCore.framework` to your linked frameworks.
- `#import "HMSegmentedControl.h"` where you want to add the control.

# Usage

The code below will create a segmented control with the default looks:

```  objective-c
HMSegmentedControl *segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"One", @"Two", @"Three"]];
segmentedControl.frame = CGRectMake(10, 10, 300, 60);
[segmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
[self.view addSubview:segmentedControl];
```

Included is a demo project showing how to fully customise the control.

![HMSegmentedControl](https://raw.githubusercontent.com/HeshamMegid/HMSegmentedControl/master/Screenshot.png)

# Apps using HMSegmentedControl

If you are using HMSegmentedControl in your app or know of an app that uses it, please add it to [this list](https://github.com/HeshamMegid/HMSegmentedControl/wiki/Apps-using-HMSegmentedControl).
  

# License

HMSegmentedControl is licensed under the terms of the MIT License. Please see the [LICENSE](LICENSE.md) file for full details.

If this code was helpful, I would love to hear from you.

[@HeshamMegid](http://twitter.com/HeshamMegid)   
[http://hesh.am](http://hesh.am)
