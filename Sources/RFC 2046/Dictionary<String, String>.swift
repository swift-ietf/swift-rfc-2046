//
//  File.swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

/// Converts to string dictionary for wire format encoding
///
/// This is the boundary where type-safety converts to strings for transmission.
///
/// - Returns: String-based header dictionary ready for encoding
import RFC_2183

extension [String: String] {
    public init(
        _ bodypartHeaders: RFC_2046.BodyPart.Headers
    ) {
        var dict: [String: String] = [:]

        if let contentDisposition = bodypartHeaders.contentDisposition {
            dict["Content-Disposition"] = contentDisposition.headerValue
        }

        if let contentType = bodypartHeaders.contentType {
            dict["Content-Type"] = contentType.headerValue
        }

        if let contentTransferEncoding = bodypartHeaders.contentTransferEncoding {
            dict["Content-Transfer-Encoding"] = contentTransferEncoding.headerValue
        }

        self = dict
    }
}
