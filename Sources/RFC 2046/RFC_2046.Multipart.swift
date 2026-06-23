import INCITS_4_1986
public import RFC_2045
import RFC_4648
import RFC_5322

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
    /// // Serialize to bytes
    /// let bytes = [UInt8](multipart)
    /// let body = String(decoding: bytes, as: UTF8.self)
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
        ///
        /// Uses type-safe `RFC_2045.Parameter.Name` for parameter names.
        /// String literals work via `ExpressibleByStringLiteral` conformance.
        public let additionalParameters: [RFC_2045.Parameter.Name: String]

        /// Creates a multipart WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 2046 validation.
        /// Only use for internal construction after validation.
        public init(
            __unchecked _: Void,
            subtype: Subtype,
            parts: [BodyPart],
            boundary: Boundary,
            preamble: String?,
            epilogue: String?,
            additionalParameters: [RFC_2045.Parameter.Name: String]
        ) {
            self.subtype = subtype
            self.parts = parts
            self.boundary = boundary
            self.preamble = preamble
            self.epilogue = epilogue
            self.additionalParameters = additionalParameters
        }

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
            additionalParameters: [RFC_2045.Parameter.Name: String] = [:]
        ) throws(Error) {
            guard !parts.isEmpty else {
                throw RFC_2046.Multipart.Error.emptyParts
            }

            self.init(
                __unchecked: (),
                subtype: subtype,
                parts: parts,
                boundary: boundary,
                preamble: preamble,
                epilogue: epilogue,
                additionalParameters: additionalParameters
            )
        }
    }
}
//
//// MARK: - Convenience Initializers
//
// extension RFC_2046.Multipart {
//    /// Creates a multipart message with a string boundary
//    ///
//    /// Convenience initializer that validates and converts a string boundary.
//    ///
//    /// - Parameters:
//    ///   - subtype: Multipart subtype
//    ///   - parts: Body parts (must not be empty)
//    ///   - boundary: Boundary string to validate
//    ///   - preamble: Optional preamble text
//    ///   - epilogue: Optional epilogue text
//    ///   - additionalParameters: Additional Content-Type parameters
//    ///
//    /// - Throws: `RFC_2046.Multipart.Error` if validation fails
//    public init(
//        subtype: Subtype,
//        parts: [RFC_2046.BodyPart],
//        boundary: String,
//        preamble: String? = nil,
//        epilogue: String? = nil,
//        additionalParameters: [RFC_2045.Parameter.Name: String] = [:]
//    ) throws {
//        try self.init(
//            subtype: subtype,
//            parts: parts,
//            boundary: RFC_2046.Boundary(boundary),
//            preamble: preamble,
//            epilogue: epilogue,
//            additionalParameters: additionalParameters
//        )
//    }
// }

// MARK: - Computed Properties

extension RFC_2046.Multipart {
    /// The Content-Type for this multipart message
    ///
    /// Includes boundary parameter and any additional parameters.
    public var contentType: RFC_2045.ContentType {
        var parameters: [RFC_2045.Parameter.Name: String] = [.boundary: boundary.rawValue]

        // Merge additional parameters from RFC extensions
        parameters.merge(additionalParameters) { _, new in new }

        // Build content type string for parsing
        var headerValue = "multipart/\(subtype.rawValue)"
        for (key, value) in parameters.sorted(by: { $0.key < $1.key }) {
            headerValue += "; \(key.rawValue)=\(value)"
        }

        // swiftlint:disable:next force_try
        return try! RFC_2045.ContentType(headerValue)
    }
}

// MARK: - Parsing Context

extension RFC_2046.Multipart {
    /// Parsing context for multipart messages
    ///
    /// Multipart data requires the boundary delimiter to identify parts.
    /// The subtype defaults to `.mixed` if not specified.
    ///
    /// ## Category Theory
    ///
    /// Context-dependent parsing: `(Context, [Byte]) → Multipart`
    ///
    /// The same raw bytes can represent different multipart structures
    /// depending on the boundary delimiter in the context.
    public struct Context: Sendable {
        /// The boundary delimiter separating body parts
        public let boundary: RFC_2046.Boundary

        /// The multipart subtype (default: .mixed)
        public let subtype: Subtype

