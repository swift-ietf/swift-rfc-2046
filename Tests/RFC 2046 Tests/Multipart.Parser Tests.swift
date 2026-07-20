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

// Multipart.Parser Tests.swift
// swift-rfc-2046

import Testing

@testable import RFC_2046

// MARK: - [INST-TEST-013] Edge-case sub-suite on the affected source type

extension RFC_2046.Multipart.Parser {
    @Suite
    struct `Edge Case` {
        // F-003 — RFC 2046 §5.1.1: delimiter lines may carry transport padding
        // (linear whitespace) between the dash-boundary and the CRLF.
        @Test
        func `Delimiter lines with trailing transport padding are recognized`() throws {
            let raw =
                "--simple-boundary \t \r\n"
                + "Content-Type: text/plain\r\n"
                + "\r\n"
                + "Hello\r\n"
                + "--simple-boundary--  \r\n"
            let boundary = try RFC_2046.Boundary("simple-boundary")
            let multipart = try RFC_2046.Multipart.parse(
                from: [Byte](raw.utf8),
                parser: RFC_2046.Multipart.Parser(boundary: boundary)
            )
            #expect(multipart.parts.count == 1)
            #expect(multipart.parts[0].content.rawValue == [Byte]("Hello".utf8))
        }

        // F-003 — a line that merely starts with the dash-boundary but continues
        // with non-whitespace is NOT a delimiter.
        @Test
        func `Dash-boundary prefix followed by non-whitespace is not a delimiter`() throws {
            let raw =
                "--b\r\n"
                + "\r\n"
                + "--bogus is content, not a delimiter\r\n"
                + "--b--\r\n"
            let boundary = try RFC_2046.Boundary("b")
            let multipart = try RFC_2046.Multipart.parse(
                from: [Byte](raw.utf8),
                parser: RFC_2046.Multipart.Parser(boundary: boundary)
            )
            #expect(multipart.parts.count == 1)
            #expect(
                multipart.parts[0].content.rawValue
                    == [Byte]("--bogus is content, not a delimiter".utf8)
            )
        }
    }
}
