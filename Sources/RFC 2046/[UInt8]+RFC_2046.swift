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

// [UInt8]+RFC_2046.swift
// swift-rfc-2046
//
// Canonical byte serialization for RFC 2046 types

import INCITS_4_1986
import RFC_2045
import RFC_2183
import RFC_4648
import RFC_5322

// MARK: - Boundary Serialization

// MARK: - Subtype Serialization

// MARK: - Headers Serialization

// MARK: - Multipart Serialization

public extension [UInt8] {
    /// Creates ASCII bytes from RFC 2046 Multipart message
    ///
    /// Serializes the complete multipart body including boundaries,
    /// preamble, parts, and epilogue as raw bytes.
    ///
    /// ## Category Theory
    ///
    /// Serialization (natural transformation):
    /// - **Domain**: RFC_2046.Multipart (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes with embedded binary)
    ///
    /// ## RFC 2046 Format
    ///
    /// ```
    /// [preamble CRLF]
    /// --boundary CRLF
    /// headers CRLF
    /// CRLF
    /// content
    /// --boundary CRLF
    /// ...
    /// --boundary-- CRLF
    /// [epilogue]
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let multipart = try RFC_2046.Multipart(
    ///     subtype: .alternative,
    ///     parts: [textPart, htmlPart],
    ///     boundary: "----=_Part_12345"
    /// )
    /// let bytes = [UInt8](multipart)
    /// ```
    ///
    /// - Parameter multipart: The multipart message to serialize
    init(_ multipart: RFC_2046.Multipart) {
        self = []

        // Estimate capacity
        var estimatedSize = 0
        estimatedSize += (multipart.preamble?.utf8.count ?? 0) + 4
        estimatedSize += multipart.parts.count * (multipart.boundary.rawValue.count + 10)
        for part in multipart.parts {
            estimatedSize += part.content.count + 200 // headers estimate
        }
        estimatedSize += (multipart.epilogue?.utf8.count ?? 0) + 4
        self.reserveCapacity(estimatedSize)

        let crlf: [UInt8] = [.ascii.cr, .ascii.lf]
        let boundaryPrefix: [UInt8] = [.ascii.hyphen, .ascii.hyphen]
        let boundaryBytes = [UInt8](multipart.boundary)

        // Preamble (optional)
        if let preamble = multipart.preamble {
            self.append(contentsOf: preamble.utf8)
            self.append(contentsOf: crlf)
            self.append(contentsOf: crlf)
        }

        // Body parts
        for part in multipart.parts {
            // Boundary delimiter
            self.append(contentsOf: boundaryPrefix)
            self.append(contentsOf: boundaryBytes)
            self.append(contentsOf: crlf)

            // Headers (using byte serialization)
            self.append(contentsOf: [UInt8](part.headers))

            // Blank line between headers and content
            self.append(contentsOf: crlf)

            // Content with encoding applied (may be binary)
            self.append(contentsOf: [UInt8](encodedContent: part))
            self.append(contentsOf: crlf)
        }

        // Final boundary
        self.append(contentsOf: boundaryPrefix)
        self.append(contentsOf: boundaryBytes)
        self.append(contentsOf: boundaryPrefix) // "--" suffix for final
        self.append(contentsOf: crlf)

        // Epilogue (optional)
        if let epilogue = multipart.epilogue {
            self.append(contentsOf: epilogue.utf8)
            self.append(contentsOf: crlf)
        }
    }
}

// MARK: - BodyPart Serialization

public extension [UInt8] {
    /// Creates bytes from RFC 2046 BodyPart
    ///
    /// Serializes headers and content. Note: This does NOT include
    /// boundary delimiters - use Multipart serialization for complete messages.
    ///
    /// Applies Content-Transfer-Encoding if specified in headers:
    /// - base64: Encodes content as base64
    /// - quoted-printable: Uses raw content (not yet implemented)
    /// - 7bit/8bit/binary: Uses raw content
    ///
    /// ## Category Theory
    ///
    /// Serialization (natural transformation):
    /// - **Domain**: RFC_2046.BodyPart (structured data)
    /// - **Codomain**: [UInt8] (bytes)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let part = RFC_2046.BodyPart(
    ///     contentType: .textPlainUTF8,
    ///     text: "Hello!"
    /// )
    /// let bytes = [UInt8](part)
    /// ```
    ///
    /// - Parameter bodyPart: The body part to serialize
    init(_ bodyPart: RFC_2046.BodyPart) {
        self = []

        let crlf: [UInt8] = [.ascii.cr, .ascii.lf]

        // Headers (byte-based)
        self.append(contentsOf: [UInt8](bodyPart.headers))

        // Blank line
        self.append(contentsOf: crlf)

        // Content with encoding applied
        self.append(contentsOf: [UInt8](encodedContent: bodyPart))
    }

    /// Creates encoded content bytes from RFC 2046 BodyPart
    ///
    /// Applies Content-Transfer-Encoding to the raw content:
    /// - base64: Encodes content as base64
    /// - quoted-printable: Uses raw content (not yet implemented)
    /// - 7bit/8bit/binary: Uses raw content
    ///
    /// ## Category Theory
    ///
    /// Encoding transformation:
    /// - **Domain**: RFC_2046.BodyPart.content (raw bytes)
    /// - **Codomain**: [UInt8] (encoded bytes)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let part = RFC_2046.BodyPart(
    ///     contentType: .textPlainUTF8,
    ///     transferEncoding: .base64,
    ///     text: "Hello!"
    /// )
    /// let encodedBytes = [UInt8](encodedContent: part)
    /// ```
    ///
    /// - Parameter bodyPart: The body part whose content to encode
    init(encodedContent bodyPart: RFC_2046.BodyPart) {
        if let encoding = bodyPart.transferEncoding {
            switch encoding {
            case .base64:
                self = RFC_4648.Base64.encode(bodyPart.content)
            case .quotedPrintable:
                // Quoted-printable encoding not yet implemented; use raw content
                self = bodyPart.content
            default:
                // 7bit, 8bit, binary: use raw content
                self = bodyPart.content
            }
        } else {
            // No encoding specified: use raw content
            self = bodyPart.content
        }
    }
}
