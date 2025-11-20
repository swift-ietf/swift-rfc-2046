public import RFC_4648
public import RFC_5322

extension RFC_2046 {
    /// A single part within a multipart message
    ///
    /// Each body part has its own headers and content (text or binary).
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Text content
    /// let textPart = RFC_2046.BodyPart(
    ///     contentType: .textPlainUTF8,
    ///     text: "Hello!"
    /// )
    ///
    /// // Binary content
    /// let imagePart = RFC_2046.BodyPart(
    ///     contentType: RFC_2045.ContentType(type: "image", subtype: "png"),
    ///     transferEncoding: .base64,
    ///     content: imageData
    /// )
    /// ```
    public struct BodyPart: Hashable, Sendable, Codable {
        /// Type-safe headers for this body part
        public let headers: Headers

        /// Content of this body part (binary data)
        public let content: [UInt8]

        /// Creates a body part with typed headers and binary content
        ///
        /// - Parameters:
        ///   - headers: Type-safe MIME headers for this part
        ///   - content: The body content (binary data)
        public init(headers: Headers, content: [UInt8]) {
            self.headers = headers
            self.content = content
        }
    }
}

// MARK: - Convenience Initializers

extension RFC_2046.BodyPart {
    /// Creates a body part with Content-Type and binary content
    ///
    /// - Parameters:
    ///   - contentType: Content-Type for this part
    ///   - transferEncoding: Optional transfer encoding
    ///   - additionalHeaders: Additional custom headers
    ///   - content: The body content (binary data)
    public init(
        contentType: RFC_2045.ContentType,
        transferEncoding: RFC_2045.ContentTransferEncoding? = nil,
        additionalHeaders: [RFC_5322.Header] = [],
        content: [UInt8]
    ) {
        self.headers = Headers(
            contentType: contentType,
            contentTransferEncoding: transferEncoding,
            custom: additionalHeaders
        )
        self.content = content
    }

    /// Creates a body part with Content-Type and text content
    ///
    /// Convenience initializer for text content that converts to UTF-8 data.
    ///
    /// - Parameters:
    ///   - contentType: Content-Type for this part
    ///   - transferEncoding: Optional transfer encoding
    ///   - additionalHeaders: Additional custom headers
    ///   - text: The text content (will be converted to UTF-8)
    public init(
        contentType: RFC_2045.ContentType,
        transferEncoding: RFC_2045.ContentTransferEncoding? = nil,
        additionalHeaders: [RFC_5322.Header] = [],
        text: String
    ) {
        self.init(
            contentType: contentType,
            transferEncoding: transferEncoding,
            additionalHeaders: additionalHeaders,
            content: Array(text.utf8)
        )
    }

    /// Creates a body part with typed headers and text content
    ///
    /// Convenience initializer for text content that converts to UTF-8 data.
    ///
    /// - Parameters:
    ///   - headers: Type-safe MIME headers for this part
    ///   - text: The text content (will be converted to UTF-8)
    public init(headers: Headers, text: String) {
        self.init(headers: headers, content: Array(text.utf8))
    }
}

// MARK: - Rendering

extension RFC_2046.BodyPart {
    /// Renders the content with appropriate encoding
    ///
    /// Applies Content-Transfer-Encoding if specified in headers:
    /// - base64: Encodes content as base64
    /// - quoted-printable: Encodes with quoted-printable (fallback to raw for now)
    /// - 7bit/8bit/binary: Uses raw content as UTF-8 string
    func renderContent() -> String {
        if let encoding = transferEncoding {
            switch encoding {
            case .base64:
                let encoded = RFC_4648.Base64.encode(content)
                return String(decoding: encoded, as: UTF8.self)
            case .quotedPrintable:
                // TODO: Implement quoted-printable encoding
                // For now, fall through to raw
                fallthrough
            default:
                // 7bit, 8bit, binary: treat as UTF-8 text
                return String(decoding: content, as: UTF8.self)
            }
        } else {
            // No encoding specified: treat as UTF-8 text
            return String(decoding: content, as: UTF8.self)
        }
    }
}

// MARK: - Computed Properties

extension RFC_2046.BodyPart {
    /// The Content-Type of this part, if specified
    public var contentType: RFC_2045.ContentType? {
        guard let value = headers["Content-Type"] else { return nil }
        return try? RFC_2045.ContentType(parsing: value)
    }

    /// The Content-Transfer-Encoding of this part, if specified
    public var transferEncoding: RFC_2045.ContentTransferEncoding? {
        guard let value = headers["Content-Transfer-Encoding"] else { return nil }
        return try? RFC_2045.ContentTransferEncoding(parsing: value)
    }

    /// The content decoded as UTF-8 text
    ///
    /// Returns nil if the content is not valid UTF-8.
    /// Useful for text parts and debugging.
    public var textContent: String? {
        String(decoding: content, as: UTF8.self)
    }
}
