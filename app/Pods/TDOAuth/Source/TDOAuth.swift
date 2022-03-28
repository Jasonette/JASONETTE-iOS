// Copyright 2021, Yahoo Inc.
// Licensed under the terms of the MIT license. See LICENSE file in https://github.com/yahoo/TDOAuth for terms.

import Foundation

/// See https://tools.ietf.org/html/rfc5849
open class OAuth1<T: OAuth1Signer> {

    public typealias KeyValuePair = (key: String, value: String)

    public let consumerKey: String

    public let accessToken: String?

    public let signer: T

    /// Generate a new timestamp as seconds since the epoch
    var timestamp: String { return String(format: "%0.f", Date().timeIntervalSince1970) }

    /// Generate a new one-time nonce value in the form of a random UUID
    var nonce: String { return UUID().uuidString }

    public required init(withConsumerKey consumerKey: String, accessToken: String? = nil, signer: T) {
        self.consumerKey = consumerKey
        self.accessToken = accessToken
        self.signer = signer
    }

    /// Signs a URLRequest
    /// - Parameters:
    ///   - request: The request to sign
    ///   - callback: Optional. Default: nil. The callback URL in string form (not URL encoded), or the string "oob" per RFC 5849 section 1.2
    ///   - realm: Optional. Default: nil. The realm to use for this access request
    ///   - includeVersionParameter: Optional. Default: true. Set to false to exclude the oauth_version=1.0 parameter in the Authorization header
    /// - Returns: The copied and signed request, or nil if the request could not be signed
    public func sign(request: URLRequest, callback: String? = nil, realm: String? = nil, includeVersionParameter: Bool = true) -> URLRequest? {
        var oauthParameters = self.generateOauthParameters(includeVersionParameter: includeVersionParameter)

        if let callback = callback {
            oauthParameters.append((key: "oauth_callback", value: callback))
        }

        guard let signatureBase = signatureBaseString(request: request, oauthParameters: oauthParameters) else { return nil }

        oauthParameters.append(("oauth_signature", signer.sign(signatureBase)))

        // 3.5.1.  Authorization Header
        //
        // Protocol parameters can be transmitted using the HTTP "Authorization"
        // header field as defined by [RFC2617] with the auth-scheme name set to
        // "OAuth" (case insensitive).
        //
        // Protocol parameters SHALL be included in the "Authorization" header
        // field as follows:
        //
        // 1.  Parameter names and values are encoded per Parameter Encoding
        // (Section 3.6).
        oauthParameters = oauthParameters.map {
            return ($0.key.addingUrlSafePercentEncoding(), $0.value.addingUrlSafePercentEncoding())
        }

        // 2.  Each parameter's name is immediately followed by an "=" character
        // (ASCII code 61), a """ character (ASCII code 34), the parameter
        // value (MAY be empty), and another """ character (ASCII code 34).
        let oauthParameterStrings = oauthParameters.map { "\($0.key)=\"\($0.value)\"" }

        // 3.  Parameters are separated by a "," character (ASCII code 44) and
        // OPTIONAL linear whitespace per [RFC2617].
        let oauthParameterString = oauthParameterStrings.joined(separator: ", ")

        // 4.  The OPTIONAL "realm" parameter MAY be added and interpreted per
        // [RFC2617] section 1.2.
        let realmString: String
        if let realm = realm {
            realmString = "realm=\"\(realm)\", "
        } else {
            realmString = ""
        }

        // Assemble the header
        let authHeader = "OAuth \(realmString)\(oauthParameterString)"

        // Assemble the updated request
        var updatedRequest = request
        updatedRequest.addValue(authHeader, forHTTPHeaderField: "Authorization")
        return updatedRequest
    }

    func generateOauthParameters(includeVersionParameter: Bool) -> [KeyValuePair] {
        var params = [
            ("oauth_nonce",              nonce),
            ("oauth_signature_method",   signer.signatureMethod),
            ("oauth_consumer_key",       consumerKey),
            ("oauth_timestamp",          timestamp)
        ]

        // oauth_version
        // OPTIONAL.  If present, MUST be set to "1.0".  Provides the
        // version of the authentication process as defined in this
        // specification.
        if includeVersionParameter {
            params.append(("oauth_version", "1.0"))
        }

        // Support xAuth attempts, where the token may be nil
        //
        // oauth_token
        // The token value used to associate the request with the resource
        // owner.  If the request is not associated with a resource owner
        // (no token available), clients MAY omit the parameter.
        if let accessToken = accessToken {
            params.insert(("oauth_token", accessToken), at: 0)
        }

        // Ensure all parameters are always base64 encoded
        let encodedParams = params.map { (pair: KeyValuePair) -> KeyValuePair in
            return (pair.key.addingUrlSafePercentEncoding(), pair.value.addingUrlSafePercentEncoding())
        }

        return encodedParams
    }

