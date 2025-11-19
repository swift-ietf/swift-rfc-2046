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
    /// // Create from string with validation
    /// let boundary = try RFC_2046.Boundary("----=_Part_Custom")
    ///
    /// // Use in multipart
    /// let multipart = try RFC_2046.Multipart(
    ///     subtype: .mixed,
    ///     parts: parts,
    ///     boundary: boundary
    /// )
    /// ```
    ///
    /// ## Boundary Generation
    ///
    /// This type only validates boundaries. For generation, see higher-level
    /// packages like swift-email-standard which can use RFC 4648 for hex encoding.
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

        /// Creates a boundary from a string with validation
        ///
        /// Validates that the boundary conforms to RFC 2046 requirements.
        ///
        /// - Parameter value: The boundary string to validate
        /// - Throws: `RFC_2046.Multipart.Error` if validation fails
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
                throw RFC_2046.Multipart.Error.invalidBoundary(value)
            }

            guard (1...70).contains(value.count) else {
                throw RFC_2046.Multipart.Error.boundaryTooLong(
                    value,
                    length: value.count
                )
            }

            // RFC 2046: boundary must not end with a space
            guard !value.hasSuffix(" ") else {
                throw RFC_2046.Multipart.Error.invalidBoundary(value)
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
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

