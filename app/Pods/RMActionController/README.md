# RMActionViewController ![Build Status](https://travis-ci.org/CooperRS/RMActionController.svg?branch=master)
This is an iOS control for presenting any UIView in an UIActionSheet/UIAlertController like manner.

## Screenshots
### Portrait
![Portrait](http://cooperrs.github.io/RMActionController/Images/Blur-Screen-Portrait.png)

### Landscape
![Landscape](http://cooperrs.github.com/RMActionController/Images/Blur-Screen-Landscape.png)

### Black version
![Colors](http://cooperrs.github.io/RMActionController/Images/Blur-Screen-Portrait-Black.png)

## Installation (CocoaPods)
```ruby
platform :ios, '8.0'
pod "RMActionController", "~> 1.0.4"
```

## Usage

### Basic

The default RMActionController does not contain any content view. This means presenting an RMActionController only presents a set of buttons added to the RMActionController. For this task an UIAlertController can be used.

To add a content view RMActionController usually is subclassed. This project contains two subclasses of RMActionController (RMCustomViewActionController and RMMapActionController) which give two examples for a subclass of RMActionController.

#### Subclassing

When subclassing RMActionController you only have to overwrite one method. This method is called `actionControllerWithStyle:title:message:selectAction:andCancelAction:`.

```objc
+ (instancetype)actionControllerWithStyle:(RMActionControllerStyle)style title:(NSString *)aTitle message:(NSString *)aMessage selectAction:(RMAction *)selectAction andCancelAction:(RMAction *)cancelAction {
    //Create an instance of your RMActionController subclass
    RMMapActionController *controller = [super actionControllerWithStyle:style title:aTitle message:aMessage selectAction:selectAction andCancelAction:cancelAction];
    
    controller.contentView = [[MKMapView alloc] initWithFrame:CGRectZero];
    controller.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    controller.contentView.accessibilityLabel = @"MapView";
    
    NSDictionary *bindings = @{@"contentView": controller.contentView};
    [controller.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView(200)]" options:0 metrics:nil views:bindings]];
    
    return controller;
}
```

#### Presenting

Presenting any RMActionController works by using standard Apple API.

```objc
- (IBAction)openActionController:(id)sender {
    //Create select action
    RMAction *selectAction = [RMAction actionWithTitle:@"Select" style:RMActionStyleDone andHandler:^(RMActionController *controller) {
        NSLog(@"Action controller finished successfully");
    }];
    
    //Create cancel action
    RMAction *cancelAction = [RMAction actionWithTitle:@"Cancel" style:RMActionStyleCancel andHandler:^(RMActionController *controller) {
        NSLog(@"Action controller was canceled");
    }];
    
    //Create action controller and (optionally) set title and message
    RMMapActionController *actionController = [RMMapActionController actionControllerWithStyle:RMActionControllerStyleWhite selectAction:selectAction andCancelAction:cancelAction];
    actionController.title = @"Test";
    actionController.message = @"This is a test action controller.\nPlease tap 'Select' or 'Cancel'.";

    //Now just present the date selection controller using the standard iOS presentation method
    [self presentViewController:actionController animated:YES completion:nil];
}
```

### Advanced

#### Presentation Style
You can use the property `modalPresentationStyle` to control how the action controller is shown. By default, it is set to `UIModalPresentationOverCurrentContext`. But on the iPad you could use `UIModalPresentationPopover` to present the action controller within a popover. See the following example on how this works:

```objc
- (IBAction)openActionController:(id)sender {
    //Create select and cancel action
    ...

    RMMapActionController *actionController = [RMMapActionController actionControllerWithStyle:RMActionControllerStyleWhite selectAction:selectAction andCancelAction:cancelAction];

    //On the iPad we want to show the date selection view controller within a popover.
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        //First we set the modal presentation style to the popover style
        actionController.modalPresentationStyle = UIModalPresentationPopover;
        
        //Then we tell the popover presentation controller, where the popover should appear
        actionController.popoverPresentationController.sourceView = self.view;
        actionController.popoverPresentationController.sourceRect = CGRectMake(...);
    }

    //Now just present the date selection controller using the standard iOS presentation method
    [self presentViewController:actionController animated:YES completion:nil];
}
```

#### Others
Finially, RMActionController can be used in both your main application and an action extension showing UI.

## Documentation
There is an additional documentation available provided by the CocoaPods team. Take a look at [cocoadocs.org](http://cocoadocs.org/docsets/RMActionController/).

## Requirements

| Compile Time  | Runtime       |
| :------------ | :------------ |
| Xcode 6       | iOS 8         |
| iOS 8 SDK     |               |
| ARC           |               |

Note: ARC can be turned on and off on a per file basis.

## Apps using this control
Using this control in your app or know anyone who does?

Feel free to add the app to this list: [Apps using RMActionController](https://github.com/CooperRS/RMActionController/wiki/Apps-using-RMActionController)

##Credits

* Hannes Tribus (Bugfixes)
* normKei (Destructive button type)

I want to thank everyone who has contributed code and/or time to this project!

## License (MIT License)
Copyright (c) 2015 Roland Moers

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
