extension RFC_2046.BodyPart.Headers {

    public enum Error: Swift.Error, Sendable, Equatable {

        case invalidHeaderLine(_ line: String)

        case emptyHeaderName
    }
}

extension RFC_2046.BodyPart.Headers.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidHeaderLine(let line):
            return "Invalid header line (missing ':'): '\(line)'"

        case .emptyHeaderName:
            return "Header name cannot be empty"
        }
    }
}
