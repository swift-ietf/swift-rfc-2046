public import Binary_Serializable
import INCITS_4_1986
import RFC_2045
import RFC_4648

extension RFC_2046.BodyPart {

    public struct Content: Hashable, Sendable, Codable {

        public let rawValue: [Byte]

        public init(_ bytes: [Byte]) {
            self.rawValue = bytes
        }
    }
}

extension RFC_2046.BodyPart.Content: Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ content: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: content.rawValue)
    }
}

extension RFC_2046.BodyPart.Content {

    public init<Bytes: Swift.Collection>(binary bytes: Bytes) where Bytes.Element == Byte {
        self.init([Byte](bytes))
    }

    public init(_ string: some StringProtocol) {
        self.init([Byte](string.utf8))
    }
}

extension RFC_2046.BodyPart.Content {

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

            return bytes
        }
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

extension [Byte] {

    init(_ content: RFC_2046.BodyPart.Content) {
        self = []
        RFC_2046.BodyPart.Content.serialize(content, into: &self)
    }
}
