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

// RFC_2046.Boundary.swift
// swift-rfc-2046

import INCITS_4_1986

// `Code` aliases ASCII.Code at file scope — avoids the INCITS `[ASCII.Code].ASCII`
// shadow inside the `extension [Byte]` below.
private typealias Code = ASCII.Code

extension RFC_2046 {
    /// A validated multipart boundary delimiter per RFC 2046 Section 5.1.1
    ///
    /// Boundaries separate parts in multipart MIME bodies. This type ensures
    /// boundaries conform to RFC 2046 requirements for robust mail gateway transport.
    ///
    /// ## Constraints
    ///
    /// Per RFC 2046 Section 5.1.1:
    /// - Length: 1-70 characters (not counting the leading "--")
    /// - Character set: Alphanumerics and specific punctuation
    /// - Must not end with whitespace
    ///
    /// ## Example
    ///
    /// ```swift
    /// let boundary = try RFC_2046.Boundary("----=_Part_12345_Custom")
    /// let bytes = [UInt8](boundary)
    /// ```
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2046 Section 5.1.1:
    ///
    /// > The boundary delimiter MUST NOT appear inside any of the encapsulated
    /// > parts, on a line by itself or as the prefix of any line.
    /// >
    /// > The boundary parameter, which consists of 1 to 70 characters from a
    /// > set of characters known to be very robust through mail gateways.
    public struct Boundary: Sendable, Codable {
        /// The validated boundary string
        public let rawValue: String

        /// Creates a boundary WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 2046 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameter rawValue: Pre-validated boundary string
        public init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Limits

extension RFC_2046.Boundary {
    /// RFC 2046 boundary length limits
    package enum Limits {
        /// Maximum boundary length (70 characters per RFC 2046 Section 5.1.1)
        static let maxLength = 70
    }
}

// MARK: - Character Validation

extension RFC_2046.Boundary {
    /// Valid boundary characters per RFC 2046 Section 5.1.1
    ///
    /// ```
    /// bcharsnospace := DIGIT / ALPHA / "'" / "(" / ")" /
    ///                  "+" / "_" / "," / "-" / "." /
    ///                  "/" / ":" / "=" / "?"
    /// ```
    @inline(always)
    static func isValidBoundaryCharacter(_ code: ASCII.Code) -> Bool {
        code.isAlphanumeric
            || code == Code.apostrophe  // '
            || code == Code.leftParenthesis  // (
            || code == Code.rightParenthesis  // )
            || code == Code.plusSign  // +
            || code == Code.underline  // _
            || code == Code.comma  // ,
            || code == Code.hyphen  // -
            || code == Code.period  // .
            || code == Code.solidus  // /
            || code == Code.colon  // :
            || code == Code.equalsSign  // =
            || code == Code.questionMark  // ?
            || code == Code.space  // space (allowed except at end)
    }
}

// MARK: - Binary.ASCII.Serializable

extension RFC_2046.Boundary: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii boundary: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: Array<Byte>(boundary.rawValue.utf8))
    }

    /// Parses a boundary from canonical byte representation
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 2046 boundaries are ASCII-only strings.
    ///
    /// ## RFC 2046 Compliance
    ///
    /// Per RFC 2046 Section 5.1.1:
    /// - Maximum 70 characters
    /// - Must not end with whitespace
    /// - Limited to robust character set
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_2046.Boundary (structured data)
    ///
    /// String parsing is derived composition:
    /// ```
    /// String → [Byte] (UTF-8) → Boundary
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array<Byte>("----=_Part_12345".utf8)
    /// let boundary = try RFC_2046.Boundary(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation
    /// - Throws: `RFC_2046.Boundary.Error` if validation fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        guard bytes.count <= Limits.maxLength else {
            throw Error.tooLong(bytes.count)
        }

        // Type-up: lift to ASCII.Code at the entry boundary so the body
        // operates on ASCII.Code constants directly (RFC 2046 boundary
        // grammar is strict ASCII; non-ASCII bytes are fail-state).
        let codes: [ASCII.Code]
        do {
            codes = try Array<ASCII.Code>(bytes)
        } catch {
            throw Error.notASCII(String(decoding: bytes, as: UTF8.self))
        }
        var lastCode: ASCII.Code = 0

        for code in codes {
            lastCode = code

            guard Self.isValidBoundaryCharacter(code) else {
                let string = String(decoding: bytes, as: UTF8.self)
                throw Error.invalidCharacter(
                    string,
                    code: code,
                    reason: "Only alphanumerics and '()+_,-./:=? are allowed"
                )
            }
        }

        // RFC 2046: boundary must not end with whitespace
        if lastCode == Code.space {
            let string = String(decoding: bytes, as: UTF8.self)
            throw Error.endsWithWhitespace(string)
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

extension [Byte] {
    /// Creates ASCII bytes from RFC 2046 Boundary
    ///
    /// ## Category Theory
    ///
    /// Serialization (natural transformation):
    /// - **Domain**: RFC_2046.Boundary (structured data)
    /// - **Codomain**: [Byte] (ASCII bytes)
    ///
    /// String representation is derived composition:
    /// ```
    /// Boundary → [Byte] (ASCII) → String (UTF-8)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let boundary = try RFC_2046.Boundary("----=_Part_12345")
    /// let bytes = [Byte](boundary)
    /// ```
    ///
    /// - Parameter boundary: The boundary to serialize
    public init(_ boundary: RFC_2046.Boundary) {
        self = []
        RFC_2046.Boundary.serialize(ascii: boundary, into: &self)
    }
}

// MARK: - Protocol Conformances

extension RFC_2046.Boundary: Binary.ASCII.RawRepresentable {}
extension RFC_2046.Boundary: CustomStringConvertible {}

// MARK: - Hashable

extension RFC_2046.Boundary: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue == rhs
    }
}
