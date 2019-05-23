SBJson 4
========

JSON (JavaScript Object Notation) is a light-weight data interchange format
that's easy to read and write for humans and computers alike. This library
implements chunk-based JSON parsing and generation in Objective-C.

[![Build Status](https://travis-ci.org/stig/json-framework.png?branch=master)](https://travis-ci.org/stig/json-framework)

[![codecov.io](http://codecov.io/github/stig/json-framework/coverage.svg?branch=master)](http://codecov.io/github/stig/json-framework?branch=master)

[![Join the chat at https://gitter.im/stig/json-framework](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/stig/json-framework?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Project Status: Inactive - The project has reached a stable, usable state but is no longer being actively developed; support/maintenance will be provided as time allows.](http://www.repostatus.org/badges/0.1.0/inactive.svg)](http://www.repostatus.org/#inactive)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Features
--------

SBJson's number one feature is chunk-based operation. Feed the parser one or
more chunks of UTF8-encoded data and it will call a block you provide with each
root-level document or array. Or, optionally, for each top-level entry in each
root-level array. See more in the [Version 4 API
docs](http://cocoadocs.org/docsets/SBJson/4.0.0/Classes/SBJson4Parser.html).

Other features:

* Configurable recursion limit. For safety SBJson defaults to a max nesting
  level of 32 for all input. This can be configured if necessary.
* The writer can optionally sort dictionary keys so output is consistent
  across writes.
* The writer can optionally create human-readable (indented) output.

API Documentation
-----------------

Please see the [API Documentation](http://cocoadocs.org/docsets/SBJson) for
more details.

Installation
------------

### CocoaPods
The preferred way to use SBJson is by using
[CocoaPods](http://cocoapods.org/?q=sbjson). In your Podfile use:

    pod 'SBJson', '~> 4.0.4'

If you depend on a third-party library that requires an earlier version of
SBJson---or want to install both version 3 and 4 in the same app to do a gradual
transition---you can instead use:

    pod 'SBJson4', '~> 4.0.4'

### Carthage
SBJson is compatible with _Carthage_. Follow the [Getting Started Guide for iOS](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos).

	github "stig/json-framework" == 4.0.4

### Copy source files
An alternative that I no longer recommend is to copy all the source files (the contents of the `Classes` folder) into your own Xcode project.

Examples
--------

* https://github.com/stig/ChunkedDelivery - a toy example showing how one can
  use `NSURLSessionDataDelegate` to do chunked delivery.
* https://github.com/stig/DisplayPretty - a very brief example using SBJson 4
  to reflow JSON on OS X.

Support
-------

* Check StackOverflow questions
  [tagged with SBJson](http://stackoverflow.com/questions/tagged/sbjson) if
  you have questions about how to use the library. I try to read all questions
  with this tag.
* Use the [issue tracker](http://github.com/stig/json-framework/issues) if you
  have found a bug.

License
-------

BSD. See [LICENSE](LICENSE) for details.
