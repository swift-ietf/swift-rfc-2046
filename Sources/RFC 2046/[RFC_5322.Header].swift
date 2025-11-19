//
//  [RFC_5322.Header].swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

import RFC_5322

// MARK: - Convenience Initializers

extension [RFC_5322.Header] {
    /// Creates a header array from a string dictionary
    ///
    /// Note: Dictionary-based creation loses header order and duplicates.
    /// For preserving order, construct the array directly.
    ///
    /// - Parameter dictionary: String-keyed dictionary of header values
    /// - Returns: Array of RFC 5322 headers
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers = [RFC_5322.Header](dictionary: [
    ///     "X-Custom": "value",
    ///     "X-Priority": "1"
    /// ])
    /// ```
    public init(dictionary: [String: String]) {
        self = dictionary.map { key, value in
            RFC_5322.Header(name: RFC_5322.Header.Name(key), value: value)
        }
    }
}
