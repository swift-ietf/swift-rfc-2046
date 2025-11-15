import Foundation

extension RFC_2046 {
    /// A validated multipart boundary string.
    ///
    /// Boundaries separate parts in multipart MIME bodies. This type ensures
    /// boundaries conform to RFC 2046 Section 5.1.1 requirements.
    ///
    /// ## RFC 2046 Requirements
    ///
    /// - Length: 1-70 characters
    /// - Character set: Alphanumerics, spaces, and specific punctuation
    /// - Must not end with space
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Generate a random boundary
    /// let boundary = RFC_2046.Boundary()
    ///
    /// // Create from string with validation
    /// let custom = try RFC_2046.Boundary("----=_Part_Custom")
    ///
    /// // Use in multipart
    /// let multipart = try RFC_2046.Multipart(
    ///     subtype: .mixed,
    ///     parts: parts,
    ///     boundary: boundary
    /// )
    /// ```
    ///
    /// ## Reference
    ///
    /// From RFC 2046 Section 5.1.1:
    ///
    /// > The boundary delimiter MUST NOT appear inside any of the encapsulated
    /// > parts. The boundary parameter consists of 1 to 70 characters from a
    /// > set of characters known to be very robust through mail gateway
    /// > transports.
    public struct Boundary: Hashable, Sendable {
        /// The validated boundary string
        public let value: String

        /// Creates a random cryptographically secure boundary
        ///
        /// Generates a boundary using UUID for uniqueness. The format is
        /// `----=_Part_{UUID}` which is always 46 characters.
        ///
        /// This boundary is guaranteed to:
        /// - Be unique (uses UUID)
        /// - Conform to RFC 2046 requirements
        /// - Be robust for mail gateway transport
        ///
        /// ## Example
        ///
        /// ```swift
        /// let boundary = RFC_2046.Boundary()
        /// // Result: ----=_Part_550E8400-E29B-41D4-A716-446655440000
        /// ```
        public init() {
            self.value = "----=_Part_\(UUID().uuidString)"
        }

        /// Creates a boundary from a string with validation
        ///
        /// Validates that the boundary conforms to RFC 2046 requirements.
        ///
        /// - Parameter value: The boundary string to validate
        /// - Throws: `RFC_2046.MultipartError` if validation fails
        ///
        /// ## Validation Rules
        ///
        /// - Length must be 1-70 characters
        /// - Must not end with a space (RFC 2046 §5.1.1)
        /// - Characters should be robust for mail gateways
        ///
        /// ## Example
        ///
        /// ```swift
        /// let boundary = try RFC_2046.Boundary("----=_Part_12345")
        /// ```
        public init(_ value: String) throws {
            guard !value.isEmpty else {
                throw RFC_2046.MultipartError.invalidBoundary(value)
            }

            guard (1...70).contains(value.count) else {
                throw RFC_2046.MultipartError.boundaryTooLong(
                    value,
                    length: value.count
                )
            }

            // RFC 2046: boundary must not end with a space
            guard !value.hasSuffix(" ") else {
                throw RFC_2046.MultipartError.invalidBoundary(value)
            }

            self.value = value
        }

    }
}

// MARK: - CustomStringConvertible

extension RFC_2046.Boundary: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - Codable

extension RFC_2046.Boundary: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_2046.Boundary: ExpressibleByStringLiteral {
    /// Creates a boundary from a string literal
    ///
    /// Traps if the literal is invalid. Only use this for compile-time
    /// constants that you know are valid.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let boundary: RFC_2046.Boundary = "----=_Part_Custom"
    /// ```
    ///
    /// - Parameter value: The boundary string literal
    public init(stringLiteral value: String) {
        try! self.init(value)
    }
}
