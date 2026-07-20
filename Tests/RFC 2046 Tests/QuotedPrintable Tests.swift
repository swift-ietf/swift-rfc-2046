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

// QuotedPrintable Tests.swift
// swift-rfc-2046

import Testing

@testable import RFC_2046

// MARK: - [INST-TEST-013] Unit sub-suite on the affected source type

extension RFC_2046.BodyPart {
    @Suite
    struct Unit {
        // F-002 — a part labeled Content-Transfer-Encoding: quoted-printable
        // must emit quoted-printable-encoded bytes, not raw content.
        @Test
        func `Serialize with quoted-printable encoding applies encoding`() throws {
            let headers = RFC_2046.BodyPart.Headers(
                contentType: .textPlainUTF8,
                contentTransferEncoding: .quotedPrintable
            )
            // '=' must become =3D; 0x0F (control) must become =0F.
            let content = RFC_2046.BodyPart.Content([Byte]("a=b".utf8) + [0x0F])
            let part = RFC_2046.BodyPart(headers: headers, content: content)

            let serialized = [Byte](part)
            let string = String(decoding: serialized, as: UTF8.self)

            #expect(string.contains("Content-Transfer-Encoding: quoted-printable"))
            #expect(string.hasSuffix("a=3Db=0F"))
        }

        // F-002 — the codec round-trips arbitrary bytes.
        @Test
        func `Quoted-printable codec round-trips arbitrary bytes`() throws {
            let payload: [Byte] = Array(0...255).map { Byte($0) }
            let encoded = RFC_2046.QuotedPrintable.encode(payload)
            // Encoded form is 7-bit safe: '=' escapes, printables, soft breaks.
            #expect(encoded.allSatisfy { $0 < 0x80 })
            let decoded = RFC_2046.QuotedPrintable.decode(encoded)
            #expect(decoded == payload)
        }

        // F-002 — encoded lines respect the RFC 2045 §6.7 76-character limit.
        @Test
        func `Quoted-printable encoded lines stay within 76 characters`() throws {
            let payload = [Byte](repeating: ASCII.Code.equalsSign.byte, count: 100)
            let encoded = RFC_2046.QuotedPrintable.encode(payload)
            let lines = String(decoding: encoded, as: UTF8.self).split(
                separator: "\r\n",
                omittingEmptySubsequences: false
            )
            #expect(lines.allSatisfy { $0.count <= 76 })
        }
    }
}
