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

// BodyPart.Content Tests.swift
// swift-rfc-2046

import Testing

@testable import RFC_2046

// MARK: - [INST-TEST-013] Unit sub-suite on the affected source type

extension RFC_2046.BodyPart.Content {
    @Suite
    struct Unit {
        // F-001 — Content canonically stores DECODED bytes: parsing a body
        // part whose Content-Transfer-Encoding is base64 must decode the wire
        // content instead of storing the encoded text.
        @Test
        func `Parse decodes base64 transfer-encoded content to canonical bytes`() throws {
            let raw = [Byte](
                "Content-Transfer-Encoding: base64\r\n\r\nSGVsbG8sIFdvcmxkIQ==".utf8
            )
            let part = try RFC_2046.BodyPart(binary: raw)
            #expect(part.content.rawValue == [Byte]("Hello, World!".utf8))
        }

        // F-001 — reparse-then-serialize must not double-encode: the round
        // trip parse(serialize(x)) == x is the invariant.
        @Test
        func `Base64 part round-trips without double encoding`() throws {
            let payload: [Byte] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]
            let original = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .init(__unchecked: (), type: "image", subtype: "jpeg"),
                    contentTransferEncoding: .base64
                ),
                content: RFC_2046.BodyPart.Content(payload)
            )
            let wire = [Byte](original)
            let reparsed = try RFC_2046.BodyPart(binary: wire)
            #expect(reparsed.content.rawValue == payload)
            #expect([Byte](reparsed) == wire)
        }

        // F-001 — the same invariant holds through Multipart parsing, for both
        // base64 and quoted-printable parts.
        @Test
        func `Multipart round-trips transfer-encoded parts without double encoding`() throws {
            let binaryPayload: [Byte] = [0x00, 0x01, 0xFE, 0xFF]
            let base64Part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .init(
                        __unchecked: (),
                        type: "application",
                        subtype: "octet-stream"
                    ),
                    contentTransferEncoding: .base64
                ),
                content: RFC_2046.BodyPart.Content(binaryPayload)
            )
            let quotedPart = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .textPlainUTF8,
                    contentTransferEncoding: .quotedPrintable
                ),
                content: RFC_2046.BodyPart.Content([Byte]("a=b".utf8) + [0x0F])
            )
            let boundary = try RFC_2046.Boundary("rt-boundary")
            let original = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [base64Part, quotedPart],
                boundary: boundary
            )
            let wire = [Byte](original)
            let reparsed = try RFC_2046.Multipart.parse(
                from: wire,
                parser: RFC_2046.Multipart.Parser(boundary: boundary)
            )
            #expect(reparsed.parts.count == 2)
            #expect(reparsed.parts[0].content.rawValue == binaryPayload)
            #expect(reparsed.parts[1].content.rawValue == [Byte]("a=b".utf8) + [0x0F])
            #expect([Byte](reparsed) == wire)
        }

        // F-001 — malformed base64 content surfaces as a typed error rather
        // than being silently stored.
        @Test
        func `Malformed base64 content throws a typed error`() throws {
            let raw = [Byte](
                "Content-Transfer-Encoding: base64\r\n\r\nnot!!valid@@base64".utf8
            )
            #expect(throws: RFC_2046.BodyPart.Error.self) {
                _ = try RFC_2046.BodyPart(binary: raw)
            }
        }
    }
}
