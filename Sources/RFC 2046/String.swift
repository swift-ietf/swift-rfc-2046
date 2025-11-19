//
//  File.swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

import RFC_2183
import RFC_5322

extension String {
    /// Renders headers as RFC 5322 header fields
    ///
    /// Preserves order and includes all headers (including duplicates).
    /// Typed headers (Content-Disposition, Content-Type, Content-Transfer-Encoding)
    /// are rendered first, followed by custom headers in their original order.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers = RFC_2046.BodyPart.Headers(
    ///     contentType: .textPlainUTF8,
    ///     custom: [.init(name: "X-Custom", value: "value")]
    /// )
    /// let rendered = String(headers)
    /// // "Content-Type: text/plain; charset=UTF-8\r\nX-Custom: value"
    /// ```
    public init(
        _ bodypartHeaders: RFC_2046.BodyPart.Headers
    ) {
        var lines: [String] = []

        // Render typed headers in consistent order
        if let contentDisposition = bodypartHeaders.contentDisposition {
            lines.append("Content-Disposition: \(String(rfc2183: contentDisposition))")
        }

        if let contentType = bodypartHeaders.contentType {
            lines.append("Content-Type: \(contentType.headerValue)")
        }

        if let contentTransferEncoding = bodypartHeaders.contentTransferEncoding {
            lines.append("Content-Transfer-Encoding: \(contentTransferEncoding.headerValue)")
        }

        // Render custom headers in order (preserves duplicates)
        for header in bodypartHeaders.custom {
            lines.append("\(header.name.rawValue): \(header.value)")
        }

        self = lines.joined(separator: "\r\n")
    }
}
