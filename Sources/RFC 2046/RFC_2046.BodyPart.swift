public import Binary_Serializable_Primitives
import Byte_Collection_Primitives_Standard_Library_Integration
import INCITS_4_1986
import RFC_4648
import RFC_5322

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

// MARK: - Binary.Serializable ([FAM-012] — BodyPart is byte-domain, Binary-only)

extension RFC_2046.BodyPart: Binary.Serializable {
    /// Serializes the body part (`headers CRLF content`) as wire bytes.
    ///
    /// [FAM-012] BodyPart is byte-domain — its content may be binary / MIME-
    /// transfer-encoded — so it conforms to `Binary.Serializable` ONLY. Clause-9:
    /// composes `Headers`' own `Byte` verb directly, then appends the (optionally
    /// transfer-encoded) content. NOT a text-serialization detour.
    ///
    /// Note: emits headers + blank line + (encoded) content WITHOUT boundary
    /// delimiters — `Multipart` wraps these with its boundaries.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ bodyPart: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        // Headers (clause-9: Headers' own Byte verb)
        RFC_2046.BodyPart.Headers.serialize(bodyPart.headers, into: &buffer)

        // Blank line between headers and content
        buffer.append(ASCII.Code.cr.byte)
        buffer.append(ASCII.Code.lf.byte)

        // Content with Content-Transfer-Encoding applied
        let contentBytes: [Byte] = bodyPart.content.rawValue
        if let encoding = bodyPart.transferEncoding {
            switch encoding {
            case .base64:
                // Base64.encode emits [ASCII.Code]; lift the ASCII codes into the
                // Byte stream (a transfer-ENCODING, not a sub-part codec verb).
                buffer.append(contentsOf: RFC_4648.Base64.encode(contentBytes).map(\.byte))
            case .quotedPrintable:
                // F-002: RFC 2045 §6.7 quoted-printable encoding (interim local
                // codec until swift-rfc-2045 owns it).
                buffer.append(contentsOf: RFC_2046.QuotedPrintable.encode(contentBytes))
            default:
                // 7bit, 8bit, binary: use raw content
                buffer.append(contentsOf: contentBytes)
            }
        } else {
            // No encoding specified: use raw content
            buffer.append(contentsOf: contentBytes)
        }
    }
}

// MARK: - Byte-domain parse ([FAM-012] free-standing init; Binary.Parseable marker seal-last)

extension RFC_2046.BodyPart {
    /// Parses a body part from wire bytes (AUTHORITATIVE IMPLEMENTATION)
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
    /// let bytes = [Byte]("Content-Type: text/plain\r\n\r\nHello!".utf8)
    /// let part = try RFC_2046.BodyPart(binary: bytes)
    /// ```
    ///
    /// - Parameter bytes: The body part bytes (headers + blank line + content)
    /// - Throws: `RFC_2046.BodyPart.Error` if parsing fails
    public init<Bytes: Collection>(binary bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        let byteArray = [Byte](bytes)

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
            do throws(Headers.Error) {
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
        do throws(Headers.Error) {
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

        // F-001: Content canonically stores DECODED bytes — invert the
        // Content-Transfer-Encoding applied by serialization.
        guard
            let decoded = Content.decoding(
                contentBytes,
                transferEncoding: headers.contentTransferEncoding
            )
        else {
            throw Error.invalidTransferEncodedContent(
                "content is not valid \(headers.contentTransferEncoding?.rawValue ?? "raw")"
            )
        }

        self.init(headers: headers, content: Content(decoded))
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
            content: Content(text)
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

// MARK: - [Byte] convenience

extension [Byte] {
    /// Creates wire bytes from a `BodyPart` via its `Binary.Serializable` verb.
    init(_ bodyPart: RFC_2046.BodyPart) {
        self = []
        RFC_2046.BodyPart.serialize(bodyPart, into: &self)
    }
}
