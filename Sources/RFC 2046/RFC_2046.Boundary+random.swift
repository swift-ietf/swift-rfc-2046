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

// RFC_2046.Boundary+random.swift
// swift-rfc-2046
//
// Documented extension: generator surface for the `Boundary` type declared in
// RFC_2046.Boundary.swift.

import INCITS_4_1986
import RFC_4648

extension RFC_2046.Boundary {
    /// Generates a random multipart boundary.
    ///
    /// Produces a boundary of the form `----=_Part_{hex}` where `hex` is 32
    /// lowercase hexadecimal characters (16 random bytes, RFC 4648 Section 8
    /// base 16 encoding). The result is 43 characters — within the RFC 2046
    /// Section 5.1.1 limit of 70 — drawn exclusively from `bcharsnospace`,
    /// and therefore never ends with whitespace.
    ///
    /// The value is constructed through the validating initializer, so the
    /// grammar guarantee is checked, not assumed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let boundary = RFC_2046.Boundary.random()
    /// // ----=_Part_a3f5d8b2c1e4f6a7b9d0c2e5f8a1b3d4
    /// ```
    ///
    /// ## RFC References
    ///
    /// - RFC 2046 Section 5.1.1: boundary delimiter grammar and limits
    /// - RFC 4648 Section 8: base 16 (hex) encoding
    public static func random() -> Self {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    /// Generates a random multipart boundary using the given generator.
    ///
    /// See ``random()`` for the produced format. Passing a deterministic
    /// generator yields a reproducible boundary, which is useful for testing.
    ///
    /// - Parameter generator: The random number generator supplying entropy.
    /// - Returns: A validated boundary of the form `----=_Part_{32 hex}`.
    public static func random(
        using generator: inout some RandomNumberGenerator
    ) -> Self {
        var bytes: [Byte] = []
        bytes.reserveCapacity(16)
        for _ in 0..<2 {
            var word = generator.next()
            for _ in 0..<8 {
                bytes.append(Byte(UInt8(truncatingIfNeeded: word)))
                word >>= 8
            }
        }

        let hexCodes: [ASCII.Code] = RFC_4648.Hex.encode(bytes, uppercase: false)
        let hex = String(decoding: hexCodes, as: UTF8.self)

        do {
            return try Self("----=_Part_\(hex)")
        } catch {
            // Unreachable: 43 characters of bcharsnospace, no trailing space.
            fatalError("RFC_2046.Boundary.random() produced an invalid boundary: \(error)")
        }
    }
}
