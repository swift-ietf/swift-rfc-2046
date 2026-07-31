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

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
import INCITS_4_1986
public import Parseable_ASCII_Primitives
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

// MARK: - ASCII.Serializable / Binary.Serializable ([FAM-012] dual format siblings)

extension RFC_2046.BodyPart.Headers: ASCII.Serializable {
    /// Serializes the MIME header block as RFC 5322 `name: value CRLF` ASCII text.
    ///
    /// [FAM-012] text sibling — emits the typed text substrate `ASCII.Code`.
    /// Clause-9: composes every sub-part's OWN `ASCII.Code` verb directly into the
    /// sink (`ContentDisposition`, `ContentType`, `ContentTransferEncoding`,
    /// `Header.Name`/`Header.Value`) — no text-serialization / rawValue detour.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ headers: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        if let contentDisposition = headers.contentDisposition {
            for byte in "Content-Disposition".utf8 { buffer.append(ASCII.Code(byte)) }
            buffer.append(Code.colon)
            buffer.append(Code.space)
            RFC_2183.ContentDisposition.serialize(contentDisposition, into: &buffer)
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        if let contentType = headers.contentType {
            for byte in "Content-Type".utf8 { buffer.append(ASCII.Code(byte)) }
            buffer.append(Code.colon)
            buffer.append(Code.space)
            RFC_2045.ContentType.serialize(contentType, into: &buffer)
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        if let contentTransferEncoding = headers.contentTransferEncoding {
            for byte in "Content-Transfer-Encoding".utf8 { buffer.append(ASCII.Code(byte)) }
            buffer.append(Code.colon)
            buffer.append(Code.space)
            RFC_2045.ContentTransferEncoding.serialize(contentTransferEncoding, into: &buffer)
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        for header in headers.custom {
            RFC_5322.Header.Name.serialize(header.name, into: &buffer)
            buffer.append(Code.colon)
            buffer.append(Code.space)
            RFC_5322.Header.Value.serialize(header.value, into: &buffer)
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }
    }
}

extension RFC_2046.BodyPart.Headers: Binary.Serializable {
    /// Serializes the MIME header block as RFC 5322 `name: value CRLF` wire bytes.
    ///
    /// [FAM-012] binary sibling. Clause-9: each sub-part is composed via its OWN
    /// same-format (`Byte`) verb directly into the sink — no text-serialization /
    /// rawValue detour. Byte-equivalent to the ASCII form (header blocks are ASCII
    /// text); the ASCII==Binary equivalence test guards the two bodies against drift.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ headers: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        if let contentDisposition = headers.contentDisposition {
            buffer.append(contentsOf: [Byte]("Content-Disposition".utf8))
            buffer.append(Code.colon.byte)
            buffer.append(Code.space.byte)
            RFC_2183.ContentDisposition.serialize(contentDisposition, into: &buffer)
            buffer.append(Code.cr.byte)
            buffer.append(Code.lf.byte)
        }

        if let contentType = headers.contentType {
            buffer.append(contentsOf: [Byte]("Content-Type".utf8))
            buffer.append(Code.colon.byte)
            buffer.append(Code.space.byte)
            RFC_2045.ContentType.serialize(contentType, into: &buffer)
            buffer.append(Code.cr.byte)
            buffer.append(Code.lf.byte)
        }

        if let contentTransferEncoding = headers.contentTransferEncoding {
            buffer.append(contentsOf: [Byte]("Content-Transfer-Encoding".utf8))
            buffer.append(Code.colon.byte)
            buffer.append(Code.space.byte)
            RFC_2045.ContentTransferEncoding.serialize(contentTransferEncoding, into: &buffer)
            buffer.append(Code.cr.byte)
            buffer.append(Code.lf.byte)
        }

        for header in headers.custom {
            RFC_5322.Header.Name.serialize(header.name, into: &buffer)
            buffer.append(Code.colon.byte)
            buffer.append(Code.space.byte)
            RFC_5322.Header.Value.serialize(header.value, into: &buffer)
            buffer.append(Code.cr.byte)
            buffer.append(Code.lf.byte)
        }
    }
}

// MARK: - ASCII.Parseable ([FAM-012] parse — free-standing init; marker requirement seal-last)

