# MDFInternationalization

MDFInternationalization assists in internationalizing your iOS app or components' user interface.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/material-foundation/material-internationalization-ios/blob/develop/LICENSE)
[![GitHub release](https://img.shields.io/github/release/material-foundation/material-internationalization-ios.svg)](https://github.com/material-foundation/material-internationalization-ios/releases)
[![Build Status](https://travis-ci.org/material-foundation/material-internationalization-ios.svg?branch=stable)](https://travis-ci.org/material-foundation/material-internationalization-ios)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/MDFInternationalization.svg)](https://img.shields.io/cocoapods/v/MDFInternationalization.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Right-to-Left calculations for CGRects and UIEdgeInsets

A UIView is positioned within its superview in terms of a frame (CGRect) consisting of an
origin and a size. When a device is set to a language that is written from Right-to-Left (RTL),
we often want to mirror the interface around the vertical axis. This library contains
functions to assist in modifying frames and edge insets for RTL.

``` obj-c
// To flip a subview's frame horizontally, pass in subview.frame and the width of its parent.
CGRect originalFrame = childView.frame;
CGRect flippedFrame = MDFRectFlippedHorizontally(originalFrame, CGRectGetWidth(self.bounds));
childView.frame = flippedFrame;
```

## Mirroring Images

A category on UIImage backports iOS 10's `[UIImage imageWithHorizontallyFlippedOrientation]` to
earlier versions of iOS.

``` obj-c
// To mirror on image, invoke mdf_imageWithHorizontallyFlippedOrientation.
UIImage *mirroredImage = [originalImage mdf_imageWithHorizontallyFlippedOrientation];
```

## Adding semantic context

A category on UIView backports iOS 9's `-[UIView semanticContentAttribute]` and iOS 10's
`-[UIView effectiveUserInterfaceLayoutDirection]` to earlier versions of iOS.

``` obj-c
// To set a semantic content attribute, set the mdf_semanticContentAttribute property.
lockedLTRView.mdf_semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;

// mdf_semanticContentAttribute is used to calculate the mdf_effectiveUserInterfaceLayoutDirection
if (customView.mdf_effectiveUserInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
  // Update customView's layout to be in RTL mode.
}
```

## Embedding Bidirection strings

A category on NSString offers a simple API to wrap strings in Unicode markers so that LTR
and RTL text can co-exist in the same string.

``` obj-c
// To embed an RTL string in an existing LTR string we should wrap it in Unicode directionality
// markers to  maintain preoper rendering.

// The name of a restaurant is in Arabic or Hebrew script, but the rest of string is in Latin.
NSString *wrappedRestaurantName =
    [restaurantName mdf_stringWithStereoReset:NSLocaleLanguageDirectionRightToLeft
                                      context:NSLocaleLanguageDirectionLeftToRight];

NSString *reservationString = [NSString stringWithFormat:@"%@ : %ld", wrappedRestaurantName, attendees];
```

## Usage

See Examples/Flags for a detailed example of how to use the functionality provided by this library.


## License

MDFInternationalization is licensed under the [Apache License Version 2.0](LICENSE).
