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

// BodyPart.Headers Unfolding Tests.swift
// swift-rfc-2046

import RFC_2045
import Testing

@testable import RFC_2046

// MARK: - [INST-TEST-013] Edge-case sub-suite on the affected source type

extension RFC_2046.BodyPart.Headers {
    @Suite
    struct `Edge Case` {
        // F-008 — folded (continuation-line) MIME headers must be unfolded per
        // RFC 5322 §2.2.3 before per-header parsing.
        @Test
        func `Folded Content-Type header is unfolded and parsed`() throws {
            let raw = [Byte](
                "Content-Type: multipart/mixed;\r\n boundary=abc123\r\n".utf8
            )
            let headers = try RFC_2046.BodyPart.Headers(ascii: raw)
            #expect(headers.contentType?.type == "multipart")
            #expect(headers.contentType?.subtype == "mixed")
            #expect(headers.contentType?.parameters[.boundary] == "abc123")
        }

        // F-008 — a tab-folded custom header unfolds into a single header.
        @Test
        func `Tab-folded custom header unfolds into one header`() throws {
            let raw = [Byte](
                "X-Custom: first\r\n\tsecond\r\nContent-Transfer-Encoding: 7bit\r\n".utf8
            )
            let headers = try RFC_2046.BodyPart.Headers(ascii: raw)
            #expect(headers.contentTransferEncoding == .sevenBit)
            #expect(headers.custom.count == 1)
        }
    }
}
