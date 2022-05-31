// Copyright 2021, Yahoo Inc.
// Licensed under the terms of the MIT license. See LICENSE file in https://github.com/yahoo/TDOAuth for terms.

import Foundation
import CommonCrypto.CommonHMAC

public enum HmacAlgorithm: String {
    case sha1 = "HMAC-SHA1"
    case sha224 = "HMAC-SHA224"
    case sha256 = "HMAC-SHA256"
    case sha384 = "HMAC-SHA384"
    case sha512 = "HMAC-SHA512"

    var commonCryptoAlgorithm: CCHmacAlgorithm {
        switch self {
        case .sha1:
            return UInt32(kCCHmacAlgSHA1)
        case .sha224:
            return UInt32(kCCHmacAlgSHA224)
        case .sha256:
            return UInt32(kCCHmacAlgSHA256)
        case .sha384:
            return UInt32(kCCHmacAlgSHA384)
        case .sha512:
            return UInt32(kCCHmacAlgSHA512)
        }
    }

    var digestLength: Int {
        switch self {
        case .sha1:
            return Int(CC_SHA1_DIGEST_LENGTH)
        case .sha224:
            return Int(CC_SHA224_DIGEST_LENGTH)
        case .sha256:
            return Int(CC_SHA256_DIGEST_LENGTH)
        case .sha384:
            return Int(CC_SHA384_DIGEST_LENGTH)
        case .sha512:
            return Int(CC_SHA512_DIGEST_LENGTH)
        }
    }
}

public class HMACSigner: OAuth1Signer {

    public typealias KeyMaterial = SharedSecrets

    /// The algorithm to use to generate the Authorization header signature
    public var signatureMethod: String { return signatureAlgorithm.rawValue }

    /// The algorithm to use to generate the Authorization header signature
    public let signatureAlgorithm: HmacAlgorithm

    /// Immutable copy of the HMAC signing context, precomputed for performance
    private let hmacContext: CCHmacContext

    public required convenience init(keyMaterial: KeyMaterial) {
        self.init(algorithm: .sha384, material: keyMaterial)
    }

    public required init(algorithm: HmacAlgorithm, material: KeyMaterial) {
        signatureAlgorithm = algorithm

        var context = CCHmacContext()
        withUnsafeMutablePointer(to: &context) { contextPtr in
            let signingKey = HMACSigner.generateSigningKey(material: material)
            let signingKeyLength = signingKey.lengthOfBytes(using: .utf8)
            signingKey.withCString { signingKeyPtr in
                CCHmacInit(contextPtr, algorithm.commonCryptoAlgorithm, signingKeyPtr, signingKeyLength)
            }
        }
        hmacContext = context
    }

    /// The value to sign, per RFC 5849, section 3.4.1.1
    /// https://tools.ietf.org/html/rfc5849#section-3.4.1.1
    ///
    /// The string should already be normalized and composed according to section 3.4.1.3.2
    /// https://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
    ///
    /// The resulting string is base64 encoded in conformance with section 6.8
    /// https://tools.ietf.org/html/rfc2045#section-6.8
    ///
    /// - Parameter value: Value to sign according to RFC 5849 section 3.4.1.1
    /// - Returns: The signed value as a base64 encoded string
    public func sign(_ value: String) -> String {
        var context = hmacContext // copy the immutable pre-compiled instance struct
        let signed = withUnsafeMutablePointer(to: &context) { contextPtr -> String in

            let valueLength = value.lengthOfBytes(using: .utf8)
            value.withCString { CCHmacUpdate(contextPtr, $0, valueLength) }

            var buffer = Data(repeating: 0, count: signatureAlgorithm.digestLength)
            buffer.withUnsafeMutableBytes { buf in
                if let bufPtr = buf.baseAddress {
                    CCHmacFinal(contextPtr, bufPtr)
                }
            }

            return buffer.base64EncodedString(options: [])
        }
        return signed
    }
}
