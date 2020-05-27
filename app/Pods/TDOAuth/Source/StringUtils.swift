// Copyright 2020, Verizon Media.
// Licensed under the terms of the MIT license. See LICENSE file in https://github.com/yahoo/TDOAuth for terms.

import Foundation

let urlSafeCharacters: CharacterSet = CharacterSet(charactersIn: "^!*'();:@&=+$,/?%#[]{}\"`<>\\| ").inverted

public extension String {

    func addingUrlSafePercentEncoding() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: urlSafeCharacters) ?? ""
    }

}
