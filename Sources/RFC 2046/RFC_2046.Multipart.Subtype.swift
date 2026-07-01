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

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives
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

// MARK: - ASCII.Serializable / Binary.Serializable ([FAM-012] format siblings)

extension RFC_2046.Multipart.Subtype: ASCII.Serializable, Binary.Serializable {
    /// Serializes the subtype token as ASCII text.
    ///
    /// [FAM-012] text sibling — emits the typed text substrate `ASCII.Code`.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ subtype: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in subtype.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    /// Serializes the subtype token as wire bytes.
    ///
    /// [FAM-012] binary sibling. Clause-9: an independent body re-emitting the
    /// lowercased ASCII token directly into the `Byte` domain — NOT a
    /// text-serialization detour. Byte-equivalent to the text form (a media subtype
    /// is an ASCII token); the ASCII==Binary equivalence test guards against drift.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ subtype: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        for byte in subtype.rawValue.utf8 { buffer.append(Byte(byte)) }
    }
}

extension RFC_2046.Multipart.Subtype: Swift.RawRepresentable {
    /// Creates a subtype by validating `rawValue`, or `nil` if it is empty.
    ///
    /// Re-provides `Swift.RawRepresentable` directly — the retired combined
    /// ASCII/binary RawRepresentable tier no longer synthesizes it. (Load-bearing:
    /// the `RawRepresentable`+`Codable` pair synthesizes the single-value JSON
    /// form.)
    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

extension RFC_2046.Multipart.Subtype: CustomStringConvertible {
    /// The subtype token — the same text the `ASCII.Serializable` /
    /// `Binary.Serializable` verbs emit.
    public var description: String { rawValue }
}

// MARK: - Parsing

extension RFC_2046.Multipart.Subtype: ASCII.Parseable {
    /// Creates a subtype by validating `string`'s UTF-8 bytes as ASCII.
    ///
    /// Re-provides the string convenience initializer (previously inherited from
    /// the retired combined ASCII serializable protocol, Void context).
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses a subtype from canonical byte representation
    ///
    /// Per RFC 2045, media type names are case-insensitive.
    /// The input is normalized to lowercase.
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_2046.Multipart.Subtype (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array<Byte>("alternative".utf8)
    /// let subtype = try RFC_2046.Multipart.Subtype(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation
    /// - Throws: `RFC_2046.Multipart.Subtype.Error` if empty
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        // Normalize to lowercase per RFC 2045 (subtypes are ASCII tokens, so
        // Unicode-default case folding is byte-identical to ASCII lowercasing).
        self.init(
            __unchecked: (),
            rawValue: String(decoding: bytes, as: UTF8.self).lowercased()
        )
    }
}

extension [Byte] {
    /// Creates ASCII bytes from RFC 2046 Multipart Subtype
    ///
    /// ## Example
    ///
    /// ```swift
    /// let subtype = RFC_2046.Multipart.Subtype.alternative
    /// let bytes = [Byte](subtype)
    /// ```
    ///
    /// - Parameter subtype: The subtype to serialize
    public init(_ subtype: RFC_2046.Multipart.Subtype) {
        self = []
        RFC_2046.Multipart.Subtype.serialize(subtype, into: &self)
    }
}

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
