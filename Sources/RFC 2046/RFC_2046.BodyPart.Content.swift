import INCITS_4_1986

extension RFC_2046.BodyPart {
    /// Type-safe content for a body part
    ///
    /// Wraps raw bytes with proper serialization semantics.
    ///
    /// Use `String(content)` to get text representation.
    /// Use `Content(ascii: bytes)` to create from bytes.
    public struct Content: Hashable, Sendable, Codable {
        /// Canonical storage: raw bytes
        public let rawValue: [Byte]

        public init(_ bytes: [Byte]) {
            self.rawValue = bytes
        }
    }
}
//
// extension RFC_2046.BodyPart.Content {
//    public var isEmpty: Bool { rawValue.isEmpty }
//    public var count: Int { rawValue.count }
// }

// MARK: - Binary.ASCII.Serializable

extension RFC_2046.BodyPart.Content: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii content: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: content.rawValue)
    }

    public init<Bytes: Collection>(
        ascii bytes: Bytes,
        in context: Void = ()
    ) throws(Never)
    where Bytes.Element == Byte {
        self.init(Array(bytes))
    }
}

extension [Byte] {
    /// Creates bytes from BodyPart.Content
    init(_ content: RFC_2046.BodyPart.Content) {
        self = []
        RFC_2046.BodyPart.Content.serialize(ascii: content, into: &self)
    }
}

extension RFC_2046.BodyPart.Content: Binary.ASCII.RawRepresentable {}
extension RFC_2046.BodyPart.Content: CustomStringConvertible {}
