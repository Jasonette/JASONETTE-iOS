# Objective-C NSHash

> NSHash adds hashing methods to NSString and NSData.

[![Build Status](https://travis-ci.org/jerolimov/NSHash.svg)](https://travis-ci.org/jerolimov/NSHash)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/NSHash.svg)](https://cocoapods.org/pods/NSHash)
[![Supported Platforms](https://img.shields.io/cocoapods/p/NSHash.svg?style=flat)](http://cocoadocs.org/docsets/NSHash)

## How to use it

Copy the NSHash classes into your project or add this line to your [Podfile](http://cocoapods.org/):

```ruby
pod 'NSHash', '~> 1.2.0'
```

## Quick API overview

Import the the category class you need:

```objectivec
#import <NSHash/NSString+NSHash.h>
#import <NSHash/NSData+NSHash.h>
```

After that you can call `MD5`, `MD5Data`, `SHA1`, `SHA1Data`, `SHA256` or `SHA256Data` on any `NSString`:

```objectivec
NSString* string = @"NSHash";

NSLog(@"MD5 as NSString:    %@", [string MD5]);
NSLog(@"SHA1 as NSString:   %@", [string SHA1]);
NSLog(@"SHA256 as NSString: %@", [string SHA256]);
NSLog(@"SHA512 as NSString: %@", [string SHA512]);

NSLog(@"MD5 as NSData:      %@", [string MD5Data]);
NSLog(@"SHA1 as NSData:     %@", [string SHA1Data]);
NSLog(@"SHA256 as NSData:   %@", [string SHA256Data]);
NSLog(@"SHA512 as NSData:   %@", [string SHA512Data]);
```

This will return a new `NSString` with a hex code transformed version of the hash:

```objectivec
MD5 as NSString:    ccbe85c2011c5fe3da7d760849c4f99e
SHA1 as NSString:   f5b17712c5d31ab49654b0baadf699561958d750
SHA256 as NSString: 84423607efac17079369134460239541285d5ff40594f9b8b16f567500162d2e
SHA512 as NSString: 927323f74dec1305f0a4822aab380268b6eab030eac4af6c881a529e610936613b0563bca84af894cff1e876522b8f721b54da9bbe3132f8de2692019e195cf8
MD5 as NSData:      <ccbe85c2 011c5fe3 da7d7608 49c4f99e>
SHA1 as NSData:     <f5b17712 c5d31ab4 9654b0ba adf69956 1958d750>
SHA256 as NSData:   <84423607 efac1707 93691344 60239541 285d5ff4 0594f9b8 b16f5675 00162d2e>
SHA512 as NSData:   <927323f7 4dec1305 f0a4822a ab380268 b6eab030 eac4af6c 881a529e 61093661 3b0563bc a84af894 cff1e876 522b8f72 1b54da9b be3132f8 de269201 9e195cf8>
```

Or call `MD5`, `MD5String`, `SHA1`, `SHA1String`, `SHA256` or `SHA256String` on any `NSData`:

```objectivec
NSData* data = [@"NSHash" dataUsingEncoding:NSUTF8StringEncoding];

NSLog(@"MD5 as NSData:      %@", [data MD5]);
NSLog(@"SHA1 as NSData:     %@", [data SHA1]);
NSLog(@"SHA256 as NSData:   %@", [data SHA256]);
NSLog(@"SHA512 as NSData:   %@", [data SHA512]);

NSLog(@"MD5 as NSString:    %@", [data MD5String]);
NSLog(@"SHA1 as NSString:   %@", [data SHA1String]);
NSLog(@"SHA256 as NSString: %@", [data SHA256String]);
NSLog(@"SHA512 as NSString: %@", [data SHA512String]);
```

Which will return the `NSData` with the hash as bytes without the hex transformation:

```objectivec
MD5 as NSData:      <ccbe85c2 011c5fe3 da7d7608 49c4f99e>
SHA1 as NSData:     <f5b17712 c5d31ab4 9654b0ba adf69956 1958d750>
SHA256 as NSData:   <84423607 efac1707 93691344 60239541 285d5ff4 0594f9b8 b16f5675 00162d2e>
SHA512 as NSData:   <927323f7 4dec1305 f0a4822a ab380268 b6eab030 eac4af6c 881a529e 61093661 3b0563bc a84af894 cff1e876 522b8f72 1b54da9b be3132f8 de269201 9e195cf8>
MD5 as NSString:    ccbe85c2011c5fe3da7d760849c4f99e
SHA1 as NSString:   f5b17712c5d31ab49654b0baadf699561958d750
SHA256 as NSString: 84423607efac17079369134460239541285d5ff40594f9b8b16f567500162d2e
SHA512 as NSString: 927323f74dec1305f0a4822aab380268b6eab030eac4af6c881a529e610936613b0563bca84af894cff1e876522b8f721b54da9bbe3132f8de2692019e195cf8
```

The generated doc (still only two categories with only this few methods)
is also available on [cocoadocs](http://cocoadocs.org/docsets/NSHash/).
