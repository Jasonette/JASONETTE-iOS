// Copyright 2021, Yahoo Inc.
// Licensed under the terms of the MIT license. See LICENSE file in https://github.com/yahoo/TDOAuth for terms.

import Foundation

#if SWIFT_PACKAGE
import TDOAuthSwift

@objc public enum TDOAuthSignatureMethod: Int {
    case hmacSha1, hmacSha256
}
#endif

@objc public class TDOAuthCompat: NSObject {

    static var OAuth1Type: OAuth1.Type = OAuth1<HMACSigner>.self

    @objc public static func signRequest(_ urlRequest: URLRequest,
                                  consumerKey: String,
                                  consumerSecret: String,
                                  accessToken: String?,
                                  tokenSecret: String?,
                                  signatureMethod: TDOAuthSignatureMethod) -> URLRequest? {


        let hmacAlgo: HmacAlgorithm
        switch signatureMethod {
        case .hmacSha1:
            hmacAlgo = .sha1
        case .hmacSha256:
            hmacAlgo = .sha256
        default:
            return nil
        }

        let key = SharedSecrets(consumerSecret: consumerSecret, accessTokenSecret: tokenSecret)
        let signer = HMACSigner(algorithm: hmacAlgo, material: key)
        let oauth1 = OAuth1Type.init(withConsumerKey: consumerKey, accessToken: accessToken, signer: signer)

        return oauth1.sign(request: urlRequest)
    }
}

@objc public extension NSString {
    @objc var TDOAuth_addingUrlSafePercentEncoding: String { (self as String).addingUrlSafePercentEncoding() }
}
