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

public extension RFC_2046.BodyPart {
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
    struct Headers: Hashable, Sendable, Codable {
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
        init(
            __unchecked _: Void,
            contentDisposition: RFC_2183.ContentDisposition?,
            contentType: RFC_2045.ContentType?,
            contentTransferEncoding: RFC_2045.ContentTransferEncoding?,
            custom: [RFC_5322.Header]
        ) {
            self.contentDisposition = contentDisposition
            self.contentType = contentType
            self.contentTransferEncoding = contentTransferEncoding
            self.custom = custom
        }

        /// Creates typed headers
        ///
        /// - Parameters:
        ///   - contentDisposition: Optional Content-Disposition header
        ///   - contentType: Optional Content-Type header
        ///   - contentTransferEncoding: Optional Content-Transfer-Encoding header
        ///   - custom: Additional custom headers
        public init(
            contentDisposition: RFC_2183.ContentDisposition? = nil,
            contentType: RFC_2045.ContentType? = nil,
            contentTransferEncoding: RFC_2045.ContentTransferEncoding? = nil,
            custom: [RFC_5322.Header] = []
        ) {
            self.init(
                __unchecked: (),
                contentDisposition: contentDisposition,
                contentType: contentType,
                contentTransferEncoding: contentTransferEncoding,
                custom: custom
            )
        }
    }
}

// MARK: - UInt8.ASCII.Serializing

