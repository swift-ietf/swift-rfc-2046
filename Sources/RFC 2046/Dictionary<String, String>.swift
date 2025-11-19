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
public import RFC_2183
public import RFC_5322

extension [RFC_5322.Header.Name: String] {
    public init(
        _ bodypartHeaders: RFC_2046.BodyPart.Headers
    ) {
        var dict: [RFC_5322.Header.Name: String] = [:]

        if let contentDisposition = bodypartHeaders.contentDisposition {
            dict[.contentDisposition] = String(contentDisposition)
        }

        if let contentType = bodypartHeaders.contentType {
            dict[.contentType] = contentType.headerValue
        }

        if let contentTransferEncoding = bodypartHeaders.contentTransferEncoding {
            dict[.contentTransferEncoding] = contentTransferEncoding.headerValue
        }

        // Include custom headers (dictionary flattens duplicates - keeps last)
        for header in bodypartHeaders.custom {
            dict[header.name] = header.value
        }

        self = dict
    }
}
