//
//  File.swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

extension RFC_2046.Multipart {
    /// Errors that can occur when working with multipart messages
    public enum Error: Swift.Error, Hashable, Sendable {
        case invalidBoundary(String)
        case boundaryTooLong(String, length: Int)
        case missingBoundary
        case emptyParts
        case invalidSubtype(String)
    }
}
