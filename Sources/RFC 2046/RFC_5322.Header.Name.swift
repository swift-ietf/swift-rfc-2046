//
//  File.swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

import RFC_5322

// MARK: - MIME Headers (RFC 2045)

extension RFC_5322.Header.Name {
    /// Content-Type: header (media type)
    public static let contentType: Self = "Content-Type"

    /// Content-Transfer-Encoding: header
    public static let contentTransferEncoding: Self = "Content-Transfer-Encoding"

    /// MIME-Version: header
    public static let mimeVersion: Self = "MIME-Version"

    /// Content-Disposition: header
    public static let contentDisposition: Self = "Content-Disposition"

    /// Content-ID: header
    public static let contentId: Self = "Content-ID"

    /// Content-Description: header
    public static let contentDescription: Self = "Content-Description"
}