    func signatureBaseString(request: URLRequest, oauthParameters: [KeyValuePair]) -> String? {
        guard let url = request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else { return nil }

        // This code executes the steps in rfc5849 Section 3.4.1.1
        // https://tools.ietf.org/html/rfc5849#section-3.4.1.1
        //
        // The signature base string is constructed by concatenating together,
        // in order, the following HTTP request elements:
        //
        // 1.  The HTTP request method in uppercase.  For example: "HEAD",
        // "GET", "POST", etc.  If the request uses a custom HTTP method, it
        // MUST be encoded (Section 3.6).
        let method = (request.httpMethod?.uppercased() ?? "").addingUrlSafePercentEncoding()

        // 2.  An "&" character (ASCII code 38).
        //
        // 3.  The base string URI from Section 3.4.1.2, after being encoded
        // (Section 3.6).
        let baseStringUri = self.baseStringUri(fromUrl: url).addingUrlSafePercentEncoding()

        // 4.  An "&" character (ASCII code 38).
        //
        // 5.  The request parameters as normalized in Section 3.4.1.3.2, after
        // being encoded (Section 3.6).
        let formData: Data?
        if let contentType = request.value(forHTTPHeaderField: "Content-Type")?.lowercased(),
            contentType.starts(with: "application/x-www-form-urlencoded") {
            formData = request.httpBody
        } else {
            formData = nil
        }

        let queryItems: [URLQueryItem] = components.queryItems ?? []
        let normalizedRequestParameters = self.normalizedParameters(queryItems: queryItems, oauthParameters: oauthParameters, formData: formData).addingUrlSafePercentEncoding()

        let signatureBase = "\(method)&\(baseStringUri)&\(normalizedRequestParameters)"
        return signatureBase
    }

