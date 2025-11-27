import INCITS_4_1986
import RFC_4648
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

        /// Content of this body part
        public let content: Content

        /// Creates a body part with typed headers and content
        ///
        /// - Parameters:
        ///   - headers: Type-safe MIME headers for this part
        ///   - content: The body content
        public init(headers: Headers, content: Content) {
            self.headers = headers
            self.content = content
        }
    }
}

// MARK: - UInt8.ASCII.Serializable

extension RFC_2046.BodyPart: UInt8.ASCII.Serializable {
    /// Serialize to canonical byte representation
    public static let serialize: @Sendable (Self) -> [UInt8] = { [UInt8]($0) }

    /// Parses a body part from bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// Parses headers up to the first blank line, then treats remaining
    /// bytes as content.
    ///
    /// ## Format
    ///
    /// ```
    /// Header-Name: Header-Value CRLF
    /// Another-Header: Value CRLF
    /// CRLF
    /// content bytes...
    /// ```
    ///
    /// ## Performance
    ///
    /// - Uses efficient byte sequence search
    /// - Single pass through input bytes
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("Content-Type: text/plain\r\n\r\nHello!".utf8)
    /// let part = try RFC_2046.BodyPart(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The body part bytes (headers + blank line + content)
    /// - Throws: `RFC_2046.BodyPart.Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        let byteArray = Array(bytes)

        // Find the blank line separating headers from content
        // Look for CRLF CRLF or LF LF
        let crlf: [UInt8] = .ascii.crlf
        var doubleCrlf: [UInt8] = []
        doubleCrlf.reserveCapacity(4)
        doubleCrlf.append(contentsOf: crlf)
        doubleCrlf.append(contentsOf: crlf)

        let doubleLf: [UInt8] = [.ascii.lf, .ascii.lf]

        var headerEndIndex: Int?
        var contentStartIndex: Int?

        // Try CRLF CRLF first (standard)
        if let idx = byteArray.firstIndex(of: doubleCrlf) {
            headerEndIndex = idx
            contentStartIndex = idx + doubleCrlf.count
        }
        // Fall back to LF LF (lenient)
        else if let idx = byteArray.firstIndex(of: doubleLf) {
            headerEndIndex = idx
            contentStartIndex = idx + doubleLf.count
        }

        guard let headerEnd = headerEndIndex, let contentStart = contentStartIndex else {
            // No blank line found - treat as headers only with empty content
            let headerBytes = byteArray
            let headers: Headers
            do {
                headers = try Headers(ascii: headerBytes)
            } catch {
                throw Error.invalidHeaders("\(error)")
            }
            self.init(headers: headers, content: Content([]))
            return
        }

        // Parse headers
        let headerBytes = Array(byteArray[..<headerEnd])
        let headers: Headers
        do {
            headers = try Headers(ascii: headerBytes)
        } catch {
            throw Error.invalidHeaders("\(error)")
        }

        // Extract content
        let contentBytes: [UInt8]
        if contentStart < byteArray.count {
            contentBytes = Array(byteArray[contentStart...])
        } else {
            contentBytes = []
        }

        self.init(headers: headers, content: Content(contentBytes))
    }
}

extension [UInt8] {
    /// Creates bytes from RFC 2046 BodyPart (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// Serializes headers and content. Note: This does NOT include
    /// boundary delimiters - use Multipart serialization for complete messages.
    ///
    /// Applies Content-Transfer-Encoding if specified in headers:
    /// - base64: Encodes content as base64
    /// - quoted-printable: Uses raw content (not yet implemented)
    /// - 7bit/8bit/binary: Uses raw content
    ///
    /// ## Category Theory
    ///
    /// Serialization (natural transformation):
    /// - **Domain**: RFC_2046.BodyPart (structured data)
    /// - **Codomain**: [UInt8] (bytes)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let part = RFC_2046.BodyPart(
    ///     contentType: .textPlainUTF8,
    ///     text: "Hello!"
    /// )
    /// let bytes = [UInt8](part)
    /// ```
    ///
    /// - Parameter bodyPart: The body part to serialize
    public init(_ bodyPart: RFC_2046.BodyPart) {
        self = []

        let contentBytes = [UInt8](bodyPart.content)

        // Estimate capacity: headers (~200) + CRLF (2) + content
        reserveCapacity(200 + 2 + contentBytes.count)

        let crlf: [UInt8] = .ascii.crlf

        // Headers (byte-based)
        self.append(contentsOf: [UInt8](bodyPart.headers))

        // Blank line
        self.append(contentsOf: crlf)

        // Content with encoding applied
        if let encoding = bodyPart.transferEncoding {
            switch encoding {
            case .base64:
                self.append(contentsOf: RFC_4648.Base64.encode(contentBytes))
            case .quotedPrintable:
                // Quoted-printable encoding not yet implemented; use raw content
                self.append(contentsOf: contentBytes)
            default:
                // 7bit, 8bit, binary: use raw content
                self.append(contentsOf: contentBytes)
            }
        } else {
            // No encoding specified: use raw content
            self.append(contentsOf: contentBytes)
        }
    }
}

