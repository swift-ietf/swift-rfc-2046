//
//  String.swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import RFC_2045
public import RFC_2183
public import RFC_5322

extension String {
    /// Renders headers as RFC 5322 header fields
    ///
    /// Preserves order and includes all headers (including duplicates).
    /// Typed headers (Content-Disposition, Content-Type, Content-Transfer-Encoding)
    /// are rendered first, followed by custom headers in their original order.
    ///
    /// This implementation maintains full type-safety by transforming all typed
    /// headers to RFC_5322.Header objects before rendering to strings.
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
        // Convert all headers to RFC_5322.Header array (type-safe transformation)
        var headers: [RFC_5322.Header] = []

        // Add typed headers in consistent order
        if let contentDisposition = bodypartHeaders.contentDisposition {
            headers.append(RFC_5322.Header(contentDisposition))
        }

        if let contentType = bodypartHeaders.contentType {
            headers.append(RFC_5322.Header(contentType))
        }

        if let contentTransferEncoding = bodypartHeaders.contentTransferEncoding {
            headers.append(RFC_5322.Header(contentTransferEncoding))
        }

        // Add custom headers (already RFC_5322.Header)
        headers.append(contentsOf: bodypartHeaders.custom)

        // Transform header array to string using RFC 5322's typed transformation
        self = headers.map { String($0) }.joined(separator: "\r\n")
    }
}
