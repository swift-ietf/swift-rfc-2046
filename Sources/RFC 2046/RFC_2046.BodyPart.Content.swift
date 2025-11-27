import INCITS_4_1986

public extension RFC_2046.BodyPart {
    /// Type-safe content for a body part
    ///
    /// Wraps raw bytes with proper serialization semantics.
    ///
    /// Use `String(content)` to get text representation.
    /// Use `Content(ascii: bytes)` to create from bytes.
    struct Content: Hashable, Sendable, Codable {
        /// Canonical storage: raw bytes
        public let rawValue: [UInt8]

        public init(_ bytes: [UInt8]) {
            self.rawValue = bytes
        }
    }
}
//
//extension RFC_2046.BodyPart.Content {
//    public var isEmpty: Bool { rawValue.isEmpty }
//    public var count: Int { rawValue.count }
//}


// MARK: - UInt8.ASCII.Serializable

extension RFC_2046.BodyPart.Content: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws
    where Bytes.Element == UInt8 {
        self.init(Array(bytes))
    }
}

public extension [UInt8] {
    /// Creates bytes from BodyPart.Content
    init(_ content: RFC_2046.BodyPart.Content) {
        self = content.rawValue
    }
}

extension RFC_2046.BodyPart.Content: UInt8.ASCII.RawRepresentable {}
extension RFC_2046.BodyPart.Content: CustomStringConvertible {}
