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

// RFC_2046.QuotedPrintable.swift
// swift-rfc-2046

import INCITS_4_1986

extension RFC_2046 {
    /// Quoted-printable content-transfer-encoding codec (RFC 2045 §6.7).
    ///
    /// INTERIM LOCATION (F-002): this codec canonically belongs in
    /// swift-ietf/swift-rfc-2045, which owns `ContentTransferEncoding` and
    /// RFC 2045 §6.7. It lives here (internal) until the upstream package
    /// gains the capability; migrate and delete when that lands.
    ///
    /// The encoder is binary-safe: every byte outside the literal-representable
    /// set (printable US-ASCII 33–126 except `=`) is emitted as an `=XX`
    /// hexadecimal escape, and soft line breaks (`=` CRLF) keep encoded lines
    /// within the 76-character limit. Decoding the encoder's output always
    /// yields the original bytes exactly.
    enum QuotedPrintable {
        /// Encodes `bytes` as quoted-printable per RFC 2045 §6.7.
        static func encode(_ bytes: [Byte]) -> [Byte] {
            let equals = ASCII.Code.equalsSign.byte
            let cr = ASCII.Code.cr.byte
            let lf = ASCII.Code.lf.byte
            let hexDigits: [Byte] = [Byte]("0123456789ABCDEF".utf8)

            var output: [Byte] = []
            output.reserveCapacity(bytes.count + bytes.count / 3)
            var lineLength = 0

            for byte in bytes {
                let isLiteral = (33...126).contains(byte.underlying) && byte != equals
                let tokenLength = isLiteral ? 1 : 3

                // Soft line break: keep every encoded line within 76 chars
                // (75 payload chars + the soft-break '=').
                if lineLength + tokenLength > 75 {
                    output.append(equals)
                    output.append(cr)
                    output.append(lf)
                    lineLength = 0
                }

                if isLiteral {
                    output.append(byte)
                } else {
                    output.append(equals)
                    output.append(hexDigits[Int(byte.underlying >> 4)])
                    output.append(hexDigits[Int(byte.underlying & 0x0F)])
                }
                lineLength += tokenLength
            }
            return output
        }

        /// Decodes quoted-printable `bytes`; returns `nil` on a malformed
        /// escape sequence.
        static func decode(_ bytes: [Byte]) -> [Byte]? {
            let equals = ASCII.Code.equalsSign.byte
            let cr = ASCII.Code.cr.byte
            let lf = ASCII.Code.lf.byte

            func hexValue(_ byte: Byte) -> UInt8? {
                switch byte.underlying {
                case 0x30...0x39: return byte.underlying - 0x30  // 0-9
                case 0x41...0x46: return byte.underlying - 0x41 + 10  // A-F
                case 0x61...0x66: return byte.underlying - 0x61 + 10  // a-f (lenient)
                default: return nil
                }
            }

            var output: [Byte] = []
            output.reserveCapacity(bytes.count)
            var index = bytes.startIndex

            while index < bytes.endIndex {
                let byte = bytes[index]
                if byte == equals {
                    let next = index + 1
                    // Soft line break: "=" CRLF (or lenient "=" LF).
                    if next < bytes.endIndex, bytes[next] == cr,
                        next + 1 < bytes.endIndex, bytes[next + 1] == lf
                    {
                        index = next + 2
                        continue
                    }
                    if next < bytes.endIndex, bytes[next] == lf {
                        index = next + 1
                        continue
                    }
                    // Hexadecimal escape: "=XX".
                    guard next + 1 < bytes.endIndex,
                        let high = hexValue(bytes[next]),
                        let low = hexValue(bytes[next + 1])
                    else { return nil }
                    output.append(Byte((high << 4) | low))
                    index = next + 2
                } else {
                    output.append(byte)
                    index += 1
                }
            }
            return output
        }
    }
}
