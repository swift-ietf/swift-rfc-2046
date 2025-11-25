import INCITS_4_1986
public import RFC_2045
import RFC_4648
import RFC_5322

public extension RFC_2046 {
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
    struct Multipart: Hashable, Sendable, Codable {
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
        init(
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

// MARK: - Convenience Initializers

public extension RFC_2046.Multipart {
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
    init(
        subtype: Subtype,
        parts: [RFC_2046.BodyPart],
        boundary: String,
        preamble: String? = nil,
        epilogue: String? = nil,
        additionalParameters: [RFC_2045.Parameter.Name: String] = [:]
    ) throws {
        try self.init(
            subtype: subtype,
            parts: parts,
            boundary: RFC_2046.Boundary(boundary),
            preamble: preamble,
            epilogue: epilogue,
            additionalParameters: additionalParameters
        )
    }
}

// MARK: - Computed Properties

public extension RFC_2046.Multipart {
    /// The Content-Type for this multipart message
    ///
    /// Includes boundary parameter and any additional parameters.
    var contentType: RFC_2045.ContentType {
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

public extension RFC_2046.Multipart {
    /// Parsing context for multipart messages
    ///
    /// Multipart data requires the boundary delimiter to identify parts.
    /// The subtype defaults to `.mixed` if not specified.
    ///
    /// ## Category Theory
    ///
    /// Context-dependent parsing: `(Context, [UInt8]) → Multipart`
    ///
    /// The same raw bytes can represent different multipart structures
    /// depending on the boundary delimiter in the context.
    struct Context: Sendable {
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

// MARK: - UInt8.ASCII.Serializing Conformance

extension RFC_2046.Multipart: UInt8.ASCII.Serializing {
    /// Serialize to canonical ASCII byte representation
    ///
    /// Serialization is always context-free because the Multipart value
    /// contains its own boundary delimiter.
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses multipart data from bytes with context (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// Multipart parsing requires context (boundary delimiter) to identify parts.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: (Context, [UInt8]) where Context provides boundary
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
    where Bytes.Element == UInt8 {
        // Build boundary delimiters as bytes
        let boundaryBytes = [UInt8](context.boundary)
        let delimiterPrefix: [UInt8] = [.ascii.hyphen, .ascii.hyphen]
        let delimiter = delimiterPrefix + boundaryBytes
        let finalDelimiter = delimiter + delimiterPrefix

        var parts: [RFC_2046.BodyPart] = []
        var preambleBytes: [UInt8]?
        var epilogueBytes: [UInt8]?

        // Split into lines (CRLF, CR, or LF for leniency)
        var lines: [[UInt8]] = []
        var currentLine: [UInt8] = []

        var index = bytes.startIndex
        while index < bytes.endIndex {
            let byte = bytes[index]

            if byte == .ascii.cr {
                let next = bytes.index(after: index)
                if next < bytes.endIndex && bytes[next] == .ascii.lf {
                    // CRLF
                    lines.append(currentLine)
                    currentLine = []
                    index = bytes.index(after: next)
                } else {
                    // Just CR
                    lines.append(currentLine)
                    currentLine = []
                    index = next
                }
            } else if byte == .ascii.lf {
                // Just LF
                lines.append(currentLine)
                currentLine = []
                index = bytes.index(after: index)
            } else {
                currentLine.append(byte)
                index = bytes.index(after: index)
            }
        }
        // Add final line
        lines.append(currentLine)

        var preambleLines: [[UInt8]] = []
        var inPreamble = true
        var inPart = false
        var partHeaderLines: [[UInt8]] = []
        var partContentLines: [[UInt8]] = []
        var inHeaders = true

        let crlf: [UInt8] = .ascii.crlf

        for line in lines {
            if line == delimiter {
                // Start of new part
                if inPart {
                    // Save previous part
                    let headerBytes = Array(partHeaderLines.joined(separator: crlf))
                    let contentBytes = Array(partContentLines.joined(separator: crlf))
                    let headers: RFC_2046.BodyPart.Headers
                    do {
                        headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
                    } catch {
                        throw Error.invalidBodyPart("Headers: \(error)")
                    }
                    parts.append(RFC_2046.BodyPart(headers: headers, content: contentBytes))
                }
                if inPreamble {
                    preambleBytes = preambleLines.isEmpty ? nil : Array(preambleLines.joined(separator: crlf))
                    inPreamble = false
                }
                inPart = true
                inHeaders = true
                partHeaderLines = []
                partContentLines = []
            } else if line == finalDelimiter {
                // End of multipart
                if inPart {
                    let headerBytes = Array(partHeaderLines.joined(separator: crlf))
                    let contentBytes = Array(partContentLines.joined(separator: crlf))
                    let headers: RFC_2046.BodyPart.Headers
                    do {
                        headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
                    } catch {
                        throw Error.invalidBodyPart("Headers: \(error)")
                    }
                    parts.append(RFC_2046.BodyPart(headers: headers, content: contentBytes))
                }
                inPart = false
            } else if inPart {
                if inHeaders {
                    if line.isEmpty {
                        // Empty line ends headers, starts content
                        inHeaders = false
                    } else {
                        partHeaderLines.append(line)
                    }
                } else {
                    partContentLines.append(line)
                }
            } else if inPreamble {
                preambleLines.append(line)
            } else {
                // Epilogue
                if epilogueBytes == nil {
                    epilogueBytes = line
                } else {
                    epilogueBytes! += crlf + line
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
