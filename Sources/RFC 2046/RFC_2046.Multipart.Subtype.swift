public import ASCII_Serializer
public import Binary_Serializable
import INCITS_4_1986
public import Parseable_ASCII

extension RFC_2046.Multipart {

    public struct Subtype: Sendable, Codable {
        public let rawValue: String

        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

extension RFC_2046.Multipart.Subtype: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ subtype: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in subtype.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ subtype: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        for byte in subtype.rawValue.utf8 { buffer.append(Byte(byte)) }
    }
}

extension RFC_2046.Multipart.Subtype: Swift.RawRepresentable {

    public init?(rawValue: String) {
        do throws(RFC_2046.Multipart.Subtype.Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_2046.Multipart.Subtype: CustomStringConvertible {

    public var description: String { rawValue }
}

extension RFC_2046.Multipart.Subtype: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        self.init(
            __unchecked: (),
            rawValue: String(decoding: bytes, as: UTF8.self).lowercased()
        )
    }
}

extension [Byte] {

    public init(_ subtype: RFC_2046.Multipart.Subtype) {
        self = []
        RFC_2046.Multipart.Subtype.serialize(subtype, into: &self)
    }
}

extension RFC_2046.Multipart.Subtype: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue == rhs.lowercased()
    }
}

extension RFC_2046.Multipart.Subtype {

    public static let mixed = Self(__unchecked: (), rawValue: "mixed")

    public static let alternative = Self(__unchecked: (), rawValue: "alternative")

    public static let digest = Self(__unchecked: (), rawValue: "digest")

    public static let parallel = Self(__unchecked: (), rawValue: "parallel")
}

extension RFC_2046.Multipart.Subtype {

    public static let related = Self(__unchecked: (), rawValue: "related")

    public static let formData = Self(__unchecked: (), rawValue: "form-data")

    public static let byteranges = Self(__unchecked: (), rawValue: "byteranges")

    public static let signed = Self(__unchecked: (), rawValue: "signed")

    public static let encrypted = Self(__unchecked: (), rawValue: "encrypted")

    public static let report = Self(__unchecked: (), rawValue: "report")
}
