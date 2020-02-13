DHSmartScreenshot
=================

UITableView/UIScrollView Category to get really easy, smart and instant screenshot images like no other library out there for iOS 5+ devices.


Screenshots
-----------

This is a tableview on the simulator:

![iOS TableView on Simulator](http://i.imgur.com/oIZJ5bT.png)

And here is the full screenshot image that you get by selecting the first row (full screenshot image):

![Screenshot Taken - Example](http://i.imgur.com/w6UkZCD.png)


Installation
------------

1. The preferred way of installation is via [Cocoapods](http://cocoapods.org). Just add 

```ruby
pod 'DHSmartScreenshot'
```

to your Podfile and run `pod install`. It will install the most recent version of DHSmartScreenshot.

Alternatively you could copy all the files in the ```Classes/``` directory into your project. Be sure 'Copy items to destination group's folder' is checked.


Usage
-----

1. Import the header: ```#import "DHSmartScreenshot.h"```

2. Call 
```objective-c
UIImage * tableViewScreenshot = [self.tableView screenshot];
```
to get a full screenshot of your tableView instance or see below to know what method to call and get a custom screenshot that better fits your needs.


Methods
-------

There are some methods to customize the way you want to take the screenshot.
Each one of them is self descriptive and works as you could expect, take a look:

```objective-c
- (UIImage *)screenshot;
```

```objective-c
- (UIImage *)screenshotOfCellAtIndexPath:(NSIndexPath *)indexPath;
```

```objective-c
- (UIImage *)screenshotOfHeaderViewAtSection:(NSUInteger)section;
```

```objective-c
- (UIImage *)screenshotOfFooterViewAtSection:(NSUInteger)section;
```

```objective-c
- (UIImage *)screenshotExcludingAllHeaders:(BOOL)withoutHeaders
					   excludingAllFooters:(BOOL)withoutFooters
						  excludingAllRows:(BOOL)withoutRows;
```

```objective-c
- (UIImage *)screenshotExcludingHeadersAtSections:(NSSet *)headerSections
					   excludingFootersAtSections:(NSSet *)footerSections
						excludingRowsAtIndexPaths:(NSSet *)indexPaths;
```

```objective-c
- (UIImage *)screenshotOfHeadersAtSections:(NSSet *)headerSections
						 footersAtSections:(NSSet *)footerSections
						  rowsAtIndexPaths:(NSSet *)indexPaths;
```

```objective-c
- (UIImage *)screenshotOfVisibleContent;
```

Contribution
------------

Sure :) please send a pull-request or raise an issue. It is always good to know how to make things better, yay!


Author
------

David Hernandez ([dav.viidd94@gmail.com](mailto:dav.viidd94@gmail.com))


License
-------

DHSmartScreenshot is under the MIT License.
