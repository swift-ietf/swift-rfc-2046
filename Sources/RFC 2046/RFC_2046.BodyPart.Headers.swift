import RFC_2045
import RFC_2183

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
    ///     contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg")
    /// )
    /// ```
    public struct Headers: Hashable, Sendable, Codable {
        /// Content-Disposition header (RFC 2183)
        public var contentDisposition: RFC_2183.ContentDisposition?

        /// Content-Type header (RFC 2045)
        public var contentType: RFC_2045.ContentType?

        /// Content-Transfer-Encoding header (RFC 2045)
        public var contentTransferEncoding: RFC_2045.ContentTransferEncoding?

        /// Custom headers not covered by typed properties
        public var custom: [String: String]

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
            custom: [String: String] = [:]
        ) {
            self.contentDisposition = contentDisposition
            self.contentType = contentType
            self.contentTransferEncoding = contentTransferEncoding
            self.custom = custom
        }

        /// Creates headers from a string dictionary (for backward compatibility)
        ///
        /// - Parameter dictionary: String-based header dictionary
        public init(parsing dictionary: [String: String]) {
            var remaining = dictionary

            // Parse Content-Disposition
            if let value = remaining.removeValue(forKey: "Content-Disposition") {
                self.contentDisposition = try? RFC_2183.ContentDisposition(parsing: value)
            }

            // Parse Content-Type
            if let value = remaining.removeValue(forKey: "Content-Type") {
                self.contentType = try? RFC_2045.ContentType(parsing: value)
            }

            // Parse Content-Transfer-Encoding
            if let value = remaining.removeValue(forKey: "Content-Transfer-Encoding") {
                self.contentTransferEncoding = try? RFC_2045.ContentTransferEncoding(parsing: value)
            }

            // Store remaining headers as custom
            self.custom = remaining
        }

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
                    return contentDisposition?.headerValue
                case "Content-Type":
                    return contentType?.headerValue
                case "Content-Transfer-Encoding":
                    return contentTransferEncoding?.headerValue
                default:
                    return custom[headerName]
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
                    custom[headerName] = newValue
                }
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
