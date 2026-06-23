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

// RFC_2046.Lines.swift
// swift-rfc-2046

import INCITS_4_1986

extension RFC_2046 {
    /// Splits raw bytes into line slices, recognising CR, LF, and CRLF
    /// terminators (excluded from each slice).
    ///
    /// The byte-domain counterpart of the retired `[UInt8].ascii.lineRanges()`:
    /// MIME bodies are binary-capable, so lines are scanned over `[Byte]` rather
    /// than lifted to `[ASCII.Code]`. Behaviour mirrors RFC 5322 line structure —
    /// a trailing terminator yields no trailing empty line, and consecutive
    /// terminators yield empty slices, preserving the blank line that separates a
    /// body part's headers from its content.
    ///
    /// Returned slices are zero-copy views into `bytes`.
    static func lines(of bytes: [Byte]) -> [ArraySlice<Byte>] {
        let cr = ASCII.Code.cr.byte
        let lf = ASCII.Code.lf.byte

        var result: [ArraySlice<Byte>] = []
        var lineStart = bytes.startIndex
        var index = bytes.startIndex

        while index < bytes.endIndex {
            let byte = bytes[index]
            if byte == cr {
                result.append(bytes[lineStart..<index])
                let next = bytes.index(after: index)
                index = next < bytes.endIndex && bytes[next] == lf
                    ? bytes.index(after: next)
                    : next
                lineStart = index
            } else if byte == lf {
                result.append(bytes[lineStart..<index])
                index = bytes.index(after: index)
                lineStart = index
            } else {
                index = bytes.index(after: index)
            }
        }

        if lineStart < bytes.endIndex {
            result.append(bytes[lineStart..<bytes.endIndex])
        }
        return result
    }
}
