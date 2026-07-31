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

// RFC_2046.BodyPart.Headers.Error.swift
// swift-rfc-2046

extension RFC_2046.BodyPart.Headers {
    /// Errors for body part header parsing
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Header line is malformed (missing colon separator)
        case invalidHeaderLine(_ line: String)

        /// Header name is empty
        case emptyHeaderName
    }
}

// MARK: - CustomStringConvertible

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
