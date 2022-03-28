// Copyright 2021, Yahoo Inc.
// Licensed under the terms of the MIT license. See LICENSE file in https://github.com/yahoo/TDOAuth for terms.

import Foundation

/// Generic protocol to support OAuth 1.0 signers, examples provided in the RFC:
/// HMAC-SHA1 (Client Secret + Shared Secret) https://tools.ietf.org/html/rfc5849#section-3.4.2
/// RSA-SHA1  (Client Secret) https://tools.ietf.org/html/rfc5849#section-3.4.3
/// PLAINTEXT (Client Secret + Shared Secret) https://tools.ietf.org/html/rfc5849#section-3.4.4
///
/// (SHA1 has not been secure in ages, but the spec allows any algo like SHA256)
public protocol OAuth1Signer {

    associatedtype KeyMaterial

    var signatureMethod: String { get }

    init(keyMaterial: KeyMaterial)

    func sign(_ value: String) -> String
}

/// Shared secrets include the consumer/client secret and access token secrets
/// used to generate HMAC and and Plaintext signatures. Other methods, such as
/// RSA signatures would not use this struct.
public struct SharedSecrets {
    public let consumerSecret: String

    public let accessTokenSecret: String?

    public init(consumerSecret: String, accessTokenSecret: String? = nil) {
        self.consumerSecret = consumerSecret
        self.accessTokenSecret = accessTokenSecret
    }
}

public extension OAuth1Signer where KeyMaterial == SharedSecrets {

    // The signature secret is created by concatenating the consumer secret and access token
    static func generateSigningKey(material: KeyMaterial) -> String {
        var generatedSecret = material.consumerSecret.appending("&")
        if let accessTokenSecret = material.accessTokenSecret {
            generatedSecret.append(contentsOf: accessTokenSecret)
        }
        return generatedSecret
    }
}
