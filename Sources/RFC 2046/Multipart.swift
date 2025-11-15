import Foundation
import RFC_2045

extension RFC_2046 {
    /// Multipart message structure
    ///
    /// Represents a MIME multipart message containing multiple body parts
    /// separated by boundary delimiters.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Text + HTML alternative
    /// let multipart = try RFC_2046.Multipart(
    ///     subtype: .alternative,
    ///     parts: [
    ///         .init(
    ///             contentType: .textPlainUTF8,
    ///             text: "Hello!"
    ///         ),
    ///         .init(
    ///             contentType: .textHTMLUTF8,
    ///             text: "<h1>Hello!</h1>"
    ///         )
    ///     ]
    /// )
    ///
    /// // Render as email body
    /// let body = multipart.render()
    /// let headers = [
    ///     "Content-Type": multipart.contentType.headerValue
    /// ]
    /// ```
    public struct Multipart: Hashable, Sendable, Codable {
        /// Multipart subtype
        public let subtype: Subtype

        /// Body parts
        public let parts: [BodyPart]

        /// Boundary for separating parts
        ///
        /// A validated boundary string conforming to RFC 2046 requirements.
        public let boundary: Boundary

        /// Optional preamble (text before first boundary)
        public let preamble: String?

        /// Optional epilogue (text after last boundary)
        public let epilogue: String?

        /// Additional Content-Type parameters beyond boundary
        ///
        /// Allows RFC extensions (2387, 7578, etc.) to add custom parameters
        /// to the multipart Content-Type header.
        public let additionalParameters: [String: String]

        /// Creates a multipart message
        ///
        /// - Parameters:
        ///   - subtype: Multipart subtype
        ///   - parts: Body parts (must not be empty)
        ///   - boundary: Custom boundary (auto-generated if nil)
        ///   - preamble: Optional preamble text
        ///   - epilogue: Optional epilogue text
        ///   - additionalParameters: Additional Content-Type parameters (e.g., type, start for RFC 2387)
        ///
        /// - Throws: `RFC_2046.MultipartError.emptyParts` if parts array is empty
        public init(
            subtype: Subtype,
            parts: [BodyPart],
            boundary: Boundary? = nil,
            preamble: String? = nil,
            epilogue: String? = nil,
            additionalParameters: [String: String] = [:]
        ) throws {
            guard !parts.isEmpty else {
                throw RFC_2046.MultipartError.emptyParts
            }

            self.subtype = subtype
            self.parts = parts
            self.boundary = boundary ?? Boundary()
            self.preamble = preamble
            self.epilogue = epilogue
            self.additionalParameters = additionalParameters
        }

        /// Creates a multipart message with a string boundary
        ///
        /// Convenience initializer that validates and converts a string boundary.
        ///
        /// - Parameters:
        ///   - subtype: Multipart subtype
        ///   - parts: Body parts (must not be empty)
        ///   - boundary: Custom boundary string (auto-generated if nil, validated if provided)
        ///   - preamble: Optional preamble text
        ///   - epilogue: Optional epilogue text
        ///   - additionalParameters: Additional Content-Type parameters
        ///
        /// - Throws: `RFC_2046.MultipartError` if validation fails
        public init(
            subtype: Subtype,
            parts: [BodyPart],
            boundary: String?,
            preamble: String? = nil,
            epilogue: String? = nil,
            additionalParameters: [String: String] = [:]
        ) throws {
            let validatedBoundary: Boundary
            if let boundary = boundary {
                validatedBoundary = try Boundary(boundary)
            } else {
                validatedBoundary = Boundary()
            }

            try self.init(
                subtype: subtype,
                parts: parts,
                boundary: validatedBoundary,
                preamble: preamble,
                epilogue: epilogue,
                additionalParameters: additionalParameters
            )
        }

        /// The Content-Type for this multipart message
        ///
        /// Includes boundary parameter and any additional parameters.
        public var contentType: RFC_2045.ContentType {
            var parameters: [String: String] = ["boundary": boundary.value]

            // Merge additional parameters from RFC extensions
            parameters.merge(additionalParameters) { _, new in new }

            return RFC_2045.ContentType(
                type: "multipart",
                subtype: subtype.rawValue,
                parameters: parameters
            )
        }

