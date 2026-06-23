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

// RFC_2046.BodyPart.Headers.swift
// swift-rfc-2046

import INCITS_4_1986
public import RFC_2045
public import RFC_2183
public import RFC_5322

// `Code` aliases ASCII.Code at file scope — avoids the INCITS `[ASCII.Code].ASCII`
// shadow inside the `extension [Byte]` below.
private typealias Code = ASCII.Code

extension RFC_2046.BodyPart {
    /// Type-safe headers for multipart body parts
    ///
    /// This structure provides type-safe access to common MIME headers while
    /// supporting custom headers as needed. Type safety is maintained throughout
    /// the codebase until the final encoding step.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var headers = RFC_2046.BodyPart.Headers(
    ///     contentDisposition: .formData(name: "avatar", filename: "photo.jpg"),
    ///     contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
    ///     custom: [
    ///         .init(name: "X-Custom-Header", value: "value")
    ///     ]
    /// )
    ///
    /// // Type-safe subscript access (string literals work via ExpressibleByStringLiteral)
    /// headers["X-Priority"] = "1"
    /// ```
    public struct Headers: Hashable, Sendable, Codable {
        /// Content-Disposition header (RFC 2183)
        public var contentDisposition: RFC_2183.ContentDisposition?

        /// Content-Type header (RFC 2045)
        public var contentType: RFC_2045.ContentType?

        /// Content-Transfer-Encoding header (RFC 2045)
        public var contentTransferEncoding: RFC_2045.ContentTransferEncoding?

        /// Additional custom headers
        ///
        /// Preserves order and allows multiple headers with the same name per RFC 5322.
        public var custom: [RFC_5322.Header]

        /// Creates headers WITHOUT validation
        ///
        /// **Warning**: Bypasses validation.
        /// Only use for internal construction after validation.
        public init(
            contentDisposition: RFC_2183.ContentDisposition? = nil,
            contentType: RFC_2045.ContentType? = nil,
            contentTransferEncoding: RFC_2045.ContentTransferEncoding? = nil,
            custom: [RFC_5322.Header] = []
        ) {
            self.contentDisposition = contentDisposition
            self.contentType = contentType
            self.contentTransferEncoding = contentTransferEncoding
            self.custom = custom
        }
    }
}

// MARK: - Binary.ASCII.Serializable

