public import Binary_Serializable_Primitives
import INCITS_4_1986
import RFC_2045
import RFC_4648

extension RFC_2046.BodyPart {
    /// Type-safe content for a body part
    ///
    /// Wraps raw bytes with proper serialization semantics.
    ///
    /// Use `String(decoding:as:)` or `description` to get a text representation.
    /// Use `Content(binary: bytes)` to create from bytes.
    ///
    /// ## [FAM-012] classification — Binary-only (clause-2)
    ///
    /// Body-part content is genuinely byte-domain: it may carry binary or
    /// MIME-transfer-encoded payloads (images, octet-streams, …) that have NO
    /// ASCII-text form. It therefore conforms to `Binary.Serializable` ONLY —
    /// there is no `ASCII.Serializable` sibling. The byte-domain parse entry is
    /// the free `init(binary:)`. (Mirrors `RFC_2822.Message.Body`.)
    public struct Content: Hashable, Sendable, Codable {
        /// Canonical storage: raw bytes
        public let rawValue: [Byte]

        public init(_ bytes: [Byte]) {
            self.rawValue = bytes
        }
    }
}

// MARK: - Binary.Serializable ([FAM-012] — Content is byte-domain, Binary-only)

extension RFC_2046.BodyPart.Content: Binary.Serializable {
    /// Serializes the content as its raw wire bytes.
    ///
    /// [FAM-012] Content is byte-domain (binary / MIME-encoded payloads), so it
    /// conforms to `Binary.Serializable` ONLY — arbitrary bytes have no ASCII form.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ content: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: content.rawValue)
    }
}

// MARK: - Byte-domain parse + String convenience ([FAM-012] free-standing inits)

extension RFC_2046.BodyPart.Content {
    /// Creates content from raw wire bytes — the byte-domain parse entry.
    ///
    /// No validation: a body-part payload is an arbitrary sequence of bytes
    /// (hence non-throwing).
    public init<Bytes: Collection>(binary bytes: Bytes) where Bytes.Element == Byte {
        self.init([Byte](bytes))
    }

    /// Creates content from a string's UTF-8 bytes.
    public init(_ string: some StringProtocol) {
        self.init([Byte](string.utf8))
    }
}

// MARK: - Content-Transfer-Encoding decoding (F-001)

extension RFC_2046.BodyPart.Content {
    /// Decodes wire content bytes into canonical (decoded) content bytes per
    /// the part's Content-Transfer-Encoding.
    ///
    /// F-001 — `Content` canonically stores DECODED bytes: serialization
    /// applies the transfer encoding, so parse paths must invert it or the
    /// domain is asymmetric and reparse-then-serialize double-encodes.
    ///
    /// - Returns: The decoded bytes, or `nil` if the wire content is not valid
    ///   for the declared encoding.
    static func decoding(
        _ bytes: [Byte],
        transferEncoding: RFC_2045.ContentTransferEncoding?
    ) -> [Byte]? {
        switch transferEncoding {
        case .base64:
            var codes: [ASCII.Code] = []
            codes.reserveCapacity(bytes.count)
            for byte in bytes {
                guard byte.underlying < 0x80 else { return nil }
                codes.append(ASCII.Code(unchecked: byte))
            }
            return RFC_4648.Base64.decode(codes)
        case .quotedPrintable:
            return RFC_2046.QuotedPrintable.decode(bytes)
        default:
            // 7bit / 8bit / binary / absent: identity.
            return bytes
        }
    }
}

// MARK: - RawRepresentable / CustomStringConvertible

extension RFC_2046.BodyPart.Content: Swift.RawRepresentable {
    /// Creates content from raw `rawValue` bytes.
    ///
    /// Re-provides `Swift.RawRepresentable` directly — the retired combined
    /// ASCII/binary RawRepresentable tier no longer synthesizes it. (Load-bearing:
    /// the `RawRepresentable`+`Codable` pair synthesizes the single-value JSON
    /// form.)
    public init?(rawValue: [Byte]) {
        self.init(rawValue)
    }
}

extension RFC_2046.BodyPart.Content: CustomStringConvertible {
    /// The content decoded as UTF-8 text (lossy for non-UTF-8 byte content).
    public var description: String {
        String(decoding: rawValue, as: UTF8.self)
    }
}

extension [Byte] {
    /// Creates wire bytes from a `BodyPart.Content` via its `Binary.Serializable` verb.
    init(_ content: RFC_2046.BodyPart.Content) {
        self = []
        RFC_2046.BodyPart.Content.serialize(content, into: &self)
    }
}
