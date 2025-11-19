import INCITS_4_1986
import RFC_2045
import RFC_4648

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
        ///   - boundary: Boundary delimiter (caller must provide)
        ///   - preamble: Optional preamble text
        ///   - epilogue: Optional epilogue text
        ///   - additionalParameters: Additional Content-Type parameters (e.g., type, start for RFC 2387)
        ///
        /// - Throws: `RFC_2046.Multipart.Error.emptyParts` if parts array is empty
        public init(
            subtype: Subtype,
            parts: [BodyPart],
            boundary: Boundary,
            preamble: String? = nil,
            epilogue: String? = nil,
            additionalParameters: [String: String] = [:]
        ) throws {
            guard !parts.isEmpty else {
                throw RFC_2046.Multipart.Error.emptyParts
            }

            self.subtype = subtype
            self.parts = parts
            self.boundary = boundary
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
        ///   - boundary: Boundary string to validate
        ///   - preamble: Optional preamble text
        ///   - epilogue: Optional epilogue text
        ///   - additionalParameters: Additional Content-Type parameters
        ///
        /// - Throws: `RFC_2046.Multipart.Error` if validation fails
        public init(
            subtype: Subtype,
            parts: [BodyPart],
            boundary: String,
            preamble: String? = nil,
            epilogue: String? = nil,
            additionalParameters: [String: String] = [:]
        ) throws {
            try self.init(
                subtype: subtype,
                parts: parts,
                boundary: try Boundary(boundary),
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
                lines.append(String(part.headers))
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
        /// - Throws: `RFC_2046.Multipart.Error.invalidFormat` if parsing fails
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

            // Split by CRLF, CR, or LF (RFC 2046 requires CRLF, but be lenient)
            var lines: [String] = []
            var lineBytes: [UInt8] = []

            var i = string.utf8.startIndex
            while i < string.utf8.endIndex {
                let byte = string.utf8[i]

                if byte == UInt8.cr {
                    let next = string.utf8.index(after: i)
                    if next < string.utf8.endIndex && string.utf8[next] == UInt8.lf {
                        // CRLF
                        lines.append(String(decoding: lineBytes, as: UTF8.self))
                        lineBytes = []
                        i = string.utf8.index(after: next)
                    } else {
                        // Just CR
                        lines.append(String(decoding: lineBytes, as: UTF8.self))
                        lineBytes = []
                        i = next
                    }
                } else if byte == UInt8.lf {
                    // Just LF
                    lines.append(String(decoding: lineBytes, as: UTF8.self))
                    lineBytes = []
                    i = string.utf8.index(after: i)
                } else {
                    lineBytes.append(byte)
                    i = string.utf8.index(after: i)
                }
            }
            // Add final line
            lines.append(String(decoding: lineBytes, as: UTF8.self))

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
                        parts.append(BodyPart(headers: BodyPart.Headers(parsing: partHeaders), text: content))
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
                        parts.append(BodyPart(headers: BodyPart.Headers(parsing: partHeaders), text: content))
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
                            let headerName = String(line[..<colonIndex]).trimming(Set([" ", "\t"]))
                            let headerValue = String(line[line.index(after: colonIndex)...]).trimming(Set([" ", "\t"]))
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


