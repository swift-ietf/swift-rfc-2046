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

// Multipart.ContentType Tests.swift
// swift-rfc-2046

import RFC_2045
import Testing

@testable import RFC_2046

// MARK: - [INST-TEST-013] Unit sub-suite on the affected source type

extension RFC_2046.Multipart {
    @Suite
    struct Unit {
        // F-006 — parameter values that cannot be represented in a
        // Content-Type header (CR/LF injection, controls, quotes) must be
        // rejected with a typed error at init, not interpolated into a header
        // string and force-parsed.
        @Test
        func `Init rejects additional parameter values that cannot be represented`() throws {
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("x")
            )
            let boundary = try RFC_2046.Boundary("b")
            #expect(throws: RFC_2046.Multipart.Error.self) {
                _ = try RFC_2046.Multipart(
                    subtype: .related,
                    parts: [part],
                    boundary: boundary,
                    additionalParameters: [
                        .init(rawValue: "start"): "x\r\nX-Injected: evil"
                    ]
                )
            }
        }

        // F-006 — contentType is constructed structurally, without a
        // serialize-then-reparse round trip; values needing quoting survive.
        @Test
        func `ContentType is built structurally with parameters intact`() throws {
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("x")
            )
            let boundary = try RFC_2046.Boundary("simple boundary")
            let multipart = try RFC_2046.Multipart(
                subtype: .related,
                parts: [part],
                boundary: boundary,
                additionalParameters: [.init(rawValue: "type"): "text/plain; not really"]
            )
            let contentType = multipart.contentType
            #expect(contentType.type == "multipart")
            #expect(contentType.subtype == "related")
            #expect(contentType.parameters[.boundary] == "simple boundary")
            #expect(contentType.parameters[.init(rawValue: "type")] == "text/plain; not really")
        }
    }
}
