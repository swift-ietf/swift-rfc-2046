import Byte
import INCITS_4_1986

private typealias Code = ASCII.Code

extension RFC_2046 {

    public struct Boundary: Sendable {

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

extension RFC_2046.Boundary {

    public init(_ string: some StringProtocol) throws(Error) {
        let value = String(string)
        let bytes: [Byte] = value.utf8.map(Byte.init(bitPattern:))

        guard !bytes.isEmpty else {
            throw Error.empty
        }

        guard bytes.count <= Limits.maxLength else {
            throw Error.tooLong(bytes.count)
        }

        let codes: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            var built: [ASCII.Code] = []
            built.reserveCapacity(bytes.count)
            for byte in bytes {
                built.append(try ASCII.Code(byte))
            }
            codes = built
        } catch {
            throw Error.notASCII(value)
        }

        var lastCode: ASCII.Code = 0

        for code in codes {
            lastCode = code

            guard Self.isValidBoundaryCharacter(code) else {
                throw Error.invalidCharacter(
                    value,
                    code: code,
                    reason: "Only alphanumerics and '()+_,-./:=? are allowed"
                )
            }
        }

        if lastCode == Code.space {
            throw Error.endsWithWhitespace(value)
        }

        self.init(__unchecked: (), rawValue: value)
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
