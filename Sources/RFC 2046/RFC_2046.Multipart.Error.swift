// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-rfc-2046 open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// RFC_2046.Multipart.Error.swift
// swift-rfc-2046

public extension RFC_2046.Multipart {
    /// Errors that can occur when working with multipart messages
    ///
    /// ## RFC 2046 Section 5.1
    ///
    /// Multipart messages have specific structural requirements.
    /// These errors indicate violations of RFC 2046 multipart rules.
    enum Error: Swift.Error, Sendable, Equatable {
        /// Multipart message has no body parts
        ///
        /// Per RFC 2046 Section 5.1, a multipart entity must have at least one body part.
        case emptyParts

        /// Invalid format during parsing
        case invalidFormat(_ reason: String)

        /// Missing required boundary parameter
        case missingBoundary

        /// Invalid subtype value
        case invalidSubtype(_ value: String)

        /// Invalid body part during parsing
        case invalidBodyPart(_ reason: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_2046.Multipart.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyParts:
            return "Multipart message must contain at least one body part"
        case let .invalidFormat(reason):
            return "Invalid multipart format: \(reason)"
        case .missingBoundary:
            return "Multipart Content-Type requires boundary parameter"
        case let .invalidSubtype(value):
            return "Invalid multipart subtype: '\(value)'"
        case let .invalidBodyPart(reason):
            return "Invalid body part: \(reason)"
        }
    }
}