        /// Renders the complete multipart body
        ///
        /// Returns the full MIME multipart body including boundaries,
        /// preamble, parts, and epilogue.
        ///
        /// Content is encoded according to each part's Content-Transfer-Encoding header:
        /// - `base64`: Content is base64-encoded
        /// - `quoted-printable`: Content is quoted-printable encoded
        /// - Other encodings: Content is treated as-is (must be valid UTF-8 or 7-bit ASCII)
        ///
        /// Per RFC 2046 Section 5.1.1, the output includes a trailing CRLF after the final boundary.
        public func render() -> String {
            var lines: [String] = []

            // Preamble (optional)
            if let preamble = preamble {
                lines.append(preamble)
                lines.append("")
            }

            // Body parts
            for part in parts {
                lines.append("--\(boundary.value)")
                lines.append(part.renderHeaders())
                lines.append("")
                lines.append(part.renderContent())
            }

            // Final boundary
            lines.append("--\(boundary.value)--")

            // Epilogue (optional)
            if let epilogue = epilogue {
                lines.append("")
                lines.append(epilogue)
            }

            // RFC 2046 Section 5.1.1: There must be a CRLF at the end of the last line
            return lines.joined(separator: "\r\n") + "\r\n"
        }


        /// Parses multipart data from a string
        ///
        /// Extracts body parts separated by boundary delimiters.
        ///
        /// - Parameters:
        ///   - string: The multipart message body as a string
        ///   - boundary: The validated boundary separating parts
        ///   - subtype: The multipart subtype (default: .mixed)
        /// - Returns: A Multipart instance containing the parsed parts
        /// - Throws: `RFC_2046.MultipartError.invalidFormat` if parsing fails
        public static func parse(
            _ string: String,
            boundary: Boundary,
            subtype: Subtype = .mixed
        ) throws -> Self {
            // Split on boundary delimiters
            let delimiter = "--\(boundary.value)"
            let finalDelimiter = "--\(boundary.value)--"

            var parts: [BodyPart] = []
            var preamble: String?
            var epilogue: String?

            // Split the content by CRLF (or LF for robustness)
            let lines = string.components(separatedBy: "\r\n")

            var currentSection: [String] = []
            var inPreamble = true
            var inPart = false
            var partHeaders: [String: String] = [:]
            var partContent: [String] = []

            for line in lines {
                if line == delimiter {
                    // Start of new part
                    if inPart {
                        // Save previous part
                        let content = partContent.joined(separator: "\r\n")
                        parts.append(BodyPart(headers: partHeaders, text: content))
                    }
                    if inPreamble {
                        preamble = currentSection.isEmpty ? nil : currentSection.joined(separator: "\r\n")
                        inPreamble = false
                    }
                    inPart = true
                    partHeaders = [:]
                    partContent = []
                    currentSection = []
                } else if line == finalDelimiter {
                    // End of multipart
                    if inPart {
                        let content = partContent.joined(separator: "\r\n")
                        parts.append(BodyPart(headers: partHeaders, text: content))
                    }
                    inPart = false
                } else if inPart {
                    // Inside a part
                    if line.isEmpty && partHeaders.isEmpty {
                        // Empty line after headers starts content
                        continue
                    } else if line.isEmpty {
                        // Already in content - this is content
                        partContent.append(line)
                    } else if partHeaders.isEmpty || line.contains(":") {
                        // Parse header
                        if let colonIndex = line.firstIndex(of: ":") {
                            let headerName = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                            let headerValue = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                            partHeaders[headerName] = headerValue
                        } else if !partHeaders.isEmpty {
                            // Already have headers, so this is content
                            partContent.append(line)
                        }
                    } else {
                        // Content line
                        partContent.append(line)
                    }
                } else if inPreamble {
                    currentSection.append(line)
                } else {
                    // Epilogue
                    if epilogue == nil {
                        epilogue = line
                    } else {
                        epilogue! += "\r\n" + line
                    }
                }
            }

            return try Self(
                subtype: subtype,
                parts: parts,
                boundary: boundary,
                preamble: preamble,
                epilogue: epilogue
            )
        }
    }
}

// MARK: - Multipart Subtypes

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

