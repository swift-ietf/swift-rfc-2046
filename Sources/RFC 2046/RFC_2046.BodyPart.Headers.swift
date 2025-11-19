import RFC_2045
import RFC_2183
import RFC_5322

extension RFC_2046.BodyPart {
    /// Type-safe headers for multipart body parts
    ///
    /// This structure provides type-safe access to common MIME headers while
    /// supporting custom headers as needed. Type safety is maintained throughout
    /// the codebase until the final encoding step.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers = RFC_2046.BodyPart.Headers(
    ///     contentDisposition: .formData(name: "avatar", filename: "photo.jpg"),
    ///     contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
    ///     custom: [
    ///         .init(name: "X-Custom-Header", value: "value")
    ///     ]
    /// )
    ///
    /// // Convenient subscript access
    /// headers.custom["X-Priority"] = "1"
    /// ```
    public struct Headers: Hashable, Sendable, Codable {
        /// Content-Disposition header (RFC 2183)
        public var contentDisposition: RFC_2183.ContentDisposition?

        /// Content-Type header (RFC 2045)
        public var contentType: RFC_2045.ContentType?

        /// Content-Transfer-Encoding header (RFC 2045)
        public var contentTransferEncoding: RFC_2045.ContentTransferEncoding?

        /// Additional custom headers
        ///
        /// Preserves order and allows multiple headers with the same name per RFC 5322.
        /// Uses RFC 5322's convenient subscript for access: `custom["X-Header"] = "value"`
        ///
        /// ## Example
        ///
        /// ```swift
        /// var headers = Headers()
        ///
        /// // Subscript access (gets/sets first match)
        /// headers.custom["X-Custom"] = "value"
        ///
        /// // Multiple headers with same name
        /// headers.custom.append(.init(name: "Received", value: "from mail1.example.com"))
        /// headers.custom.append(.init(name: "Received", value: "from mail2.example.com"))
        ///
        /// // Get all values for a name
        /// let received = headers.custom.values(for: "Received")
        /// ```
        public var custom: [RFC_5322.Header]

        /// Creates typed headers
        ///
        /// - Parameters:
        ///   - contentDisposition: Optional Content-Disposition header
        ///   - contentType: Optional Content-Type header
        ///   - contentTransferEncoding: Optional Content-Transfer-Encoding header
        ///   - custom: Additional custom headers
        public init(
            contentDisposition: RFC_2183.ContentDisposition? = nil,
            contentType: RFC_2045.ContentType? = nil,
            contentTransferEncoding: RFC_2045.ContentTransferEncoding? = nil,
            custom: [RFC_5322.Header] = []
        ) {
            self.contentDisposition = contentDisposition
            self.contentType = contentType
            self.contentTransferEncoding = contentTransferEncoding
            self.custom = custom
        }

        /// Creates typed headers with dictionary-based custom headers
        ///
        /// Note: Dictionary loses header order and duplicates.
        /// Prefer the array-based init for preserving order.
        ///
        /// - Parameters:
        ///   - contentDisposition: Optional Content-Disposition header
        ///   - contentType: Optional Content-Type header
        ///   - contentTransferEncoding: Optional Content-Transfer-Encoding header
        ///   - custom: Additional custom headers as dictionary
        public init(
            contentDisposition: RFC_2183.ContentDisposition? = nil,
            contentType: RFC_2045.ContentType? = nil,
            contentTransferEncoding: RFC_2045.ContentTransferEncoding? = nil,
            custom: [String: String]
        ) {
            self.init(
                contentDisposition: contentDisposition,
                contentType: contentType,
                contentTransferEncoding: contentTransferEncoding,
                custom: [RFC_5322.Header](dictionary: custom)
            )
        }
    }
}

// MARK: - Parsing