extension RFC_2046.BodyPart.Headers: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii headers: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        // Content-Disposition
        if let contentDisposition = headers.contentDisposition {
            buffer.append(contentsOf: Array<Byte>("Content-Disposition".utf8))
            buffer.append(Code.colon)
            buffer.append(Code.space)
            // Serialize via UInt8 intermediate; non-migrated dep emits UInt8.
            var u8: [UInt8] = []
            RFC_2183.ContentDisposition.serialize(ascii: contentDisposition, into: &u8)
            buffer.append(contentsOf: Array<Byte>(u8))
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        // Content-Type
        if let contentType = headers.contentType {
            buffer.append(contentsOf: Array<Byte>("Content-Type".utf8))
            buffer.append(Code.colon)
            buffer.append(Code.space)
            var u8: [UInt8] = []
            RFC_2045.ContentType.serialize(ascii: contentType, into: &u8)
            buffer.append(contentsOf: Array<Byte>(u8))
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        // Content-Transfer-Encoding
        if let contentTransferEncoding = headers.contentTransferEncoding {
            buffer.append(contentsOf: Array<Byte>("Content-Transfer-Encoding".utf8))
            buffer.append(Code.colon)
            buffer.append(Code.space)
            var u8: [UInt8] = []
            RFC_2045.ContentTransferEncoding.serialize(
                ascii: contentTransferEncoding,
                into: &u8
            )
            buffer.append(contentsOf: Array<Byte>(u8))
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        // Custom headers
        for header in headers.custom {
            var u8Name: [UInt8] = []
            RFC_5322.Header.Name.serialize(ascii: header.name, into: &u8Name)
            buffer.append(contentsOf: Array<Byte>(u8Name))
            buffer.append(Code.colon)
            buffer.append(Code.space)
            var u8Value: [UInt8] = []
            RFC_5322.Header.Value.serialize(ascii: header.value, into: &u8Value)
            buffer.append(contentsOf: Array<Byte>(u8Value))
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }
    }

    /// Parses headers from canonical byte representation
    ///
    /// Composes canonical transformations: parses each line as `RFC_5322.Header`,
    /// then dispatches to type-specific parsers based on header name.
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation composed from canonical parts:
    /// - `[Byte] → RFC_5322.Header` (canonical header parsing)
    /// - `RFC_5322.Header.Value → RFC_2045.ContentType` (canonical type parsing)
    /// - etc.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headerBytes = Array<Byte>("Content-Type: text/plain\r\n".utf8)
    /// let headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of headers
    /// - Throws: `RFC_2046.BodyPart.Headers.Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == Byte {
        var contentDisposition: RFC_2183.ContentDisposition?
        var contentType: RFC_2045.ContentType?
        var contentTransferEncoding: RFC_2045.ContentTransferEncoding?
        var customHeaders: [RFC_5322.Header] = []

        // INCITS_4_1986.ASCII.lineRanges is UInt8-keyed; bridge once at the
        // entry boundary via BSLI `Array<UInt8>(bytes)` and operate on the
        // UInt8 buffer for the line-range scan and dep calls (RFC_5322 /
        // RFC_2045 / RFC_2183 conformances are still UInt8-substrate).
        let byteArray = Array<UInt8>(bytes)
        let lineRanges = byteArray.ascii.lineRanges()

        for range in lineRanges {
            let lineBytes = Array(byteArray[range])
            guard !lineBytes.isEmpty else { continue }

            // Parse line as RFC_5322.Header using canonical transformation
            let header: RFC_5322.Header
            do {
                header = try RFC_5322.Header(ascii: lineBytes)
            } catch {
                throw Error.invalidHeaderLine(String(decoding: lineBytes, as: UTF8.self))
            }

            // Dispatch based on header name, using canonical parsers
            let valueBytes = [Byte](header.value)

            switch header.name {
            case .contentDisposition:
                contentDisposition = try? RFC_2183.ContentDisposition(ascii: valueBytes)
            case .contentType:
                contentType = try? RFC_2045.ContentType(ascii: valueBytes)
            case .contentTransferEncoding:
                contentTransferEncoding = try? RFC_2045.ContentTransferEncoding(ascii: valueBytes)
            default:
                customHeaders.append(header)
            }
        }

        self.init(
            contentDisposition: contentDisposition,
            contentType: contentType,
            contentTransferEncoding: contentTransferEncoding,
            custom: customHeaders
        )
    }
}

extension [Byte] {
    /// Creates ASCII bytes from RFC 2046 BodyPart Headers
    ///
    /// Serializes headers as RFC 5322 header lines (name: value CRLF).
    ///
    /// ## Category Theory
    ///
    /// Serialization (natural transformation):
    /// - **Domain**: RFC_2046.BodyPart.Headers (structured data)
    /// - **Codomain**: [Byte] (ASCII bytes)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers = RFC_2046.BodyPart.Headers(
    ///     contentType: .textPlainUTF8
    /// )
    /// let bytes = [Byte](headers)
    /// ```
    ///
    /// - Parameter headers: The headers to serialize
    public init(_ headers: RFC_2046.BodyPart.Headers) {
        self = []

        // Estimate capacity based on header presence
        var estimatedSize = 0
        if headers.contentDisposition != nil { estimatedSize += 80 }
        if headers.contentType != nil { estimatedSize += 60 }
        if headers.contentTransferEncoding != nil { estimatedSize += 40 }
        estimatedSize += headers.custom.count * 50
        reserveCapacity(estimatedSize)

        // Build the header block directly in the Byte domain — the dependency
        // serialize inits and the header name/value serializers all emit [Byte].
        var u8: [Byte] = []
        u8.reserveCapacity(estimatedSize)

        let crlf: [Byte] = Array<Byte>("\r\n".utf8)
        let colonSpace: [Byte] = [Code.colon.byte, Code.space.byte]

        // Content-Disposition
        if let contentDisposition = headers.contentDisposition {
            u8.append(contentsOf: [Byte](RFC_2183.ContentDisposition.self))
            u8.append(contentsOf: colonSpace)
            u8.append(contentsOf: [Byte](contentDisposition))
            u8.append(contentsOf: crlf)
        }

        // Content-Type
        if let contentType = headers.contentType {
            u8.append(contentsOf: [Byte](RFC_2045.ContentType.self))
            u8.append(contentsOf: colonSpace)
            u8.append(contentsOf: [Byte](contentType))
            u8.append(contentsOf: crlf)
        }

        // Content-Transfer-Encoding
        if let contentTransferEncoding = headers.contentTransferEncoding {
            u8.append(contentsOf: [Byte](RFC_2045.ContentTransferEncoding.self))
            u8.append(contentsOf: colonSpace)
            u8.append(contentsOf: [Byte](contentTransferEncoding))
            u8.append(contentsOf: crlf)
        }

        // Custom headers
        for header in headers.custom {
            u8.append(contentsOf: [Byte](header.name))
            u8.append(contentsOf: colonSpace)
            u8.append(contentsOf: [Byte](header.value))
            u8.append(contentsOf: crlf)
        }

        self = u8
    }
}

