extension RFC_2046.Multipart.Subtype {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty
    }
}

extension RFC_2046.Multipart.Subtype.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Multipart subtype cannot be empty"
        }
    }
}