    func baseStringUri(fromUrl url: URL) -> String {
        // 3.4.1.2.  Base String URI
        //
        // The scheme, authority, and path of the request resource URI [RFC3986]
        // are included by constructing an "http" or "https" URI representing
        // the request resource (without the query or fragment) as follows:
        //
        // 1.  The scheme and host MUST be in lowercase.
        //
        // 2.  The host and port values MUST match the content of the HTTP
        //     request "Host" header field.
        //
        // 3.  The port MUST be included if it is not the default port for the
        //     scheme, and MUST be excluded if it is the default.  Specifically,
        //     the port MUST be excluded when making an HTTP request [RFC2616]
        //     to port 80 or when making an HTTPS request [RFC2818] to port 443.
        //     All other non-default port numbers MUST be included.
        //
        // For example, the HTTP request:
        //
        // GET /r%20v/X?id=123 HTTP/1.1
        // Host: EXAMPLE.COM:80
        //
        // is represented by the base string URI: "http://example.com/r%20v/X".
        //
        // In another example, the HTTPS request:
        //
        // GET /?q=1 HTTP/1.1
        // Host: www.example.net:8080
        //
        // is represented by the base string URI:
        // "https://www.example.net:8080/".

        // Using URLComponents because it provides a more precise URL parser than
        // properties of (NS)URL. For example, currently `URL.path` drops tailing slashes
        // and does other interpretations on the path which cause it to differ from the
        // value that would be transmitted in a URLRequest.
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return "" }
        let scheme = components.scheme?.lowercased() ?? "https"
        let host = components.host?.lowercased() ?? ""
        let port: String
        switch url.port {
        case .some(let p) where p == 80 && scheme == "http": // default port, elide
            fallthrough
        case .some(let p) where p == 443 && scheme == "https": // default port, elide
            fallthrough
        case .none:
            port = ""
        case .some(let p):
            port = ":\(p)"
        }
        let path = components.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let baseStringUri = "\(scheme)://\(host)\(port)\(path)"
        return baseStringUri
    }

    func normalizedParameters(queryItems: [URLQueryItem], oauthParameters: [KeyValuePair], formData: Data?) -> String {
        // 3.4.1.3.2.  Parameters Normalization
        //
        // The parameters collected in Section 3.4.1.3 are normalized into a
        // single string as follows:
        //
        // 1.  First, the name and value of each parameter are encoded
        // (Section 3.6).
        var parameters = collectParameters(queryItems: queryItems, oauthParameters: oauthParameters, formData: formData)

        // 2.  The parameters are sorted by name, using ascending byte value
        // ordering.  If two or more parameters share the same name, they
        // are sorted by their value.
        parameters.sort { lval, rval  -> Bool in
            switch lval.key.compare(rval.key) {
            case .orderedSame:
                return lval.value.compare(rval.value) == .orderedAscending
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            }
        }

        // 3.  The name of each parameter is concatenated to its corresponding
        // value using an "=" character (ASCII code 61) as a separator, even
        // if the value is empty.
        let parameterStrings = parameters.map { keyValuePair -> String in
            return "\(keyValuePair.key)=\(keyValuePair.value)"
        }

        // 4.  The sorted name/value pairs are concatenated together into a
        // single string by using an "&" character (ASCII code 38) as
        // separator.
        let normalizedParameters = parameterStrings.joined(separator: "&")
        return normalizedParameters
    }

    func collectParameters(queryItems: [URLQueryItem], oauthParameters: [KeyValuePair], formData: Data?) -> [KeyValuePair] {
        // The parameters from the following sources are collected into a single
        // list of name/value pairs:
        //
        // o  The query component of the HTTP request URI as defined by
        // [RFC3986], Section 3.4.  The query component is parsed into a list
        // of name/value pairs by treating it as an
        // "application/x-www-form-urlencoded" string, separating the names
        // and values and decoding them as defined by
        // [W3C.REC-html40-19980424], Section 17.13.4.
        var parameters: [KeyValuePair] = queryItems.map { queryItem in
            let name = queryItem.name.addingUrlSafePercentEncoding()
            let value = queryItem.value?.addingUrlSafePercentEncoding()
            return (name, value ?? "")
        }

        // o  The OAuth HTTP "Authorization" header field (Section 3.5.1) if
        //     present.  The header's content is parsed into a list of name/value
        // pairs excluding the "realm" parameter if present.  The parameter
        // values are decoded as defined by Section 3.5.1.
        oauthParameters.forEach { pair in
            let key = pair.key.addingUrlSafePercentEncoding()
            let value = pair.value.addingUrlSafePercentEncoding()
            parameters.append((key: key, value: value))
        }

        // o  The HTTP request entity-body, but only if all of the following
        //   conditions are met
        if let formData = formData {
            let formParameters = collectParameters(formData: formData)
            parameters.append(contentsOf: formParameters)
        }

        // The "oauth_signature" parameter MUST be excluded from the signature
        // base string if present.  Parameters not explicitly included in the
        // request MUST be excluded from the signature base string (e.g., the
        // "oauth_version" parameter when omitted).
        return parameters
    }

    /// Parse Data containing HTTP form data in the format required for application/x-www-form-urlencoded,
    /// returning KeyValuePair list of parameters if the form data was well formed.
    ///
    /// - Parameter formData: The form data to turn into parameters
    /// - Returns: A list of parameters
    func collectParameters(formData: Data) -> [KeyValuePair] {
        // o  The HTTP request entity-body, but only if all of the following
        // conditions are met:
        //
        //      *  The entity-body is single-part.
        //
        //      *  The entity-body follows the encoding requirements of the
        //          "application/x-www-form-urlencoded" content-type as defined by
        //          [W3C.REC-html40-19980424].
        //
        //      *  The HTTP request entity-header includes the "Content-Type"
        //          header field set to "application/x-www-form-urlencoded".
        //
        // The entity-body is parsed into a list of decoded name/value pairs
        // as described in [W3C.REC-html40-19980424], Section 17.13.4
        guard let formString = String(data: formData, encoding: .utf8) else { return [] }

        let formItems = formString.components(separatedBy: "&")

        let formParameters = formItems.compactMap { item -> KeyValuePair? in
            let parts = item.split(separator: "=")
            guard let key = parts.first, parts.count < 3 else { return nil }

            // Swap the form encoding's "+" for " " (space)
            let encodedKey = key.replacingOccurrences(of: "+", with: " ").addingUrlSafePercentEncoding()
            let value: String
            if parts.count > 1 {
                value = parts[1].replacingOccurrences(of: "+", with: " ").addingUrlSafePercentEncoding()
            } else {
                value = ""
            }

            return (key: encodedKey, value: value)
        }
        return formParameters
    }
}
