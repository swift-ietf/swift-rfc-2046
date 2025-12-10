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

// RFC_2046.Multipart.Subtype.swift
// swift-rfc-2046

import INCITS_4_1986

extension RFC_2046.Multipart {
    /// Multipart subtype per RFC 2046 Section 5.1
    ///
    /// Represents the subtype portion of a multipart Content-Type.
    /// RFC 2046 defines several standard subtypes. Unknown subtypes
    /// should be treated as equivalent to "mixed" per RFC 2046 Section 5.1.7.
    ///
    /// ## Case Sensitivity
    ///
    /// Per RFC 2045, media type names are case-insensitive.
    /// This type normalizes to lowercase for consistent comparison.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Using standard subtypes
    /// let multipart = RFC_2046.Multipart(subtype: .alternative, parts: [...])
    ///
    /// // Custom subtype (treated as mixed)
    /// let custom = RFC_2046.Multipart(
    ///     subtype: Subtype(rawValue: "x-custom"),
    ///     parts: [...]
    /// )
    /// ```
    ///
    /// ## RFC References
    ///
    /// - RFC 2046 Section 5.1: MIME Multipart Media Type
    /// - RFC 2387: multipart/related (compound documents)
    /// - RFC 7578: multipart/form-data (HTML forms)
    /// - RFC 2046 Section 5.2.3: multipart/byteranges (HTTP range requests)
    public struct Subtype: Sendable, Codable {
        public let rawValue: String

        /// Creates a subtype WITHOUT validation
        ///
        /// **Warning**: Bypasses normalization.
        /// Only use for static constants with pre-lowercased values.
        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Binary.ASCII.Serializable

extension RFC_2046.Multipart.Subtype: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii subtype: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: subtype.rawValue.utf8)
    }

    /// Parses a subtype from canonical byte representation
    ///
    /// Per RFC 2045, media type names are case-insensitive.
    /// The input is normalized to lowercase.
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2046.Multipart.Subtype (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("alternative".utf8)
    /// let subtype = try RFC_2046.Multipart.Subtype(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation
    /// - Throws: `RFC_2046.Multipart.Subtype.Error` if empty
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        // Normalize to lowercase per RFC 2045
        let lowercased = bytes.ascii.lowercased()
        self.init(__unchecked: (), rawValue: String(decoding: lowercased, as: UTF8.self))
    }
}

extension [UInt8] {
    /// Creates ASCII bytes from RFC 2046 Multipart Subtype
    ///
    /// ## Example
    ///
    /// ```swift
    /// let subtype = RFC_2046.Multipart.Subtype.alternative
    /// let bytes = [UInt8](subtype)
    /// ```
    ///
    /// - Parameter subtype: The subtype to serialize
    public init(_ subtype: RFC_2046.Multipart.Subtype) {
        self = []
        RFC_2046.Multipart.Subtype.serialize(ascii: subtype, into: &self)
    }
}

// MARK: - Protocol Conformances

extension RFC_2046.Multipart.Subtype: Binary.ASCII.RawRepresentable {}
extension RFC_2046.Multipart.Subtype: CustomStringConvertible {}

// MARK: - Hashable

extension RFC_2046.Multipart.Subtype: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue == rhs.lowercased()
    }
}

// MARK: - RFC 2046 Standard Subtypes

extension RFC_2046.Multipart.Subtype {
    /// Independent body parts in specified order
    ///
    /// Used when body parts are independent and should be
    /// presented in sequence. This is the default treatment
    /// for unrecognized subtypes.
    ///
    /// **RFC 2046 Section 5.1.3**
    public static let mixed = Self(__unchecked: (), rawValue: "mixed")

    /// Alternative representations of same content
    ///
    /// Body parts are alternative versions of the same information.
    /// Parts are ordered from lowest to highest fidelity.
    /// Mail clients should display the last one they understand.
    ///
    /// **RFC 2046 Section 5.1.4**
    public static let alternative = Self(__unchecked: (), rawValue: "alternative")

    /// Collection of RFC 822 messages
    ///
    /// Each body part is a complete message (RFC 822).
    /// Default Content-Type for parts is `message/rfc822`
    /// (unlike other subtypes which default to `text/plain`).
    ///
    /// **RFC 2046 Section 5.1.5**
    public static let digest = Self(__unchecked: (), rawValue: "digest")

    /// Body parts to be viewed simultaneously
    ///
    /// All parts should be presented at the same time
    /// (e.g., for compound documents with synchronized media).
    ///
    /// **RFC 2046 Section 5.1.6**
    public static let parallel = Self(__unchecked: (), rawValue: "parallel")
}

// MARK: - RFC Extensions

extension RFC_2046.Multipart.Subtype {
    /// Compound object with root and related parts
    ///
    /// For documents with embedded objects (e.g., HTML with images).
    /// Requires `type` and `start` parameters to identify root part.
    ///
    /// **RFC 2387**
    public static let related = Self(__unchecked: (), rawValue: "related")

    /// HTML form data submission
    ///
    /// Used for HTTP form uploads with file attachments.
    /// Parts contain form fields, identified by `name` parameter
    /// in Content-Disposition header.
    ///
    /// **RFC 7578**
    public static let formData = Self(__unchecked: (), rawValue: "form-data")

    /// HTTP byte range responses
    ///
    /// Used in HTTP 206 Partial Content responses when
    /// multiple ranges are requested.
    ///
    /// **RFC 2046 Section 5.2.3 / RFC 7233**
    public static let byteranges = Self(__unchecked: (), rawValue: "byteranges")

    /// Signed message (S/MIME)
    ///
    /// Contains original message and detached signature.
    ///
    /// **RFC 5751**
    public static let signed = Self(__unchecked: (), rawValue: "signed")

    /// Encrypted message (S/MIME)
    ///
    /// Contains encryption control information and encrypted content.
    ///
    /// **RFC 5751**
    public static let encrypted = Self(__unchecked: (), rawValue: "encrypted")

    /// Report message (delivery status, disposition)
    ///
    /// Used for email delivery status notifications and
    /// message disposition notifications.
    ///
    /// **RFC 6522**
    public static let report = Self(__unchecked: (), rawValue: "report")
}