// MARK: - Protocol Conformances

extension RFC_2046.BodyPart.Headers: CustomStringConvertible {}

//// MARK: - Convenience Initializers
//
// extension RFC_2046.BodyPart.Headers {
//    /// Creates headers from an array of RFC 5322 headers
//    ///
//    /// Preserves header order and allows duplicate headers per RFC 5322.
//    ///
//    /// - Parameter headers: Array of RFC 5322 headers
//    public init(_ headers: [RFC_5322.Header]) throws {
//        var contentDisposition: RFC_2183.ContentDisposition?
//        var contentType: RFC_2045.ContentType?
//        var contentTransferEncoding: RFC_2045.ContentTransferEncoding?
//        var customHeaders: [RFC_5322.Header] = []
//
//        for header in headers {
//            switch header.name {
//            case .contentDisposition:
//                // Parse using byte-based init
//                contentDisposition = try RFC_2183.ContentDisposition(ascii: Array(String(header.value).utf8))
//            case .contentType:
//                contentType = try RFC_2045.ContentType(ascii: Array(String(header.value).utf8))
//            case .contentTransferEncoding:
//                contentTransferEncoding = try RFC_2045.ContentTransferEncoding(ascii: Array(String(header.value).utf8))
//            default:
//                customHeaders.append(header)
//            }
//        }
//
//        self.init(
//            contentDisposition: contentDisposition,
//            contentType: contentType,
//            contentTransferEncoding: contentTransferEncoding,
//            custom: customHeaders
//        )
//    }
// }

// MARK: - Subscript

extension RFC_2046.BodyPart.Headers {
    /// Subscript access to header values by typed name
    ///
    /// Provides type-safe access to headers using `RFC_5322.Header.Name`.
    /// String literals work via `ExpressibleByStringLiteral` conformance.
    ///
    /// ## Category Theory
    ///
    /// This subscript implements a lens composing through canonical `[UInt8]`:
    /// - **Get**: `T → [UInt8] (serialize) → String (UTF-8 decode)`
    /// - **Set**: `String → UTF8View → T (parse via init(ascii:))`
    ///
    /// ## Information Theory
    ///
    /// The setter passes `String.UTF8View` directly to parsers (avoiding call-site
    /// `Array` allocation) since `init(ascii:)` accepts any `Collection<UInt8>`.
    ///
    /// - Parameter headerName: Typed header name (e.g., .contentType or "Content-Type")
    /// - Returns: Header value as string, or nil if not present
    public subscript(_ headerName: RFC_5322.Header.Name) -> String? {
        get {
            switch headerName {
            case .contentDisposition:
                return contentDisposition.map(\.description)
            case .contentType:
                return contentType.map(\.description)
            case .contentTransferEncoding:
                return contentTransferEncoding.map(\.description)
            default:
                return custom[headerName]
            }
        }
        set {
            switch headerName {
            case .contentDisposition:
                contentDisposition = newValue.flatMap {
                    try? RFC_2183.ContentDisposition(ascii: Array<Byte>($0.utf8))
                }
            case .contentType:
                contentType = newValue.flatMap {
                    try? RFC_2045.ContentType(ascii: Array<Byte>($0.utf8))
                }
            case .contentTransferEncoding:
                contentTransferEncoding = newValue.flatMap {
                    try? RFC_2045.ContentTransferEncoding(ascii: Array<Byte>($0.utf8))
                }
            default:
                custom[headerName] = newValue
            }
        }
    }
}
