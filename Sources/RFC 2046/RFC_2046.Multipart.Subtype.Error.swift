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

// RFC_2046.Multipart.Subtype.Error.swift
// swift-rfc-2046

public extension RFC_2046.Multipart.Subtype {
    /// Errors for multipart subtype parsing
    enum Error: Swift.Error, Sendable, Equatable {
        /// Subtype cannot be empty
        case empty
    }
}

// MARK: - CustomStringConvertible

extension RFC_2046.Multipart.Subtype.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Multipart subtype cannot be empty"
        }
    }
}
