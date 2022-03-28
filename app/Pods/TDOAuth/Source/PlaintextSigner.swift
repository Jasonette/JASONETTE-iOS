// Copyright 2021, Yahoo Inc.
// Licensed under the terms of the MIT license. See LICENSE file in https://github.com/yahoo/TDOAuth for terms.

import Foundation

public class PlaintextSigner: OAuth1Signer {

    public typealias KeyMaterial = SharedSecrets

    public let signatureMethod = "PLAINTEXT"

    let signature: String

    public required init(keyMaterial: KeyMaterial) {
        signature = PlaintextSigner.generateSigningKey(material: keyMaterial)
    }

    public func sign(_ value: String) -> String {
        return signature
    }
}