extension RFC_2046.BodyPart.Headers: UInt8.ASCII.Serializing {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses headers from canonical byte representation
    ///
    /// Parses MIME header lines from raw bytes. Each line is `name: value`,
    /// terminated by CRLF. An empty line terminates the headers.
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2046.BodyPart.Headers (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headerBytes = Array("Content-Type: text/plain\r\n".utf8)
    /// let headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of headers
    /// - Throws: `RFC_2046.BodyPart.Headers.Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
        where Bytes.Element == UInt8
    {
        var contentDisposition: RFC_2183.ContentDisposition?
        var contentType: RFC_2045.ContentType?
        var contentTransferEncoding: RFC_2045.ContentTransferEncoding?
        var customHeaders: [RFC_5322.Header] = []

        // Parse header lines (split on CRLF, CR, or LF for leniency)
        var lineBytes: [UInt8] = []
        var i = bytes.startIndex

        while i < bytes.endIndex {
            let byte = bytes[i]

            if byte == UInt8.ascii.cr {
                // Check for CRLF
                let next = bytes.index(after: i)
                if next < bytes.endIndex && bytes[next] == UInt8.ascii.lf {
                    // CRLF - process line
                    try Self.parseLine(lineBytes, into: &contentDisposition, &contentType, &contentTransferEncoding, &customHeaders)
                    lineBytes = []
                    i = bytes.index(after: next)
                } else {
                    // Just CR
                    try Self.parseLine(lineBytes, into: &contentDisposition, &contentType, &contentTransferEncoding, &customHeaders)
                    lineBytes = []
                    i = next
                }
            } else if byte == UInt8.ascii.lf {
                // Just LF
                try Self.parseLine(lineBytes, into: &contentDisposition, &contentType, &contentTransferEncoding, &customHeaders)
                lineBytes = []
                i = bytes.index(after: i)
            } else {
                lineBytes.append(byte)
                i = bytes.index(after: i)
            }
        }

        // Process final line if not empty
        if !lineBytes.isEmpty {
            try Self.parseLine(lineBytes, into: &contentDisposition, &contentType, &contentTransferEncoding, &customHeaders)
        }

        self.init(
            __unchecked: (),
            contentDisposition: contentDisposition,
            contentType: contentType,
            contentTransferEncoding: contentTransferEncoding,
            custom: customHeaders
        )
    }

    /// Parses a single header line from bytes
    @inline(__always)
    private static func parseLine(
        _ lineBytes: [UInt8],
        into contentDisposition: inout RFC_2183.ContentDisposition?,
        _ contentType: inout RFC_2045.ContentType?,
        _ contentTransferEncoding: inout RFC_2045.ContentTransferEncoding?,
        _ customHeaders: inout [RFC_5322.Header]
    ) throws(Error) {
        guard !lineBytes.isEmpty else { return }

        // Find colon separator
        guard let colonIndex = lineBytes.firstIndex(of: UInt8.ascii.colon) else {
            throw Error.invalidHeaderLine(String(decoding: lineBytes, as: UTF8.self))
        }

        let nameBytes = lineBytes[..<colonIndex].ascii.trimming(.ascii.whitespaces)
        let valueBytes = lineBytes[lineBytes.index(after: colonIndex)...].ascii.trimming(.ascii.whitespaces)

        guard !nameBytes.isEmpty else {
            throw Error.emptyHeaderName
        }

        // Determine header type and parse value
        let nameLower = nameBytes.ascii.lowercased()

        if nameLower == Self.contentDispositionBytes {
            contentDisposition = try? RFC_2183.ContentDisposition(ascii: valueBytes)
        } else if nameLower == Self.contentTypeBytes {
            contentType = try? RFC_2045.ContentType(ascii: valueBytes)
        } else if nameLower == Self.contentTransferEncodingBytes {
            contentTransferEncoding = try? RFC_2045.ContentTransferEncoding(ascii: valueBytes)
        } else {
            // Custom header - create RFC_5322.Header
            if let header = try? RFC_5322.Header(
                name: RFC_5322.Header.Name(String(decoding: nameBytes, as: UTF8.self)),
                value: RFC_5322.Header.Value(String(decoding: valueBytes, as: UTF8.self))
            ) {
                customHeaders.append(header)
            }
        }
    }

    // Header name byte constants for comparison
    private static let contentDispositionBytes: [UInt8] = Array("content-disposition".utf8)
    private static let contentTypeBytes: [UInt8] = Array("content-type".utf8)
    private static let contentTransferEncodingBytes: [UInt8] = Array("content-transfer-encoding".utf8)
}

public extension [UInt8] {
    /// Creates ASCII bytes from RFC 2046 BodyPart Headers
    ///
    /// Serializes headers as RFC 5322 header lines (name: value CRLF).
    ///
    /// ## Category Theory
    ///
    /// Serialization (natural transformation):
    /// - **Domain**: RFC_2046.BodyPart.Headers (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers = RFC_2046.BodyPart.Headers(
    ///     contentType: .textPlainUTF8
    /// )
    /// let bytes = [UInt8](headers)
    /// ```
    ///
    /// - Parameter headers: The headers to serialize
    init(_ headers: RFC_2046.BodyPart.Headers) {
        self = []

        let crlf: [UInt8] = [.ascii.cr, .ascii.lf]
        let colonSpace: [UInt8] = [.ascii.colon, .ascii.space]

        // Content-Disposition
        if let contentDisposition = headers.contentDisposition {
            append(contentsOf: [UInt8](RFC_2183.ContentDisposition.self))
            append(contentsOf: colonSpace)
            append(contentsOf: [UInt8](contentDisposition))
            append(contentsOf: crlf)
        }

        // Content-Type
        if let contentType = headers.contentType {
            append(contentsOf: [UInt8](RFC_2045.ContentType.self))
            append(contentsOf: colonSpace)
            append(contentsOf: [UInt8](contentType))
            append(contentsOf: crlf)
        }

        // Content-Transfer-Encoding
        if let contentTransferEncoding = headers.contentTransferEncoding {
            append(contentsOf: [UInt8](RFC_2045.ContentTransferEncoding.self))
            append(contentsOf: colonSpace)
            append(contentsOf: [UInt8](contentTransferEncoding))
            append(contentsOf: crlf)
        }

        // Custom headers
        for header in headers.custom {
            append(contentsOf: [UInt8](header.name))
            append(contentsOf: colonSpace)
            append(contentsOf: [UInt8](header.value))
            append(contentsOf: crlf)
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_2046.BodyPart.Headers: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - Convenience Initializers

public extension RFC_2046.BodyPart.Headers {
    /// Creates headers from an array of RFC 5322 headers
    ///
    /// Preserves header order and allows duplicate headers per RFC 5322.
    ///
    /// - Parameter headers: Array of RFC 5322 headers
    init(_ headers: [RFC_5322.Header]) throws {
        var contentDisposition: RFC_2183.ContentDisposition?
        var contentType: RFC_2045.ContentType?
        var contentTransferEncoding: RFC_2045.ContentTransferEncoding?
        var customHeaders: [RFC_5322.Header] = []

        for header in headers {
            switch header.name {
            case .contentDisposition:
                // Parse using byte-based init
                contentDisposition = try RFC_2183.ContentDisposition(ascii: Array(String(header.value).utf8))
            case .contentType:
                contentType = try RFC_2045.ContentType(ascii: Array(String(header.value).utf8))
            case .contentTransferEncoding:
                contentTransferEncoding = try RFC_2045.ContentTransferEncoding(ascii: Array(String(header.value).utf8))
            default:
                customHeaders.append(header)
            }
        }

        self.init(
            __unchecked: (),
            contentDisposition: contentDisposition,
            contentType: contentType,
            contentTransferEncoding: contentTransferEncoding,
            custom: customHeaders
        )
    }
}

// MARK: - Subscript

public extension RFC_2046.BodyPart.Headers {
    /// Subscript access to header values by typed name
    ///
    /// Provides type-safe access to headers using `RFC_5322.Header.Name`.
    /// String literals work via `ExpressibleByStringLiteral` conformance.
    ///
    /// - Parameter headerName: Typed header name (e.g., .contentType or "Content-Type")
    /// - Returns: Header value as string, or nil if not present
    subscript(headerName: RFC_5322.Header.Name) -> String? {
        get {
            switch headerName {
            case .contentDisposition:
                return contentDisposition.map(\.description)
            case .contentType:
                return contentType?.headerValue
            case .contentTransferEncoding:
                return contentTransferEncoding?.headerValue
            default:
                return custom[headerName]
            }
        }
        set {
            switch headerName {
            case .contentDisposition:
                if let value = newValue {
                    contentDisposition = try? RFC_2183.ContentDisposition(ascii: Array(value.utf8))
                } else {
                    contentDisposition = nil
                }
            case .contentType:
                if let value = newValue {
                    contentType = try? RFC_2045.ContentType(ascii: Array(value.utf8))
                } else {
                    contentType = nil
                }
            case .contentTransferEncoding:
                if let value = newValue {
                    contentTransferEncoding = try? RFC_2045.ContentTransferEncoding(ascii: Array(value.utf8))
                } else {
                    contentTransferEncoding = nil
                }
            default:
                custom[headerName] = newValue
            }
        }
    }
}

// MARK: - Convenience Constructors

public extension RFC_2046.BodyPart.Headers {
    /// Creates headers for a form-data text field
    ///
    /// - Parameter name: Form field name
    /// - Returns: Headers configured for a text field
    static func formDataTextField(name: String) -> Self {
        Self(contentDisposition: .formData(name: name))
    }

    /// Creates headers for a form-data file upload
    ///
    /// - Parameters:
    ///   - name: Form field name
    ///   - filename: Filename for the upload
    ///   - contentType: Optional content type (defaults to application/octet-stream)
    /// - Returns: Headers configured for a file upload
    static func formDataFile(
        name: String,
        filename: RFC_2183.Filename,
        contentType: RFC_2045.ContentType? = nil
    ) -> Self {
        Self(
            contentDisposition: .formData(name: name, filename: filename),
            contentType: contentType
        )
    }
}