extension RFC_2046.BodyPart.Headers {
    /// Creates headers from an array of RFC 5322 headers
    ///
    /// Preserves header order and allows duplicate headers per RFC 5322.
    ///
    /// - Parameter headers: Array of RFC 5322 headers
    public init(parsing headers: [RFC_5322.Header]) {
        var contentDisposition: RFC_2183.ContentDisposition?
        var contentType: RFC_2045.ContentType?
        var contentTransferEncoding: RFC_2045.ContentTransferEncoding?
        var customHeaders: [RFC_5322.Header] = []

        // Parse headers, extracting known types
        for header in headers {
            switch header.name {
            case .contentDisposition:
                contentDisposition = try? RFC_2183.ContentDisposition(parsing: header.value)
            case .contentType:
                contentType = try? RFC_2045.ContentType(parsing: header.value)
            case .contentTransferEncoding:
                contentTransferEncoding = try? RFC_2045.ContentTransferEncoding(parsing: header.value)
            default:
                // Keep custom headers in order
                customHeaders.append(header)
            }
        }

        // Use canonical init
        self.init(
            contentDisposition: contentDisposition,
            contentType: contentType,
            contentTransferEncoding: contentTransferEncoding,
            custom: customHeaders
        )
    }

    /// Creates headers from a type-safe dictionary
    ///
    /// Note: Dictionary parsing loses header order and duplicates.
    /// Prefer the array-based init for preserving order.
    ///
    /// - Parameter dictionary: Type-safe dictionary of headers
    public init(parsing dictionary: [RFC_5322.Header.Name: String]) {
        // Convert to headers array
        let headers = dictionary.map { name, value in
            RFC_5322.Header(name: name, value: value)
        }
        self.init(parsing: headers)
    }
}

// MARK: - Subscript

extension RFC_2046.BodyPart.Headers {
    /// Subscript access to header values by name
    ///
    /// Provides string-based access to headers for convenience. Typed properties should be preferred.
    ///
    /// - Parameter headerName: Case-sensitive header name (e.g., "Content-Type")
    /// - Returns: Header value as string, or nil if not present
    public subscript(headerName: String) -> String? {
        get {
            switch headerName {
            case "Content-Disposition":
                return contentDisposition.map(String.init)
            case "Content-Type":
                return contentType?.headerValue
            case "Content-Transfer-Encoding":
                return contentTransferEncoding?.headerValue
            default:
                // Delegate to RFC_5322.Header array subscript
                return custom[RFC_5322.Header.Name(headerName)]
            }
        }
        set {
            switch headerName {
            case "Content-Disposition":
                if let value = newValue {
                    contentDisposition = try? RFC_2183.ContentDisposition(parsing: value)
                } else {
                    contentDisposition = nil
                }
            case "Content-Type":
                if let value = newValue {
                    contentType = try? RFC_2045.ContentType(parsing: value)
                } else {
                    contentType = nil
                }
            case "Content-Transfer-Encoding":
                if let value = newValue {
                    contentTransferEncoding = try? RFC_2045.ContentTransferEncoding(parsing: value)
                } else {
                    contentTransferEncoding = nil
                }
            default:
                // Delegate to RFC_5322.Header array subscript
                custom[RFC_5322.Header.Name(headerName)] = newValue
            }
        }
    }
}

// MARK: - Convenience Constructors

extension RFC_2046.BodyPart.Headers {
    /// Creates headers for a form-data text field
    ///
    /// - Parameter name: Form field name
    /// - Returns: Headers configured for a text field
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers = RFC_2046.BodyPart.Headers.formDataTextField(name: "username")
    /// ```
    public static func formDataTextField(name: String) -> Self {
        Self(contentDisposition: .formData(name: name))
    }

    /// Creates headers for a form-data file upload
    ///
    /// - Parameters:
    ///   - name: Form field name
    ///   - filename: Filename for the upload
    ///   - contentType: Optional content type (defaults to application/octet-stream)
    /// - Returns: Headers configured for a file upload
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers = RFC_2046.BodyPart.Headers.formDataFile(
    ///     name: "avatar",
    ///     filename: "photo.jpg",
    ///     contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg")
    /// )
    /// ```
    public static func formDataFile(
        name: String,
        filename: String,
        contentType: RFC_2045.ContentType? = nil
    ) -> Self {
        Self(
            contentDisposition: .formData(name: name, filename: filename),
            contentType: contentType
        )
    }
}
