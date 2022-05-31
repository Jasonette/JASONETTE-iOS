// Copyright 2021, Yahoo Inc.
// Licensed under the terms of the MIT license. See LICENSE file in https://github.com/yahoo/TDOAuth for terms.

import Foundation

let urlSafeCharacters: CharacterSet = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-._~")

public extension String {

    func addingUrlSafePercentEncoding() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: urlSafeCharacters) ?? ""
    }

}
