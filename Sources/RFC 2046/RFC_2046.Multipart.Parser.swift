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

// RFC_2046.Multipart.Parser.swift
// swift-rfc-2046

public import Byte_Parser_Primitives
import INCITS_4_1986
public import Parser_Primitives

extension RFC_2046.Multipart {
    /// Parser witness carrying the out-of-band parse CONTEXT a multipart body needs
    /// — the boundary delimiter (and the subtype) — as a stored VALUE.
    ///
    /// ## [FAM-012] §11 — context as a parser-witness VALUE
    ///
    /// Multipart parsing is context-dependent: the same raw bytes decode to
    /// different structures depending on the boundary delimiter. Per the
    /// serialize/parse codec-attachment model §11, that context is **NOT** an
    /// `associatedtype Context` on a flat parse marker ([FAM-001]). It is carried
    /// by a **witness VALUE the caller constructs with the context and passes in**
    /// (the serde `DeserializeSeed` shape). The caller able to supply the boundary
    /// is concrete by construction, so the realistic site is:
    ///
    /// ```swift
    /// let multipart = try RFC_2046.Multipart.parse(
    ///     from: bytes,
    ///     parser: RFC_2046.Multipart.Parser(boundary: boundary, subtype: .alternative)
    /// )
    /// ```
    ///
    /// Serialize-VARIANT ∥ parse-CONTEXT are the same principle: the witness carries
    /// the operation's parameters; you pass the witness. The witness conforms to the
    /// ecosystem `Parser.`Protocol`` — symmetric with the serializer variant-witnesses
    /// conforming to `Serializer.`Protocol`` — so the context lives on the witness
    /// value while the flat parse marker stays context-free ([FAM-001]).
    ///
    /// `Input` is the canonical byte-stream cursor `Byte.Input`; multipart is a
    /// whole-buffer grammar (boundary-delimited, with preamble/epilogue lookahead),
    /// so this leaf parser drains the cursor and runs the boundary/line scan over
    /// the collected bytes.
    public struct Parser: Parser_Primitives.Parser.`Protocol`, Sendable {
        public typealias Input = Byte.Input
        public typealias Output = RFC_2046.Multipart
        public typealias Failure = RFC_2046.Multipart.Error
        public typealias Body = Never

        /// The boundary delimiter separating body parts.
        public let boundary: RFC_2046.Boundary

        /// The multipart subtype (default `.mixed`).
        public let subtype: RFC_2046.Multipart.Subtype

        /// Builds the parser witness with its parse context.
        ///
        /// - Parameters:
        ///   - boundary: The boundary delimiter for the multipart message.
        ///   - subtype: The multipart subtype (default `.mixed`).
        public init(
            boundary: RFC_2046.Boundary,
            subtype: RFC_2046.Multipart.Subtype = .mixed
        ) {
            self.boundary = boundary
            self.subtype = subtype
        }