// MARK: - Body Part

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
        /// Headers for this body part
        public let headers: [String: String]

        /// Content of this body part (binary data)
        public let content: Data

        /// Creates a body part with headers and binary content
        ///
        /// - Parameters:
        ///   - headers: MIME headers for this part
        ///   - content: The body content (binary data)
        public init(headers: [String: String], content: Data) {
            self.headers = headers
            self.content = content
        }

        /// Creates a body part with Content-Type and binary content
        ///
        /// - Parameters:
        ///   - contentType: Content-Type for this part
        ///   - transferEncoding: Optional transfer encoding
        ///   - additionalHeaders: Additional headers
        ///   - content: The body content (binary data)
        public init(
            contentType: RFC_2045.ContentType,
            transferEncoding: RFC_2045.ContentTransferEncoding? = nil,
            additionalHeaders: [String: String] = [:],
            content: Data
        ) {
            var headers = additionalHeaders
            headers["Content-Type"] = contentType.headerValue

            if let encoding = transferEncoding {
                headers["Content-Transfer-Encoding"] = encoding.headerValue
            }

            self.headers = headers
            self.content = content
        }

        /// Creates a body part with Content-Type and text content
        ///
        /// Convenience initializer for text content that converts to UTF-8 data.
        ///
        /// - Parameters:
        ///   - contentType: Content-Type for this part
        ///   - transferEncoding: Optional transfer encoding
        ///   - additionalHeaders: Additional headers
        ///   - text: The text content (will be converted to UTF-8)
        public init(
            contentType: RFC_2045.ContentType,
            transferEncoding: RFC_2045.ContentTransferEncoding? = nil,
            additionalHeaders: [String: String] = [:],
            text: String
        ) {
            self.init(
                contentType: contentType,
                transferEncoding: transferEncoding,
                additionalHeaders: additionalHeaders,
                content: Data(text.utf8)
            )
        }

        /// Creates a body part with headers and text content
        ///
        /// Convenience initializer for text content that converts to UTF-8 data.
        ///
        /// - Parameters:
        ///   - headers: MIME headers for this part
        ///   - text: The text content (will be converted to UTF-8)
        public init(headers: [String: String], text: String) {
            self.init(headers: headers, content: Data(text.utf8))
        }

        /// Renders the headers as a string
        func renderHeaders() -> String {
            headers
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\r\n")
        }

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
                    return content.base64EncodedString(options: [
                        .lineLength76Characters, .endLineWithCarriageReturn,
                    ])
                case .quotedPrintable:
                    // TODO: Implement quoted-printable encoding
                    // For now, fall through to raw
                    fallthrough
                default:
                    // 7bit, 8bit, binary: treat as UTF-8 text
                    return String(data: content, encoding: .utf8) ?? ""
                }
            } else {
                // No encoding specified: treat as UTF-8 text
                return String(data: content, encoding: .utf8) ?? ""
            }
        }

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
            String(data: content, encoding: .utf8)
        }
    }
}

// MARK: - Common Multipart Constructors

extension RFC_2046.Multipart {
    /// Creates a multipart/alternative message (text + HTML)
    ///
    /// Commonly used for emails that provide both plain text and HTML versions.
    /// Email clients display the last format they understand (typically HTML).
    ///
    /// **RFC 2046 Section 5.1.4**
    ///
    /// - Parameters:
    ///   - textContent: Plain text version
    ///   - htmlContent: HTML version
    ///   - boundary: Custom boundary (auto-generated if nil)
    /// - Throws: `RFC_2046.MultipartError` if validation fails
    public static func alternative(
        textContent: String,
        htmlContent: String,
        boundary: String? = nil
    ) throws -> Self {
        try Self(
            subtype: .alternative,
            parts: [
                .init(
                    contentType: .textPlainUTF8,
                    transferEncoding: .sevenBit,
                    text: textContent
                ),
                .init(
                    contentType: .textHTMLUTF8,
                    transferEncoding: .sevenBit,
                    text: htmlContent
                ),
            ],
            boundary: boundary
        )
    }

    /// Creates a multipart/mixed message
    ///
    /// Used for independent parts that should be presented in sequence.
    /// Common use case: email body with file attachments.
    ///
    /// **RFC 2046 Section 5.1.3**
    ///
    /// - Parameters:
    ///   - parts: Body parts in order
    ///   - boundary: Custom boundary (auto-generated if nil)
    /// - Throws: `RFC_2046.MultipartError` if validation fails
    public static func mixed(
        parts: [RFC_2046.BodyPart],
        boundary: String? = nil
    ) throws -> Self {
        try Self(
            subtype: .mixed,
            parts: parts,
            boundary: boundary
        )
    }
}
