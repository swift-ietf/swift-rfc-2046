public import RFC_5322

public extension RFC_2046 {
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
    struct BodyPart: Hashable, Sendable, Codable {
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

public extension RFC_2046.BodyPart {
    /// Creates a body part with Content-Type and binary content
    ///
    /// - Parameters:
    ///   - contentType: Content-Type for this part
    ///   - transferEncoding: Optional transfer encoding
    ///   - additionalHeaders: Additional custom headers
    ///   - content: The body content (binary data)
    init(
        contentType: RFC_2045.ContentType,
        transferEncoding: RFC_2045.ContentTransferEncoding? = nil,
        additionalHeaders: [RFC_5322.Header] = [],
        content: [UInt8]
    ) {
        headers = Headers(
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
    init(
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
    init(headers: Headers, text: String) {
        self.init(headers: headers, content: Array(text.utf8))
    }
}

// MARK: - Computed Properties

public extension RFC_2046.BodyPart {
    /// The Content-Type of this part, if specified
    var contentType: RFC_2045.ContentType? {
        guard let value = headers[.contentType] else { return nil }
        return try? RFC_2045.ContentType(value)
    }

    /// The Content-Transfer-Encoding of this part, if specified
    var transferEncoding: RFC_2045.ContentTransferEncoding? {
        guard let value = headers[.contentTransferEncoding] else { return nil }
        return RFC_2045.ContentTransferEncoding(rawValue: value)
    }

    /// The content decoded as UTF-8 text
    ///
    /// Returns nil if the content is not valid UTF-8.
    /// Useful for text parts and debugging.
    var textContent: String? {
        String(decoding: content, as: UTF8.self)
    }
}
