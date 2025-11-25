//
//  File.swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 25/11/2025.
//

extension RFC_2046.BodyPart {
    /// Errors for BodyPart operations
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Invalid headers format
        case invalidHeaders(_ reason: String)
    }
}
