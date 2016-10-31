BBBadgeBarButtonItem
==============

<p>Create a BarButtonItem with a badge on top. Easily customizable.
Your BarButtonItem can be any custom view you wish for. The badge on top can display any number or string of any size or length.</p>

<img alt="ScreenShot BarButtonItem" src="https://github.com/TanguyAladenise/BBBadgeBarButtonItem/blob/master/screenshot.png?raw=true" width="320px"/>


How To Get Started
------------------

#### Installation with CocoaPods

Use the CocoaPods magic by adding in your podfile the following line :

```ruby
pod 'BBBadgeBarButtonItem'
```

#### Manually

It's quite easy, just download and add "BBBadgeBarButtonItem.h" and "BBBadgeBarButtonItem.m" into your xcodeproject.
Don't forget to import the header file wherever you need it :

``` objective-c
#import "BBBadgeBarButtonItem.h"
```

Usage
------------------

Then, you only need to instantiate your beautiful BBBadgeBarButtonItem and add it to your navigation bar :

``` objective-c
UIButton *customButton = [[UIButton alloc] init];
//...

// Create and add our custom BBBadgeBarButtonItem
BBBadgeBarButtonItem *barButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:customButton];
// Set a value for the badge
barButton.badgeValue = @"1";

// Add it as the leftBarButtonItem of the navigation bar
self.navigationItem.leftBarButtonItem = barButton;
```

If you want your BarButtonItem to handle touch event and click, use a UIButton as customView.
The icon or text displayed by the BarButtonItem is your custom view.


Useful properties
---------------

Take a look at BBBadgeBarButtonItem.h to see how easily and quickly you can customize the badge.
Remember that each time you change one of these value, the badge will directly be refresh to handle your styling preferences.

``` objective-c
// Each time you change one of properties, the badge will refresh with your changes

// Badge value to be display
@property (nonatomic) NSString *badgeValue;
// Badge background color
@property (nonatomic) UIColor *badgeBGColor;
// Badge text color
@property (nonatomic) UIColor *badgeTextColor;
// Badge font
@property (nonatomic) UIFont *badgeFont;

// Padding value for the badge
@property (nonatomic) CGFloat badgePadding;
// Minimum size badge to small
@property (nonatomic) CGFloat badgeMinSize;
// Values for offseting the badge over the BarButtonItem you picked
@property (nonatomic) CGFloat badgeOriginX;
@property (nonatomic) CGFloat badgeOriginY;

// In case of numbers, remove the badge when reaching zero
@property BOOL shouldHideBadgeAtZero;
// Badge has a bounce animation when value changes
@property BOOL shouldAnimateBadge;
```

You can also choose to turn off the little bounce animation triggered when changing the badge value or decide if 0 should be display or not.

What else ?
---------------

The class is compatible with iOS >= 6.0.

There is a little demo project to help you if you need ;)


More
----

<p>Any suggestions are welcome ! as I am looking to learn good practices, to understand better behaviors and Objective-C in general !
Thank you.</p>

