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
    }
}

extension RFC_2046.Multipart.Parser {
    /// RFC 2046 §5.1.1 delimiter-line recognition: the line consists of the
    /// dash-boundary (`delimiter`) followed only by optional linear whitespace
    /// (transport padding, SP / HTAB). Exact-equality matching would reject
    /// padded delimiters that are valid on the wire (F-003).
    static func isDelimiterLine(
        _ line: ArraySlice<Byte>,
        delimiter: [Byte]
    ) -> Bool {
        guard line.count >= delimiter.count,
            line.prefix(delimiter.count).elementsEqual(delimiter)
        else { return false }
        let space = ASCII.Code.space.byte
        let htab = ASCII.Code.htab.byte
        return line.dropFirst(delimiter.count).allSatisfy { $0 == space || $0 == htab }
    }

    /// Builds a `BodyPart` from the raw byte region between two delimiter lines.
    ///
    /// F-004 — the header block ends at the first blank line; the content is the
    /// EXACT remaining byte range (no line split-and-rejoin), so bare CR / LF
    /// bytes inside binary / 8bit payloads are preserved.
    static func bodyPart(
        fromRegion region: [Byte]
    ) throws(RFC_2046.Multipart.Error) -> RFC_2046.BodyPart {
        let cr = ASCII.Code.cr.byte
        let lf = ASCII.Code.lf.byte

        // Locate the blank line separating headers from content.
        var headerEnd = region.endIndex
        var contentStart = region.endIndex
        var index = region.startIndex
        while index < region.endIndex {
            let lineStart = index
            var lineEnd = index
            while lineEnd < region.endIndex, region[lineEnd] != cr, region[lineEnd] != lf {
                lineEnd += 1
            }
            var next = lineEnd
            if next < region.endIndex {
                if region[next] == cr {
                    next += 1
                    if next < region.endIndex, region[next] == lf { next += 1 }
                } else {
                    next += 1
                }
            }
            if lineStart == lineEnd {
                // Blank line: headers end before it, content starts after it.
                headerEnd = lineStart
                contentStart = next
                break
            }
            index = next
        }

        let headerBytes = [Byte](region[region.startIndex..<headerEnd])
        let headers: RFC_2046.BodyPart.Headers
        do throws(RFC_2046.BodyPart.Headers.Error) {
            headers = try RFC_2046.BodyPart.Headers(ascii: headerBytes)
        } catch {
            throw RFC_2046.Multipart.Error.invalidBodyPart("Headers: \(error)")
        }

        let contentBytes =
            contentStart < region.endIndex
            ? [Byte](region[contentStart...])
            : []
        return RFC_2046.BodyPart(headers: headers, content: RFC_2046.BodyPart.Content(contentBytes))
    }
}

extension RFC_2046.Multipart.Parser {
    public typealias Input = Byte.Input
    public typealias Output = RFC_2046.Multipart
    public typealias Failure = RFC_2046.Multipart.Error
    public typealias Body = Never

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

        // F-004 — RAW-BYTE delimiter scan. Part content is captured as the exact
        // byte range between the line break following the header blank line and
        // the line break preceding the next delimiter. Line splitting is used
        // only to LOCATE delimiter lines and the header blank line — content
        // bytes are never split-and-rejoined, so bare CR / LF bytes inside
        // binary or 8bit payloads survive untouched.
        var parts: [RFC_2046.BodyPart] = []
        var preambleBytes: [Byte]?
        var epilogueBytes: [Byte]?

        var regionStart = bytes.startIndex
        var previousContentEnd = bytes.startIndex
        var sawFirstDelimiter = false
        var inPart = false
        var epilogueStart: Int?

        var index = bytes.startIndex
        let cr = ASCII.Code.cr.byte
        let lf = ASCII.Code.lf.byte

        // Walk lines with explicit byte offsets: (lineStart, contentEnd, next).
        while index < bytes.endIndex {
            let lineStart = index
            var contentEnd = index
            while contentEnd < bytes.endIndex, bytes[contentEnd] != cr, bytes[contentEnd] != lf {
                contentEnd += 1
            }
            var next = contentEnd
            if next < bytes.endIndex {
                if bytes[next] == cr {
                    next += 1
                    if next < bytes.endIndex, bytes[next] == lf { next += 1 }
                } else {
                    next += 1  // lone LF
                }
            }

            let line = bytes[lineStart..<contentEnd]
            let isInterior = Self.isDelimiterLine(line, delimiter: delimiter)
            let isFinal = !isInterior && Self.isDelimiterLine(line, delimiter: finalDelimiter)

            if isInterior || isFinal {
                // The region before this delimiter line, EXCLUDING the line
                // break that precedes the delimiter (it belongs to the
                // delimiter per RFC 2046 §5.1.1).
                let region = [Byte](bytes[regionStart..<previousContentEnd])
                if !sawFirstDelimiter {
                    preambleBytes = region.isEmpty ? nil : region
                    sawFirstDelimiter = true
                } else if inPart {
                    parts.append(try Self.bodyPart(fromRegion: region))
                }
                if isFinal {
                    inPart = false
                    epilogueStart = next
                    break
                }
                inPart = true
                regionStart = next
                previousContentEnd = next
            } else {
                previousContentEnd = contentEnd
            }
            index = next
        }

        // Trailing part with no closing delimiter (lenient — mirrors the
        // previous parser's behavior of not requiring the close-delimiter).
        if inPart {
            let region = [Byte](bytes[regionStart..<previousContentEnd])
            parts.append(try Self.bodyPart(fromRegion: region))
        }

        // Everything after the close-delimiter line is the epilogue; strip a
        // single trailing line break (the transport's final terminator).
        if let start = epilogueStart, start < bytes.endIndex {
            var end = bytes.endIndex
            if end > start, bytes[end - 1] == lf {
                end -= 1
                if end > start, bytes[end - 1] == cr { end -= 1 }
            } else if end > start, bytes[end - 1] == cr {
                end -= 1
            }
            let region = [Byte](bytes[start..<end])
            epilogueBytes = region.isEmpty ? nil : region
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

extension RFC_2046.Multipart {
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
