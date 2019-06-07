# JDStatusBarNotification

Show messages on top of the status bar. Customizable colors, font and animation. Supports progress display and can show an activity indicator. iOS 7/8 ready. iOS6 support. Please open a [Github issue], if you think anything is missing or wrong.

![Animation](gfx/animation.gif "Animation")

![Screenshots](gfx/screenshots.png "Screenshots")

## Installation

#### Cocoapods:

`pod 'JDStatusBarNotification'`

(For infos on cocoapods, have a look at the [cocoapods website])

#### Manually:

1. Drag the `JDStatusBarNotification/JDStatusBarNotification` folder into your project.
2. Add `#include "JDStatusBarNotification.h"`, where you want to use it

## Usage

JDStatusBarNotification is a singleton. You don't need to initialize it anywhere.
Just use the following class methods:

### Showing a notification
    
    + (JDStatusBarView*)showWithStatus:(NSString *)status;
    + (JDStatusBarView*)showWithStatus:(NSString *)status
                          dismissAfter:(NSTimeInterval)timeInterval;

The return value will be the notification view. You can just ignore it, but if you need further customization, this is where you can access the view.

### Dismissing a notification

    + (void)dismiss;
    + (void)dismissAfter:(NSTimeInterval)delay;
    
### Showing progress

![Progress animation](gfx/progress.gif "Progress animation")

    + (void)showProgress:(CGFloat)progress;  // Range: 0.0 - 1.0
    
### Showing activity

![Activity screenshot](gfx/activity.gif "Activity screenshot")

    + (void)showActivityIndicator:(BOOL)show
                   indicatorStyle:(UIActivityIndicatorViewStyle)style;
    
### Showing a notification with alternative styles

Included styles:

![](gfx/styles.png)

Use them with the following methods:

    + (JDStatusBarView*)showWithStatus:(NSString *)status
                             styleName:(NSString*)styleName;

    + (JDStatusBarView*)showWithStatus:(NSString *)status
                          dismissAfter:(NSTimeInterval)timeInterval
                             styleName:(NSString*)styleName;
                 
To present a notification using a custom style, use the `identifier` you specified in `addStyleNamed:prepare:`. See Customization below.

### Beware

[@goelv](https://github.com/goelv) / [@dskyu](https://github.com/dskyu) / [@graceydb](https://github.com/graceydb) informed me (see [#15](https://github.com/jaydee3/JDStatusBarNotification/issues/15), [#30](https://github.com/jaydee3/JDStatusBarNotification/issues/30), [#49](https://github.com/jaydee3/JDStatusBarNotification/issues/49)), that his app got rejected because of a status bar overlay (for violating 10.1/10.3). So don't overuse it. Although I haven't heard of any other cases.

## Customization

    + (void)setDefaultStyle:(JDPrepareStyleBlock)prepareBlock;
    
    + (NSString*)addStyleNamed:(NSString*)identifier
                       prepare:(JDPrepareStyleBlock)prepareBlock;


The `prepareBlock` gives you a copy of the default style, which can be modified as you like:

	[JDStatusBarNotification addStyleNamed:<#identifier#>
	                               prepare:^JDStatusBarStyle*(JDStatusBarStyle *style) {
	                               
                                       // main properties
	                                   style.barColor = <#color#>;
	                                   style.textColor = <#color#>;
	                                   style.font = <#font#>;
	                                   
                                       // advanced properties
	                                   style.animationType = <#type#>;
	                                   style.textShadow = <#shadow#>;
	                                   style.textVerticalPositionAdjustment = <#adjustment#>;

                                       // progress bar
                                       style.progressBarColor = <#color#>;
                                       style.progressBarHeight = <#height#>;
                                       style.progressBarPosition = <#position#>;

	                                   return style;
	                               }];

#### Animation Types

- `JDStatusBarAnimationTypeNone`
- `JDStatusBarAnimationTypeMove`
- `JDStatusBarAnimationTypeBounce`
- `JDStatusBarAnimationTypeFade`

#### Progress Bar Positions

- `JDStatusBarProgressBarPositionBottom`
- `JDStatusBarProgressBarPositionCenter`
- `JDStatusBarProgressBarPositionTop`
- `JDStatusBarProgressBarPositionBelow`
- `JDStatusBarProgressBarPositionNavBar`

## Twitter

I'm [@jaydee3](http://twitter.com/jaydee3) on Twitter. Feel free to [post a tweet](https://twitter.com/intent/tweet?button_hashtag=JDStatusBarNotification&text=Simple%20and%20customizable%20statusbar%20notifications%20for%20iOS!%20Check%20it%20out.%20https://github.com/jaydee3/JDStatusBarNotification&via=jaydee3), if you like JDStatusBarNotification.  

[![TweetButton](gfx/tweetbutton.png "Tweet")](https://twitter.com/intent/tweet?button_hashtag=JDStatusBarNotification&text=Simple%20and%20customizable%20statusbar%20notifications%20for%20iOS!%20Check%20it%20out.%20https://github.com/jaydee3/JDStatusBarNotification&via=jaydee3)

[Github issue]: https://github.com/jaydee3/JDStatusBarNotification/issues
[cocoapods website]: http://cocoapods.org
