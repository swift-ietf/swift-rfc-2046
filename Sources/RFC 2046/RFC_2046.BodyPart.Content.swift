public import Byte
import Byte

extension RFC_2046.BodyPart {

    public struct Content: Hashable, Sendable {

        public let rawValue: [Byte]

        public init(_ bytes: [Byte]) {
            self.rawValue = bytes
        }
    }
}

extension RFC_2046.BodyPart.Content {

    public init<Bytes: Swift.Collection>(binary bytes: Bytes) where Bytes.Element == Byte {
        self.init([Byte](bytes))
    }

    public init(_ string: some StringProtocol) {
        self.init(string.utf8.map(Byte.init(bitPattern:)))
    }
}

extension RFC_2046.BodyPart.Content: Swift.RawRepresentable {

    public init?(rawValue: [Byte]) {
        self.init(rawValue)
    }
}

extension RFC_2046.BodyPart.Content: CustomStringConvertible {

    public var description: String {
        String(decoding: rawValue, as: UTF8.self)
    }
}