//// MARK: - Convenience Initializers
//
// extension RFC_2046.BodyPart {
//    /// Creates a body part with Content-Type and content
//    ///
//    /// - Parameters:
//    ///   - contentType: Content-Type for this part
//    ///   - transferEncoding: Optional transfer encoding
//    ///   - additionalHeaders: Additional custom headers
//    ///   - content: The body content
//    public init(
//        contentType: RFC_2045.ContentType,
//        transferEncoding: RFC_2045.ContentTransferEncoding? = nil,
//        additionalHeaders: [RFC_5322.Header] = [],
//        content: Content
//    ) {
//        headers = Headers(
//            contentType: contentType,
//            contentTransferEncoding: transferEncoding,
//            custom: additionalHeaders
//        )
//        self.content = content
//    }
//
//    /// Creates a body part with Content-Type and text content
//    ///
//    /// Convenience initializer for text content.
//    ///
//    /// - Parameters:
//    ///   - contentType: Content-Type for this part
//    ///   - transferEncoding: Optional transfer encoding
//    ///   - additionalHeaders: Additional custom headers
//    ///   - text: The text content
//    public init(
//        contentType: RFC_2045.ContentType,
//        transferEncoding: RFC_2045.ContentTransferEncoding? = nil,
//        additionalHeaders: [RFC_5322.Header] = [],
//        text: String
//    ) {
//        self.init(
//            contentType: contentType,
//            transferEncoding: transferEncoding,
//            additionalHeaders: additionalHeaders,
//            content: Content(text)
//        )
//    }
//
//    /// Creates a body part with typed headers and text content
//    ///
//    /// Convenience initializer for text content.
//    ///
//    /// - Parameters:
//    ///   - headers: Type-safe MIME headers for this part
//    ///   - text: The text content
//    public init(headers: Headers, text: String) {
//        self.init(headers: headers, content: Content(text))
//    }
// }

// MARK: - Convenience Initializers

extension RFC_2046.BodyPart {
    /// Creates a text body part with the specified content type
    ///
    /// Convenience initializer for text-based body parts.
    /// Automatically sets `Content-Transfer-Encoding: 8bit` for UTF-8 text.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let htmlPart = try RFC_2046.BodyPart(
    ///     contentType: .textHTMLUTF8,
    ///     text: "<h1>Hello</h1>"
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - contentType: Content type for the text (e.g., `.textPlainUTF8`, `.textHTMLUTF8`)
    ///   - text: The text content
    /// - Throws: If header or content creation fails
    public init(
        contentType: RFC_2045.ContentType,
        text: some StringProtocol
    ) throws {
        var headers = try Headers(ascii: [])
        headers.contentType = contentType
        // UTF-8 text may contain bytes > 127, use 8bit encoding
        headers.contentTransferEncoding = .eightBit

        self.init(
            headers: headers,
            content: try Content(text)
        )
    }
}

// MARK: - Computed Properties

extension RFC_2046.BodyPart {
    /// The Content-Type of this part, if specified
    public var contentType: RFC_2045.ContentType? {
        headers.contentType
    }

    /// The Content-Transfer-Encoding of this part, if specified
    public var transferEncoding: RFC_2045.ContentTransferEncoding? {
        headers.contentTransferEncoding
    }
}
