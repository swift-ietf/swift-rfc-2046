public import Byte_Parser_Primitives
import INCITS_4_1986
public import Parser_Primitives

extension RFC_2046.Multipart {

    public struct Parser: Parser_Primitives.Parser.`Protocol`, Sendable {

        public let boundary: RFC_2046.Boundary

        public let subtype: RFC_2046.Multipart.Subtype

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

    static func bodyPart(
        fromRegion region: [Byte]
    ) throws(RFC_2046.Multipart.Error) -> RFC_2046.BodyPart {
        let cr = ASCII.Code.cr.byte
        let lf = ASCII.Code.lf.byte

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

        guard
            let decoded = RFC_2046.BodyPart.Content.decoding(
                contentBytes,
                transferEncoding: headers.contentTransferEncoding
            )
        else {
            throw RFC_2046.Multipart.Error.invalidBodyPart(
                "content is not valid \(headers.contentTransferEncoding?.rawValue ?? "raw")"
            )
        }
        return RFC_2046.BodyPart(headers: headers, content: RFC_2046.BodyPart.Content(decoded))
    }
}

extension RFC_2046.Multipart.Parser {
    public typealias Input = Byte.Input
    public typealias Output = RFC_2046.Multipart
    public typealias Failure = RFC_2046.Multipart.Error
    public typealias Body = Never

    public borrowing func parse(
        _ input: inout Byte.Input
    ) throws(RFC_2046.Multipart.Error) -> RFC_2046.Multipart {

        var bytes: [Byte] = []
        while !input.isEmpty {

            bytes.append(try! input.advance())
        }

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

        var regionStart = bytes.startIndex
        var previousContentEnd = bytes.startIndex
        var sawFirstDelimiter = false
        var inPart = false
        var epilogueStart: Int?

        var index = bytes.startIndex
        let cr = ASCII.Code.cr.byte
        let lf = ASCII.Code.lf.byte

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
                    next += 1
                }
            }

            let line = bytes[lineStart..<contentEnd]
            let isInterior = Self.isDelimiterLine(line, delimiter: delimiter)
            let isFinal = !isInterior && Self.isDelimiterLine(line, delimiter: finalDelimiter)

            if isInterior || isFinal {

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

        if inPart {
            let region = [Byte](bytes[regionStart..<previousContentEnd])
            parts.append(try Self.bodyPart(fromRegion: region))
        }

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

    public static func parse<Bytes: Swift.Collection>(
        from bytes: Bytes,
        parser: Parser
    ) throws(Error) -> RFC_2046.Multipart
    where Bytes.Element == Byte {
        var input = Byte.Input(bytes)
        return try parser.parse(&input)
    }
}
