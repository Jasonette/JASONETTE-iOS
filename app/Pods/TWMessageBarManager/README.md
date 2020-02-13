# TWMessageBarManager

An iOS manager for presenting system-wide notifications via a dropdown message bar. 

<img src="https://raw.github.com/terryworona/TWMessageBarManager/master/Screenshots/main.png">

## Requirements

- Requires iOS 6.0 or later
- Requires Automatic Reference Counting (ARC)

## Features

- Drop-in singleton manager supported across all devices.
- Simple to use protocols and callbacks.
- Landscape and portrait orientation support.
- Highly customizable.

Refer to the <a href="https://github.com/terryworona/TWMessageBarManager/blob/master/CHANGELOG.md"">changelog</a> for an overview of TWMessagBarManager's feature history.

## Author

<p>
	Terry Worona
</p>

<p>
	Tweet me <a href="http://www.twitter.com/terryworona">@terryworona</a>
</p>

<p>
	Email me at <a href="mailto:terryworona@gmail.com">terryworona@gmail.com</a>
</p>

## Installation

<a href="http://cocoapods.org/" target="_blank">CocoaPods</a> is the recommended method of installing the TWMessageBarManager.

### The Pod Way

Simply add the following line to your <code>Podfile</code>:

	pod 'TWMessageBarManager'
	
Your podfile should look something like:

	platform :ios, '6.0'
	pod 'TWMessageBarManager'
	
### The Old School Way

The simpliest way to use TWMessageBarManager with your application is to drag and drop the <i>/Classes</i> folder into you're Xcode 5 project. It's also recommended you rename the <i>/Classes</i> folder to something more descriptive (ie. "<i>TWMessageBarManager</i>").

<center>
	<img src="https://raw.github.com/terryworona/TWMessageBarManager/master/Screenshots/installation.png">
</center>

## Usage

### Calling the manager

As a singleton class, the manager can be accessed from anywhere within your app via the ***+ sharedInstance*** function:

	[TWMessageBarManager sharedInstance]
	
### Presenting a basic message

All messages can be preseted via ***showMessageWithTitle:description:type:***. Additional arguments include duration and callback blocks to be notified of a user tap. 

Basic message:

    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Account Updated!"
                                                   description:@"Your account was successfully updated."
                                                          type:TWMessageBarMessageTypeSuccess];


The default display duration is ***3 seconds***. You can override this value by supplying an additional argument:

    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Account Updated!"
                                                   description:@"Your account was successfully updated."
                                                          type:TWMessageBarMessageTypeSuccess
                                                      duration:6.0];


### Hiding messages

It's not currently possible to hide or cancel a message on a per-instance basis. Instead, all messages must be canceled at once. This action may or may not be animated:

	[[TWMessageBarManager sharedInstance] hideAllAnimated:YES]; // animated
	
	[[TWMessageBarManager sharedInstance] hideAll]; // non-animated

### Callbacks

By default, if a user ***taps*** on a message while it is presented, it will automatically dismiss. To be notified of the touch, simply supply a callback block:


    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Account Updated!"
                                                   description:@"Your account was successfully updated."
                                                          type:TWMessageBarMessageTypeSuccess callback:^{
                                                              NSLog(@"Message bar tapped!");
    }];
	
### Queue

The manager is backed by a queue that can handle an infinite number of sequential requests. You can stack as many messages you want on the stack and they will be presetented one after another:

    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Message 1"
                                                   description:@"Description 1"
                                                          type:TWMessageBarMessageTypeSuccess];

    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Message 2"
                                                   description:@"Description 2"
                                                          type:TWMessageBarMessageTypeError];

    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Message 3"
                                                   description:@"Description 3"
                                                          type:TWMessageBarMessageTypeInfo];

### UIStatusBarStyle

The manager utilizes a custom UIWindow & UIViewController to manage orientation. For targets >= iOS7, if a UIStatusBarStyle other than UIStatusBarStyleDefault is desired, simply call:

	- (void)showMessageWithTitle:(NSString *)title description:(NSString *)description type:(TWMessageBarMessageType)type statusBarStyle:(UIStatusBarStyle)statusBarStyle callback:(void (^)())callback;


If a message is presented with a custom UIStatusBarStyle, after dismissal, the status bar will revert back to the the system style (that of the current UIVIewController). 

If you wish to hide the status bar altogether during presentations, you can do so via:

	- (void)showMessageWithTitle:(NSString *)title description:(NSString *)description type:(TWMessageBarMessageType)type statusBarHidden:(BOOL)statusBarHidden callback:(void (^)())callback;

### Customization

An object conforming to the ***TWMessageBarStyleSheet*** protocol defines the message bar's look and feel:  

	@required
	
	- (UIColor *)backgroundColorForMessageType:(TWMessageBarMessageType)type;
	- (UIColor *)strokeColorForMessageType:(TWMessageBarMessageType)type;
	- (UIImage *)iconImageForMessageType:(TWMessageBarMessageType)type;
	
	@optional
	
	- (UIFont *)titleFontForMessageType:(TWMessageBarMessageType)type;
	- (UIFont *)descriptionFontForMessageType:(TWMessageBarMessageType)type;
	- (UIColor *)titleColorForMessageType:(TWMessageBarMessageType)type;
	- (UIColor *)descriptionColorForMessageType:(TWMessageBarMessageType)type;

If no style sheet is supplied, a default class is provided on initialization. To customize the look and feel of your message bars, simply supply an object conforming to the ***TWMessageBarStyleSheet*** protocol via:

	@property (nonatomic, weak) id<TWMessageBarStyleSheet> styleSheet;
	
See ***TWAppDelegateDemoStyleSheet*** for an example on how to create a custom stylesheet. 

## License

Usage is provided under the <a href="http://opensource.org/licenses/MIT" target="_blank">MIT</a> License. See <a href="https://github.com/terryworona/TWMessageBarManager/blob/master/LICENSE">LICENSE</a> for full details.