        /// Creates a parsing context
        ///
        /// - Parameters:
        ///   - boundary: The boundary delimiter for the multipart message
        ///   - subtype: The multipart subtype (default: .mixed)
        public init(boundary: RFC_2046.Boundary, subtype: Subtype = .mixed) {
            self.boundary = boundary
            self.subtype = subtype
        }
    }
}

// MARK: - Binary.ASCII.Serializable Conformance

extension RFC_2046.Multipart: Binary.ASCII.Serializable {
    /// Serialize to canonical ASCII byte representation
    ///
    /// Serialization is always context-free because the Multipart value
    /// contains its own boundary delimiter.
    ///
    /// ## RFC 2046 Format
    ///
    /// ```
    /// [preamble CRLF]
    /// --boundary CRLF
    /// headers CRLF
    /// CRLF
    /// content
    /// --boundary CRLF
    /// ...
    /// --boundary-- CRLF
    /// [epilogue]
    /// ```
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii multipart: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        let boundaryPrefix: [Byte] = [ASCII.Code.hyphen.byte, ASCII.Code.hyphen.byte]
        var boundaryBytes: [Byte] = []
        RFC_2046.Boundary.serialize(ascii: multipart.boundary, into: &boundaryBytes)

        // Preamble (optional)
        if let preamble = multipart.preamble {
            buffer.append(contentsOf: Array<Byte>(preamble.utf8))
            buffer.append(ASCII.Code.cr)
            buffer.append(ASCII.Code.lf)
            buffer.append(ASCII.Code.cr)
            buffer.append(ASCII.Code.lf)
        }

        // Body parts
        for part in multipart.parts {
            // Boundary delimiter
            buffer.append(contentsOf: boundaryPrefix)
            buffer.append(contentsOf: boundaryBytes)
            buffer.append(ASCII.Code.cr)
            buffer.append(ASCII.Code.lf)

            // Headers (using byte serialization) — migrated to Byte substrate.
            RFC_2046.BodyPart.Headers.serialize(ascii: part.headers, into: &buffer)

            // Blank line between headers and content
            buffer.append(ASCII.Code.cr)
            buffer.append(ASCII.Code.lf)

            // Content with encoding applied (may be binary).
            let contentBytes: [Byte] = part.content.rawValue
            if let encoding = part.transferEncoding {
                switch encoding {
                case .base64:
                    // Base64.encode takes [Byte] and returns [ASCII.Code]; bridge codes to bytes.
                    buffer.append(contentsOf: RFC_4648.Base64.encode(contentBytes).map(\.byte))
                case .quotedPrintable:
                    // Quoted-printable encoding not yet implemented; use raw content
                    buffer.append(contentsOf: contentBytes)
                default:
                    // 7bit, 8bit, binary: use raw content
                    buffer.append(contentsOf: contentBytes)
                }
            } else {
                // No encoding specified: use raw content
                buffer.append(contentsOf: contentBytes)
            }
            buffer.append(ASCII.Code.cr)
            buffer.append(ASCII.Code.lf)
        }

        // Final boundary
        buffer.append(contentsOf: boundaryPrefix)
        buffer.append(contentsOf: boundaryBytes)
        buffer.append(contentsOf: boundaryPrefix)  // "--" suffix for final
        buffer.append(ASCII.Code.cr)
        buffer.append(ASCII.Code.lf)

