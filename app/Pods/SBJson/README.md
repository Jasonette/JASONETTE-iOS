SBJson 5
========

JSON (JavaScript Object Notation) is a light-weight data interchange format
that's easy to read and write for humans and computers alike. This library
implements chunk-based JSON parsing and generation in Objective-C.

[![Build Status](https://travis-ci.org/stig/json-framework.png?branch=master)](https://travis-ci.org/stig/json-framework)

[![codecov.io](http://codecov.io/github/stig/json-framework/coverage.svg?branch=master)](http://codecov.io/github/stig/json-framework?branch=master)

[![Project Status: Inactive - The project has reached a stable, usable state but is no longer being actively developed; support/maintenance will be provided as time allows.](http://www.repostatus.org/badges/0.1.0/inactive.svg)](http://www.repostatus.org/#inactive)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Overview
========

SBJson's number one feature is chunk-based operation. Feed the parser one or
more chunks of UTF8-encoded data and it will call a block you provide with each
root-level document or array. Or, optionally, for each top-level entry in each
root-level array.

With chunk-based parsing you can reduce the apparent latency for each
download/parse cycle of documents over a slow connection. You can start
parsing *and return chunks of the parsed document* before the entire document
is even downloaded. You can also parse massive documents bit by bit so you
don't have to keep them all in memory.

JSON is mapped to Objective-C types in the following way:

| JSON Type | Objective-C Type                |
|-----------|---------------------------------|
| null      | NSNull                          |
| string    | NSString                        |
| array     | NSMutableArray                  |
| object    | NSMutableDictionary             |
| true      | -[NSNumber numberWithBool: YES] |
| false     | -[NSNumber numberWithBool: NO]  |
| number    | NSNumber                        |

Since Objective-C doesn't have a dedicated class for boolean values, these
turns into NSNumber instances. However, because they are initialised with the
-initWithBool: method they round-trip back to JSON true and false properly.
Integers are parsed into either a `long long` or `unsigned long long` type if
they fit, else a `double` is used.

"Plain" Chunk Based Parsing
---------------------------

First define a simple block & an error handler. (These are just minimal
examples. You should strive to do something better that makes sense in your
application!)

```objc
SBJson5ValueBlock block = ^(id v, BOOL *stop) {
    BOOL isArray = [v isKindOfClass:[NSArray class]];
    NSLog(@"Found: %@", isArray ? @"Array" : @"Object");
};

SBJson5ErrorBlock eh = ^(NSError* err) {
    NSLog(@"OOPS: %@", err);
    exit(1);
};
```

Then create a parser and add data to it:

```objc
id parser = [SBJson5Parser parserWithBlock:block
                              errorHandler:eh];

id data = [@"[true," dataWithEncoding:NSUTF8StringEncoding];
[parser parse:data]; // returns SBJson5ParserWaitingForData

// block is not called yet...

// ok, now we add another value and close the array

data = [@"false]" dataWithEncoding:NSUTF8StringEncoding];
[parser parse:data]; // returns SBJson5ParserComplete

// the above -parse: method calls your block before returning.
```

Alright! Now let's look at something slightly more interesting.

Handling multiple documents
---------------------------

This is useful for something like Twitter's feed, which gives you one JSON
document per line. Here is an example of parsing many consequtive JSON
documents, where your block will be called once for each document:

```objc
id parser = [SBJson5Parser multiRootParserWithBlock:block
                                       errorHandler:eh];

// Note that this input contains multiple top-level JSON documents
id data = [@"[]{}" dataWithEncoding:NSUTF8StringEncoding];
[parser parse:data];
[parser parse:data];
```

The above example will print:

```
Found: Array
Found: Object
Found: Array
Found: Object
```

Unwrapping a gigantic top-level array
-------------------------------------

Often you won't have control over the input you're parsing, so can't use a
multiRootParser. But, all is not lost: if you are parsing a long array you can
get the same effect by using an unwrapRootArrayParser:

```objc
id parser = [SBJson5Parser unwrapRootArrayParserWithBlock:block
                                             errorHandler:eh];

// Note that this input contains A SINGLE top-level document
id data = [@"[[],{},[],{}]" dataWithEncoding:NSUTF8StringEncoding];
[parser parse:data];
```

Other features
--------------

* For safety there is a max nesting level for all input. This defaults to 32,
  but is configurable.
* The writer can sort dictionary keys so output is consistent across writes.
* The writer can create human-readable output, with newlines and indents.
* You can install SBJson v3, v4 and v5 side-by-side in the same application.
  (This is possible because all classes & public symbols contains the major
  version number.)

A word of warning
-----------------

Stream based parsing does mean that you lose some of the correctness
verification you would have with a parser that considered the entire input
before returning an answer. It is technically possible to have some parts of a
document returned *as if they were correct* but then encounter an error in a
later part of the document. You should keep this in mind when considering
whether it would suit your application.

American Fuzzy Lop
==================

I've run [AFL][] on the sbjson binary for over 24 hours, with no crashes
found. (I cannot reproduce the hangs reported when attempting to parse them
manually.)

[AFL]: http://lcamtuf.coredump.cx/afl/

```
                       american fuzzy lop 2.35b (sbjson)

┌─ process timing ─────────────────────────────────────┬─ overall results ─────┐
│        run time : 1 days, 0 hrs, 45 min, 26 sec      │  cycles done : 2      │
│   last new path : 0 days, 0 hrs, 5 min, 24 sec       │  total paths : 555    │
│ last uniq crash : none seen yet                      │ uniq crashes : 0      │
│  last uniq hang : 0 days, 2 hrs, 11 min, 43 sec      │   uniq hangs : 19     │
├─ cycle progress ────────────────────┬─ map coverage ─┴───────────────────────┤
│  now processing : 250* (45.05%)     │    map density : 0.70% / 1.77%         │
│ paths timed out : 0 (0.00%)         │ count coverage : 3.40 bits/tuple       │
├─ stage progress ────────────────────┼─ findings in depth ────────────────────┤
│  now trying : auto extras (over)    │ favored paths : 99 (17.84%)            │
│ stage execs : 603/35.6k (1.70%)     │  new edges on : 116 (20.90%)           │
│ total execs : 20.4M                 │ total crashes : 0 (0 unique)           │
│  exec speed : 481.9/sec             │   total hangs : 44 (19 unique)         │
├─ fuzzing strategy yields ───────────┴───────────────┬─ path geometry ────────┤
│   bit flips : 320/900k, 58/900k, 5/899k             │    levels : 8          │
│  byte flips : 0/112k, 4/112k, 3/112k                │   pending : 385        │
│ arithmetics : 66/6.24M, 0/412k, 0/35                │  pend fav : 1          │
│  known ints : 5/544k, 0/3.08M, 0/4.93M              │ own finds : 554        │
│  dictionary : 0/0, 0/0, 29/1.83M                    │  imported : n/a        │
│       havoc : 64/300k, 0/0                          │ stability : 100.00%    │
│        trim : 45.19%/56.5k, 0.00%                   ├────────────────────────┘
^C────────────────────────────────────────────────────┘             [cpu: 74%]

+++ Testing aborted by user +++
[+] We're done here. Have a nice day!
```

API Documentation
=================

Please see the [API Documentation](http://cocoadocs.org/docsets/SBJson) for
more details.


Installation
============

CocoaPods
---------

The preferred way to use SBJson is by using
[CocoaPods](http://cocoapods.org/?q=sbjson). In your Podfile use:

    pod 'SBJson5', '~> 5.0.0'

Carthage
--------

SBJson is compatible with _Carthage_. Follow the [Getting Started Guide for iOS](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos).

	github "stig/json-framework" == 5.0.0

Bundle the source files
-----------------------

An alternative that I no longer recommend is to copy all the source files (the
contents of the `Classes` folder) into your own Xcode project.

Examples
========

* https://github.com/stig/ChunkedDelivery - a toy example showing how one can
  use `NSURLSessionDataDelegate` to do chunked delivery.
* https://github.com/stig/DisplayPretty - a very brief example using SBJson 4
  to reflow JSON on OS X.

Support
=======

* Check StackOverflow questions
  [tagged with SBJson](http://stackoverflow.com/questions/tagged/sbjson) if
  you have questions about how to use the library. I try to read all questions
  with this tag.
* Use the [issue tracker](http://github.com/stig/json-framework/issues) if you
  have found a bug.

License
=======

BSD. See [LICENSE](LICENSE) for details.
