# CYRTextView

by **Illya Busigin**

- Visit my blog at [http://illyabusigin.com/](http://illyabusigin.com/)
- Follow [@illyabusigin on Twitter](http://twitter.com/illyabusigin)

Purpose
--------------

CYRTextView is a UITextView subclass that implements a variety of features that are relevant to a syntax or code text view. There are many subclasses of UITextView out there with the release of TextKit but none that are specifically tailored towards a code/syntax view. CYRTextView aims to change this. Features include:
- Regular expression based text highlighting with support for multiple text attributes for each expression
- Line numbers
- Gesture based navigation

Long term, I would like to turn CYRTextView into a full fledged code editor component with code folding, markers, annotation, and more.


Screenshot
--------------
<img src="https://raw.github.com/illyabusigin/CYRTextView/master/Screenshots/1.png">


Requirements
-----------------------------

iOS 7.0 or later (**with ARC**) for iPhone, iPad and iPod touch


Installation
---------------

To use CYRTextView, just drag the class files into your project and add the CoreText framework. You can create CYRTextView instances programatically, or create them in Interface Builder by dragging an ordinary UITextView into your view and setting its class to CYRTextView.

If you are using Interface Builder, to set the custom properties of CYRTextView (ones that are not supported by regular UIViews) either create an IBOutlet for your view and set the properties in code, or use the User Defined Runtime Attributes feature in Interface Builder (introduced in Xcode 4.2 for iOS 5+).

**NOTE**: The current version (0.4.0) is alpha quality at best. Use at your own risk!


Example
---------------

CYRTextView includes an example project that demonstrates how to subclass CYRTextView to provide highlighting behavior for multiple attributes with a default set of normal, bold, and italic fonts.


Bugs & Feature Requests
---------------

There is **no support** offered with this component. If you would like a feature or find a bug, please submit a feature request through the [GitHub issue tracker](http://github.com/illyabusigin/CYRTextView/issues).

Pull-requests for bug-fixes and features are welcome!

Attribution
--------------

CYRTextView uses portions of code from the following sources.

| Component     | Description   | License  |
| ------------- |:-------------:| -----:|
| [NLTextView](https://github.com/srijs/NLTextView)      | A UITextView with Syntax Highlighting and Pan-Gesture Navigation / Selection | [MIT](https://github.com/srijs/NLTextView/blob/master/NLTextView/NLTextView.h) |
| [TextKit_LineNumbers](https://github.com/alldritt/TextKit_LineNumbers)      | iOS7 Text Kit - Text View with Line Numbers      |   [MIT](https://github.com/alldritt/TextKit_LineNumbers) |