extension RFC_2046.BodyPart.Headers: ASCII.Parseable {

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
    /// let headerBytes = [Byte]("Content-Type: text/plain\r\n".utf8)
    /// let headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of headers
    /// - Throws: `RFC_2046.BodyPart.Headers.Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        var contentDisposition: RFC_2183.ContentDisposition?
        var contentType: RFC_2045.ContentType?
        var contentTransferEncoding: RFC_2045.ContentTransferEncoding?
        var customHeaders: [RFC_5322.Header] = []

        // Split header bytes into physical lines (CR / LF / CRLF), then unfold
        // folded headers per RFC 5322 §2.2.3 (F-008): a line starting with SP
        // or HTAB is a continuation of the previous header line — the CRLF is
        // removed, the leading whitespace is kept.
        let space = ASCII.Code.space.byte
        let htab = ASCII.Code.htab.byte
        var logicalLines: [[Byte]] = []
        for line in RFC_2046.lines(of: [Byte](bytes)) where !line.isEmpty {
            if let first = line.first, first == space || first == htab,
                !logicalLines.isEmpty
            {
                logicalLines[logicalLines.count - 1].append(contentsOf: line)
            } else {
                logicalLines.append([Byte](line))
            }
        }

        for line in logicalLines {
            // Parse line as RFC_5322.Header using canonical transformation
            let header: RFC_5322.Header
            do throws(RFC_5322.Header.Error) {
                header = try RFC_5322.Header(ascii: line)
            } catch {
                throw Error.invalidHeaderLine(String(decoding: line, as: UTF8.self))
            }

            // Dispatch based on header name; re-emit the value bytes via the
            // drained `Header.Value` Byte verb (clause-9 same-format), then feed
            // the type-specific ASCII parsers.
            var valueBytes: [Byte] = []
            RFC_5322.Header.Value.serialize(header.value, into: &valueBytes)

            switch header.name {
            case .contentDisposition:
                do throws(RFC_2183.ContentDisposition.Error) {
                    contentDisposition = try RFC_2183.ContentDisposition(ascii: valueBytes)
                } catch {
                    contentDisposition = nil
                }

            case .contentType:
                do throws(RFC_2045.ContentType.Error) {
                    contentType = try RFC_2045.ContentType(ascii: valueBytes)
                } catch {
                    contentType = nil
                }

            case .contentTransferEncoding:
                do throws(RFC_2045.ContentTransferEncoding.Error) {
                    contentTransferEncoding = try RFC_2045.ContentTransferEncoding(
                        ascii: valueBytes
                    )
                } catch {
                    contentTransferEncoding = nil
                }

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
    /// Creates wire bytes from RFC 2046 BodyPart Headers via the
    /// `Binary.Serializable` verb (the single source of the header-block bytes).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
    /// let bytes = [Byte](headers)
    /// ```
    public init(_ headers: RFC_2046.BodyPart.Headers) {
        self = []
        RFC_2046.BodyPart.Headers.serialize(headers, into: &self)
    }
}

// MARK: - CustomStringConvertible

extension RFC_2046.BodyPart.Headers: CustomStringConvertible {
    /// The header block decoded as UTF-8 text — derived from the
    /// `Binary.Serializable` verb (the retired combined ASCII/binary tier
    /// formerly synthesized this).
    public var description: String {
        var bytes: [Byte] = []
        RFC_2046.BodyPart.Headers.serialize(self, into: &bytes)
        return String(decoding: bytes, as: UTF8.self)
    }
}

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
                contentDisposition = newValue.flatMap { value in
                    do throws(RFC_2183.ContentDisposition.Error) {
                        return try RFC_2183.ContentDisposition(ascii: [Byte](value.utf8))
                    } catch {
                        return nil
                    }
                }

            case .contentType:
                contentType = newValue.flatMap { value in
                    do throws(RFC_2045.ContentType.Error) {
                        return try RFC_2045.ContentType(ascii: [Byte](value.utf8))
                    } catch {
                        return nil
                    }
                }

            case .contentTransferEncoding:
                contentTransferEncoding = newValue.flatMap { value in
                    do throws(RFC_2045.ContentTransferEncoding.Error) {
                        return try RFC_2045.ContentTransferEncoding(ascii: [Byte](value.utf8))
                    } catch {
                        return nil
                    }
                }

            default:
                custom[headerName] = newValue
            }
        }
    }
}
