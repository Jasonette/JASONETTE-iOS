# TDOAuth

[![CI Status](https://github.com/yahoo/TDOAuth/workflows/TDOAuth%20CI/badge.svg?branch=master)](https://github.com/yahoo/TDOAuth/actions)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Version](https://img.shields.io/cocoapods/v/TDOAuth.svg?style=flat)](https://cocoapods.org/pods/TDOAuth)
[![License](https://img.shields.io/cocoapods/l/TDOAuth.svg?style=flat)](https://cocoapods.org/pods/TDOAuth)
[![Platform](https://img.shields.io/cocoapods/p/TDOAuth.svg?style=flat)](https://cocoapods.org/pods/TDOAuth)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

Swift 4, 4.2 or 5. The pure-Swift subspec has no dependencies.

## Installation

### CocoaPods

TDOAuth is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'TDOAuth'
```

### SwiftPM

Add `.package(url: "https://github.com/yahoo/TDOAuth.git", from: "1.5.0")` to your `package.swift`

## Usage (Swift)

### Two-Legged OAuth (Client & Server Only)

The two legs of two-legged OAuth are the client and server. This method of authentication is suitable for verifying access from a blessed first-party. If you have only a consumer secret and consumer key, this the method you would use:

```
let consumerSecret = "my-consumer-secret"
let consumerKey = "my-consmer-key"

/// Generate our OAuth1 signer
let oauth1: OAuth1<HMACSigner> = {
    let secrets = SharedSecrets(consumerSecret: consumerSecret)
    let sha1Signer = HMACSigner(algorithm: .sha1, material: secrets)
    return OAuth1(withConsumerKey: consumerKey, signer: sha1Signer)
}()

/// Feed requests into our OAuth1 signer to produce signed versions of those requests.
/// The only modificataion to the provided request is setting the Authorization HTTP header.
func signRequest(_ request: URLRequest) -> URLRequest? {
    return oauth1.sign(request: request)
}
```

### Three-Legged OAuth (Client, Server & Third-party)

Three-legged OAuth is a version suitable for authenticating a third-party to access a user's data. This method introduces a second set of key & secret for the third party:

```
let consumerSecret = "my-consumer-secret"
let consumerKey = "my-consmer-key"
let accessToken: String? = "access-token"
let accessTokenSecret: String? = "token-secret"


/// Generate our OAuth1 signer
let oauth1: OAuth1<HMACSigner> = {
    let secrets = SharedSecrets(consumerSecret: consumerSecret, accessTokenSecret: accessTokenSecret)
    let sha1Signer = HMACSigner(algorithm: .sha1, material: secrets)
    return OAuth1(withConsumerKey: consumerKey, accessToken: accessToken, signer: sha1Signer)
}()

/// Feed requests into our OAuth1 signer to produce signed versions of those requests.
/// The only modificataion to the provided request is setting the Authorization HTTP header.
func signRequest(_ request: URLRequest) -> URLRequest? {
    return oauth1.sign(request: request)
}
```

### Signing Methods

In the examples above, we use SHA-1 HMAC to sign generate the signatures. You may want to use a more secure hashing algorithm since SHA-1 is quite weak now. TDOAuth supports more secure SHA-2 signing by default, as well as arbitrary signing (Bring Your Own Algorithm).

Supported SHA-2 variants:
- SHA-224
- SHA-256
- SHA-384
- SHA-512

Example for SHA-256
```
let signer: OAuth1<HMACSigner> = HMACSigner(algorithm: .sha256, material: secrets)
```

#### Plain text Signing

Plain text signing is useful mainly for debugging or use over strictly pinned SSL connections. The keys are not secured in any way, so it is very bad idea to use this strategy without pinned SSL.

Example for PlainText signing
```
let signer: OAuth1<PlaintextSigner> = PlaintextSigner(keyMaterial: secrets)
```

#### Custom Signing

To provide your own custom signing, implement the `OAuth1Signer` protocol:
```
public protocol OAuth1Signer {

    associatedtype KeyMaterial

    var signatureMethod: String { get }

    init(keyMaterial: KeyMaterial)

    func sign(_ value: String) -> String
}
```

For a simple example, see the implementation in `PlaintextSigner.swift`.

## Usage (Legacy Objective-C)

Using the Objective-C API is not recommended. It is provided for backwards compatability with the old TDOAuth Obj-C API. While the underlying code uses the exact same Swift code as above, the legacy TDOAuth API imposed significant opinions on the requests, and those opinions were replicated in the new compatability API. For example, a User-Agent header is generated and added automatically to your request. Handling for POST and form-data has a lot of caveats and edge cases around encoding.

While the Swift API simply signs whatever `URLRequest` you provide it, the Objective-C API generates a new `NSURLRequest` for you as part of the signing process. As a result you may need to carefully alter the returned request instance to suit your needs (be sure not to break the signature).

**Use the Swift API!**

Objective-C API Example
```
#import <TDOAuth/TDOAuth.h>

NSURLRequest * request = [TDOAuth URLRequestForPath:@"/v1/service/name"
                         parameters:@{ "count": @10, "format": "json" }
                               host:@"api.example.com"
                        consumerKey:@"my-consumer-key"
                     consumerSecret:@"my-consumer-secret"
                        accessToken:@"my-token"
                        tokenSecret:@"my-token-secret"
                             scheme:@"https"
                      requestMethod:@"GET"
                       dataEncoding:TDOAuthContentTypeUrlEncodedForm
                       headerValues:@{ "Accept": "application/json" }
                    signatureMethod:TDOAuthSignatureMethodHmacSha1;
```

## Author

Adam Kaplan, adamkaplan@yahooinc.com

## License

TDOAuth is available under the MIT license. See the LICENSE file for more info.
