extension RFC_2046.Multipart {

    public enum Error: Swift.Error, Sendable, Equatable, Hashable {

        case emptyParts

        case invalidFormat(_ reason: String)

        case missingBoundary

        case invalidSubtype(_ value: String)

        case invalidBodyPart(_ reason: String)

        case invalidParameterValue(name: String, value: String)
    }
}

extension RFC_2046.Multipart.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyParts:
            return "Multipart message must contain at least one body part"

        case .invalidFormat(let reason):
            return "Invalid multipart format: \(reason)"

        case .missingBoundary:
            return "Multipart Content-Type requires boundary parameter"

        case .invalidSubtype(let value):
            return "Invalid multipart subtype: '\(value)'"

        case .invalidBodyPart(let reason):
            return "Invalid body part: \(reason)"

        case .invalidParameterValue(let name, let value):
            return "Invalid Content-Type parameter value for '\(name)': '\(value)'"
        }
    }
}
