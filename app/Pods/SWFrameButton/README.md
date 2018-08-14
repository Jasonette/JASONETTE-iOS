# SWFrameButton

This UIButton subclass replicate single line border button see in iOS 7 App Store.

![Screenshot](/Documentation/Images/demo.gif)

## Installation

SWFrameButton is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "SWFrameButton"

You may also quickly try the SWFrameButton example project with

    pod try SWFrameButton

## Requirements

Requires iOS 7.0+ and ARC.

## Usage

SWFrameButton design to use `tintColor` to determine its color, so try to avoid set text color by `setTitleColor:forState:` it won't break your button, but may raise inconsistent highlighted/selected color state. `Text Color` property in Interface Builder will be ignore for this reason, use `Tint` property in view section instead.

Basic usage
```objective-c
SWFrameButton *button = [[SWFrameButton alloc] init];
[button setTitle:@"Green Tint Button" forState:UIControlStateNormal];
[button sizeToFit];
button.tintColor = [UIColor greenColor];
```

If you use Interface Builder, add a UIBUtton to your interface and set Class to `SWFrameButton`.

![Use with storyboard](/Documentation/Images/use-with-storyboard.png)

### Customization
You can use customize SWFrameButton using UIAppearance
```objective-c
[[SWFrameButton appearance] setTintColor:[UIColor orangeColor]];
[[SWFrameButton appearance] setBorderWidth:1];
[[SWFrameButton appearance] setCornerRadius:10];
```
or set individual button style via property
```objective-c
SWFrameButton *button = [[SWFrameButton alloc] init];
button.tintColor = [UIColor orangeColor];
button.borderWidth = 1;
button.corderRadius = 10;
```

## Author

[Sarun Wongpatcharapakorn](https://github.com/sarunw) ([@sarunw](https://twitter.com/sarunw))

## License

SWFrameButton is available under the MIT license. See the LICENSE file for more info.
