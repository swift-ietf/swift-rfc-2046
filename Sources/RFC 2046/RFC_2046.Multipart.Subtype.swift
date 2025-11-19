//
//  File.swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

extension RFC_2046.Multipart {
    /// Multipart subtype
    ///
    /// Represents the subtype portion of a multipart Content-Type.
    /// RFC 2046 defines several standard subtypes, but unknown subtypes
    /// should be treated as equivalent to "mixed" per RFC 2046 Section 5.1.7.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Using standard subtypes
    /// let multipart = RFC_2046.Multipart(subtype: .alternative, parts: [...])
    ///
    /// // Custom subtype
    /// let custom = RFC_2046.Multipart(
    ///     subtype: Subtype(rawValue: "x-custom"),
    ///     parts: [...]
    /// )
    ///
    /// // HTTP form data (RFC 7578)
    /// let formData = RFC_2046.Multipart(subtype: .formData, parts: [...])
    /// ```
    ///
    /// ## RFC References
    ///
    /// - RFC 2046: MIME Part Two - Media Types (base multipart specification)
    /// - RFC 2387: The MIME Multipart/Related Content-type (related subtype)
    /// - RFC 7578: Returning Values from Forms: multipart/form-data (form-data subtype)
    public struct Subtype: RawRepresentable, Hashable, Sendable, Codable {
        public let rawValue: String

        /// Creates a multipart subtype
        ///
        /// - Parameter rawValue: The subtype name (case-insensitive)
        public init(rawValue: String) {
            self.rawValue = rawValue.lowercased()
        }

        // MARK: - RFC 2046 Standard Subtypes

        /// Independent body parts in specified order
        ///
        /// Used when body parts are independent and should be
        /// presented in sequence.
        ///
        /// **RFC 2046 Section 5.1.3**
        public static let mixed = Subtype(rawValue: "mixed")

        /// Alternative representations of same content
        ///
        /// Body parts are alternative versions of the same information.
        /// Mail clients should display the last one they understand.
        ///
        /// **RFC 2046 Section 5.1.4**
        public static let alternative = Subtype(rawValue: "alternative")

        /// Collection of messages
        ///
        /// Each body part is a complete message (RFC 822).
        /// Default Content-Type for parts is `message/rfc822`.
        ///
        /// **RFC 2046 Section 5.1.5**
        public static let digest = Subtype(rawValue: "digest")

        /// Body parts to be viewed simultaneously
        ///
        /// All parts should be presented at the same time
        /// (e.g., for compound documents).
        ///
        /// **RFC 2046 Section 5.1.6**
        public static let parallel = Subtype(rawValue: "parallel")
    }
}