        /// Parses a multipart body from the byte cursor `input`, consuming it.
        ///
        /// [FAM-012] `Parser.`Protocol`` cursor-form leaf parser: drains the whole
        /// byte cursor (multipart is a whole-buffer grammar) and runs the
        /// boundary/line scan using this witness's stored `boundary` / `subtype`.
        ///
        /// - Parameter input: The byte cursor to consume.
        /// - Returns: The parsed multipart value.
        /// - Throws: `RFC_2046.Multipart.Error` if parsing fails.
        public borrowing func parse(
            _ input: inout Byte.Input
        ) throws(RFC_2046.Multipart.Error) -> RFC_2046.Multipart {
            // Drain the cursor into an owned byte buffer (whole-buffer grammar).
            var bytes: [Byte] = []
            while !input.isEmpty {
                guard let byte = try? input.advance() else { break }
                bytes.append(byte)
            }

            // MIME delimiters: "--boundary" and the closing "--boundary--".
            let boundaryBytes: [Byte] = [Byte](boundary)

            var delimiter: [Byte] = []
            delimiter.reserveCapacity(2 + boundaryBytes.count)
            delimiter.append(ASCII.Code.hyphen.byte)
            delimiter.append(ASCII.Code.hyphen.byte)
            delimiter.append(contentsOf: boundaryBytes)

            var finalDelimiter: [Byte] = []
            finalDelimiter.reserveCapacity(delimiter.count + 2)
            finalDelimiter.append(contentsOf: delimiter)
            finalDelimiter.append(ASCII.Code.hyphen.byte)
            finalDelimiter.append(ASCII.Code.hyphen.byte)

            var parts: [RFC_2046.BodyPart] = []
            var preambleBytes: [Byte]?
            var epilogueBytes: [Byte]?

            var preambleLines: [[Byte]] = []
            var inPreamble = true
            var inPart = false
            var partHeaderLines: [[Byte]] = []
            var partContentLines: [[Byte]] = []
            var inHeaders = true

            let crlf: [Byte] = [ASCII.Code.cr.byte, ASCII.Code.lf.byte]

            for lineSlice in RFC_2046.lines(of: bytes) {
                if lineSlice.elementsEqual(delimiter) {
                    // Start of new part
                    if inPart {
                        let headerBytes = [Byte](partHeaderLines.joined(separator: crlf))
                        let contentBytes = [Byte](partContentLines.joined(separator: crlf))
                        let headers: RFC_2046.BodyPart.Headers
                        do {
                            headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
                        } catch {
                            throw RFC_2046.Multipart.Error.invalidBodyPart("Headers: \(error)")
                        }
                        parts.append(
                            RFC_2046.BodyPart(
                                headers: headers,
                                content: RFC_2046.BodyPart.Content(contentBytes)
                            )
                        )
                    }
                    if inPreamble {
                        preambleBytes =
                            preambleLines.isEmpty
                            ? nil : [Byte](preambleLines.joined(separator: crlf))
                        inPreamble = false
                    }
                    inPart = true
                    inHeaders = true
                    partHeaderLines = []
                    partContentLines = []
                } else if lineSlice.elementsEqual(finalDelimiter) {
                    // End of multipart
                    if inPart {
                        let headerBytes = [Byte](partHeaderLines.joined(separator: crlf))
                        let contentBytes = [Byte](partContentLines.joined(separator: crlf))
                        let headers: RFC_2046.BodyPart.Headers
                        do {
                            headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
                        } catch {
                            throw RFC_2046.Multipart.Error.invalidBodyPart("Headers: \(error)")
                        }
                        parts.append(
                            RFC_2046.BodyPart(
                                headers: headers,
                                content: RFC_2046.BodyPart.Content(contentBytes)
                            )
                        )
                    }
                    inPart = false
                } else if inPart {
                    if inHeaders {
                        if lineSlice.isEmpty {
                            // Empty line ends headers, starts content
                            inHeaders = false
                        } else {
                            partHeaderLines.append([Byte](lineSlice))
                        }
                    } else {
                        partContentLines.append([Byte](lineSlice))
                    }
                } else if inPreamble {
                    preambleLines.append([Byte](lineSlice))
                } else {
                    // Epilogue - use separate appends to avoid intermediate allocations
                    if epilogueBytes == nil {
                        epilogueBytes = [Byte](lineSlice)
                    } else {
                        epilogueBytes!.append(contentsOf: crlf)
                        epilogueBytes!.append(contentsOf: lineSlice)
                    }
                }
            }

            return try RFC_2046.Multipart(
                subtype: subtype,
                parts: parts,
                boundary: boundary,
                preamble: preambleBytes.map { String(decoding: $0, as: UTF8.self) },
                epilogue: epilogueBytes.map { String(decoding: $0, as: UTF8.self) }
            )
        }
    }

    /// Parses a multipart body from `bytes`, with the parse CONTEXT carried by the
    /// `parser` witness VALUE ([FAM-012] §11 — the ergonomic context-bearing entry).
    ///
    /// Builds the canonical `Byte.Input` cursor from `bytes` and delegates to the
    /// witness's `Parser.`Protocol`` cursor `parse(_:)`.
    ///
    /// - Parameters:
    ///   - bytes: The multipart message body as wire bytes.
    ///   - parser: The parser witness carrying the boundary (and subtype).
    /// - Throws: `RFC_2046.Multipart.Error` if parsing fails.
    public static func parse<Bytes: Swift.Collection>(
        from bytes: Bytes,
        parser: Parser
    ) throws(Error) -> RFC_2046.Multipart
    where Bytes.Element == Byte {
        var input = Byte.Input(bytes)
        return try parser.parse(&input)
    }
}
