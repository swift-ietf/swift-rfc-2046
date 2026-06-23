import Byte_Collection_Primitives_Standard_Library_Integration
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

// MARK: - Binary.ASCII.Serializable

extension RFC_2046.BodyPart: Binary.ASCII.Serializable {
    /// Serialize to canonical byte representation
    ///
    /// Serializes headers and content. Note: This does NOT include
    /// boundary delimiters - use Multipart serialization for complete messages.
    ///
    /// Applies Content-Transfer-Encoding if specified in headers:
    /// - base64: Encodes content as base64
    /// - quoted-printable: Uses raw content (not yet implemented)
    /// - 7bit/8bit/binary: Uses raw content
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii bodyPart: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        let contentBytes: [Byte] = bodyPart.content.rawValue

        // Headers (byte-based) — RFC_2046.BodyPart.Headers is migrated to Byte.
        RFC_2046.BodyPart.Headers.serialize(ascii: bodyPart.headers, into: &buffer)

        // Blank line
        buffer.append(ASCII.Code.cr)
        buffer.append(ASCII.Code.lf)

        // Content with encoding applied
        if let encoding = bodyPart.transferEncoding {
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
    }

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
    /// let bytes = Array<Byte>("Content-Type: text/plain\r\n\r\nHello!".utf8)
    /// let part = try RFC_2046.BodyPart(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The body part bytes (headers + blank line + content)
    /// - Throws: `RFC_2046.BodyPart.Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == Byte {
        let byteArray = Array<Byte>(bytes)

        // Find the blank line separating headers from content
        // Look for CRLF CRLF or LF LF
        let doubleCrlf: [Byte] = [
            ASCII.Code.cr.byte, ASCII.Code.lf.byte,
            ASCII.Code.cr.byte, ASCII.Code.lf.byte,
        ]
        let doubleLf: [Byte] = [ASCII.Code.lf.byte, ASCII.Code.lf.byte]

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
        let contentBytes: [Byte]
        if contentStart < byteArray.count {
            contentBytes = Array(byteArray[contentStart...])
        } else {
            contentBytes = []
        }

        self.init(headers: headers, content: Content(contentBytes))
    }
}

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
    ) throws(Headers.Error) {
        var headers = try Headers(ascii: [] as [Byte])
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