        // Epilogue (optional)
        if let epilogue = multipart.epilogue {
            buffer.append(contentsOf: Array<Byte>(epilogue.utf8))
            buffer.append(ASCII.Code.cr)
            buffer.append(ASCII.Code.lf)
        }
    }

    /// Parses multipart data from bytes with context (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// Multipart parsing requires context (boundary delimiter) to identify parts.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: (Context, [Byte]) where Context provides boundary
    /// - **Codomain**: RFC_2046.Multipart (structured data)
    ///
    /// Context provides the boundary delimiter required to split parts.
    /// Serialization is context-free since the Multipart contains its boundary.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let context = RFC_2046.Multipart.Context(
    ///     boundary: try RFC_2046.Boundary("----=_Part_123"),
    ///     subtype: .alternative
    /// )
    /// let multipart = try RFC_2046.Multipart(ascii: bytes, in: context)
    /// ```
    ///
    /// - Parameters:
    ///   - bytes: The multipart message body as ASCII bytes
    ///   - context: Parsing context containing boundary and subtype
    /// - Throws: `RFC_2046.Multipart.Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Context) throws(Error)
    where Bytes.Element == Byte {
        // MIME delimiters: "--boundary" and the closing "--boundary--". ASCII
        // codes append into the [Byte] buffer via Binary.ASCII.Serializable.
        let boundaryBytes: [Byte] = [Byte](context.boundary)

        var delimiter: [Byte] = []
        delimiter.reserveCapacity(2 + boundaryBytes.count)
        delimiter.append(ASCII.Code.hyphen)
        delimiter.append(ASCII.Code.hyphen)
        delimiter.append(contentsOf: boundaryBytes)

        var finalDelimiter: [Byte] = []
        finalDelimiter.reserveCapacity(delimiter.count + 2)
        finalDelimiter.append(contentsOf: delimiter)
        finalDelimiter.append(ASCII.Code.hyphen)
        finalDelimiter.append(ASCII.Code.hyphen)

        var parts: [RFC_2046.BodyPart] = []
        var preambleBytes: [Byte]?
        var epilogueBytes: [Byte]?

        var preambleLines: [[Byte]] = []
        var inPreamble = true
        var inPart = false
        var partHeaderLines: [[Byte]] = []
        var partContentLines: [[Byte]] = []
        var inHeaders = true

        let crlf: [Byte] = [ASCII.Code.cr.byte, ASCII.Code.lf.byte]

        for lineSlice in RFC_2046.lines(of: Array(bytes)) {
            if lineSlice.elementsEqual(delimiter) {
                // Start of new part
                if inPart {
                    // Save previous part using efficient joined()
                    let headerBytes = Array<Byte>(partHeaderLines.joined(separator: crlf))
                    let contentBytes = Array<Byte>(partContentLines.joined(separator: crlf))
                    let headers: RFC_2046.BodyPart.Headers
                    do {
                        headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
                    } catch {
                        throw Error.invalidBodyPart("Headers: \(error)")
                    }
                    parts.append(
                        RFC_2046.BodyPart(
                            headers: headers,
                            content: RFC_2046.BodyPart.Content(contentBytes)
                        )
                    )
                }
                if inPreamble {
                    preambleBytes =
                        preambleLines.isEmpty ? nil : Array(preambleLines.joined(separator: crlf))
                    inPreamble = false
                }
                inPart = true
                inHeaders = true
                partHeaderLines = []
                partContentLines = []
            } else if lineSlice.elementsEqual(finalDelimiter) {
                // End of multipart
                if inPart {
                    let headerBytes = Array<Byte>(partHeaderLines.joined(separator: crlf))
                    let contentBytes = Array<Byte>(partContentLines.joined(separator: crlf))
                    let headers: RFC_2046.BodyPart.Headers
                    do {
                        headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
                    } catch {
                        throw Error.invalidBodyPart("Headers: \(error)")
                    }
                    parts.append(
                        RFC_2046.BodyPart(
                            headers: headers,
                            content: RFC_2046.BodyPart.Content(contentBytes)
                        )
                    )
                }
                inPart = false
            } else if inPart {
                if inHeaders {
                    if lineSlice.isEmpty {
                        // Empty line ends headers, starts content
                        inHeaders = false
                    } else {
                        partHeaderLines.append(Array(lineSlice))
                    }
                } else {
                    partContentLines.append(Array(lineSlice))
                }
            } else if inPreamble {
                preambleLines.append(Array(lineSlice))
            } else {
                // Epilogue - use separate appends to avoid intermediate allocations
                if epilogueBytes == nil {
                    epilogueBytes = Array(lineSlice)
                } else {
                    epilogueBytes!.append(contentsOf: crlf)
                    epilogueBytes!.append(contentsOf: lineSlice)
                }
            }
        }

        try self.init(
            subtype: context.subtype,
            parts: parts,
            boundary: context.boundary,
            preamble: preambleBytes.map { String(decoding: $0, as: UTF8.self) },
            epilogue: epilogueBytes.map { String(decoding: $0, as: UTF8.self) }
        )
    }
}
