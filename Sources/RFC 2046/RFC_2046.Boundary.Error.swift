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

// RFC_2046.Boundary.Error.swift
// swift-rfc-2046

extension RFC_2046.Boundary {
    /// Errors that can occur during boundary validation
    ///
    /// ## RFC 2046 Section 5.1.1
    ///
    /// Boundary delimiters must conform to strict rules:
    /// - Length: 1-70 characters (not counting leading hyphens)
    /// - Cannot end with whitespace
    /// - Limited to robust character set for mail gateway transport
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Boundary is empty
        case empty

        /// Boundary exceeds maximum length of 70 characters
        case tooLong(_ length: Int)

        /// Boundary contains invalid character
        case invalidCharacter(_ value: String, byte: UInt8, reason: String)

        /// Boundary ends with whitespace (forbidden by RFC 2046)
        case endsWithWhitespace(_ value: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_2046.Boundary.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Boundary cannot be empty"
        case .tooLong(let length):
            return
                "Boundary too long (\(length) characters, max \(RFC_2046.Boundary.Limits.maxLength))"
        case .invalidCharacter(let value, let byte, let reason):
            return
                "Invalid byte 0x\(String(byte, radix: 16, uppercase: true)) in boundary '\(value)': \(reason)"
        case .endsWithWhitespace(let value):
            return "Boundary '\(value)' cannot end with whitespace"
        }
    }
}
