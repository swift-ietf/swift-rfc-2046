extension RFC_2046.Boundary {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case tooLong(_ length: Int)

        case invalidCharacter(_ value: String, code: ASCII.Code, reason: String)

        case endsWithWhitespace(_ value: String)

        case notASCII(_ value: String)
    }
}

extension RFC_2046.Boundary.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Boundary cannot be empty"

        case .tooLong(let length):
            return
                "Boundary too long (\(length) characters, max \(RFC_2046.Boundary.Limits.maxLength))"

        case .invalidCharacter(let value, let code, let reason):
            return
                "Invalid byte 0x\(String(code.underlying, radix: 16, uppercase: true)) in boundary '\(value)': \(reason)"

        case .endsWithWhitespace(let value):
            return "Boundary '\(value)' cannot end with whitespace"

        case .notASCII(let value):
            return "Boundary '\(value)' contains a non-ASCII byte"
        }
    }
}
