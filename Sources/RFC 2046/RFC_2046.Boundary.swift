public import ASCII_Serializer
public import Binary_Serializable
import INCITS_4_1986
public import Parseable_ASCII

private typealias Code = ASCII.Code

extension RFC_2046 {

    public struct Boundary: Sendable, Codable {

        public let rawValue: String

        public init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

extension RFC_2046.Boundary {

    package enum Limits {}
}

extension RFC_2046.Boundary.Limits {

    static let maxLength = 70
}

extension RFC_2046.Boundary {

    @inline(always)
    static func isValidBoundaryCharacter(_ code: ASCII.Code) -> Bool {
        code.isAlphanumeric
            || code == Code.apostrophe
            || code == Code.leftParenthesis
            || code == Code.rightParenthesis
            || code == Code.plusSign
            || code == Code.underline
            || code == Code.comma
            || code == Code.hyphen
            || code == Code.period
            || code == Code.solidus
            || code == Code.colon
            || code == Code.equalsSign
            || code == Code.questionMark
            || code == Code.space
    }
}

extension RFC_2046.Boundary: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ boundary: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in boundary.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ boundary: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        for byte in boundary.rawValue.utf8 { buffer.append(Byte(byte)) }
    }
}

extension RFC_2046.Boundary: Swift.RawRepresentable {

    public init?(rawValue: String) {
        do throws(RFC_2046.Boundary.Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_2046.Boundary: CustomStringConvertible {

    public var description: String { rawValue }
}

extension RFC_2046.Boundary: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        guard bytes.count <= Limits.maxLength else {
            throw Error.tooLong(bytes.count)
        }

        let codes: [ASCII.Code]
        do {
            codes = try [ASCII.Code](bytes)
        } catch {
            throw Error.notASCII(String(decoding: bytes, as: UTF8.self))
        }
        var lastCode: ASCII.Code = 0

        for code in codes {
            lastCode = code

            guard Self.isValidBoundaryCharacter(code) else {
                let string = String(decoding: bytes, as: UTF8.self)
                throw Error.invalidCharacter(
                    string,
                    code: code,
                    reason: "Only alphanumerics and '()+_,-./:=? are allowed"
                )
            }
        }

        if lastCode == Code.space {
            let string = String(decoding: bytes, as: UTF8.self)
            throw Error.endsWithWhitespace(string)
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

extension [Byte] {

    public init(_ boundary: RFC_2046.Boundary) {
        self = []
        RFC_2046.Boundary.serialize(boundary, into: &self)
    }
}

extension RFC_2046.Boundary: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue == rhs
    }
}
