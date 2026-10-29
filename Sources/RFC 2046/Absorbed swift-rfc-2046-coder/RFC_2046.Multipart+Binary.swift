#if Coder
    import ASCII
    public import Binary
    public import Byte
    import RFC_2045

    extension RFC_2046.Multipart: Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ multipart: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            if let preamble = multipart.preamble {
                Scan.append(preamble, into: &buffer)
                Scan.append("\r\n\r\n", into: &buffer)
            }

            for part in multipart.parts {
                Scan.append("--", into: &buffer)
                RFC_2046.Boundary.serialize(multipart.boundary, into: &buffer)
                Scan.append("\r\n", into: &buffer)

                RFC_2046.BodyPart.serialize(part, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }

            Scan.append("--", into: &buffer)
            RFC_2046.Boundary.serialize(multipart.boundary, into: &buffer)
            Scan.append("--\r\n", into: &buffer)

            if let epilogue = multipart.epilogue {
                Scan.append(epilogue, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }
        }
    }

    extension [Byte] {

        public init(_ multipart: RFC_2046.Multipart) {
            self = []
            RFC_2046.Multipart.serialize(multipart, into: &self)
        }
    }

    extension RFC_2046.Multipart {

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

        static func bodyPart(fromRegion region: [Byte]) throws(Error) -> RFC_2046.BodyPart {
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

            let headers: RFC_2046.BodyPart.Headers
            do throws(RFC_2046.BodyPart.Headers.Error) {
                headers = try RFC_2046.BodyPart.Headers(
                    ascii: [Byte](region[region.startIndex..<headerEnd])
                )
            } catch {
                throw Error.invalidBodyPart("Headers: \(error)")
            }

            let contentBytes: [Byte] =
                contentStart < region.endIndex
                ? [Byte](region[contentStart...])
                : []

            guard
                let decoded = RFC_2046.BodyPart.Content.decoding(
                    contentBytes,
                    transferEncoding: headers.contentTransferEncoding
                )
            else {
                throw Error.invalidBodyPart(
                    "content is not valid \(headers.contentTransferEncoding.map { String(decoding: [Byte]($0), as: UTF8.self) } ?? "raw")"
                )
            }
            return RFC_2046.BodyPart(headers: headers, content: RFC_2046.BodyPart.Content(decoded))
        }
    }

    extension RFC_2046.Multipart {

        public init<Bytes: Swift::Collection>(
            binary input: Bytes,
            boundary: RFC_2046.Boundary,
            subtype: RFC_2046.Multipart.Subtype = .mixed
        ) throws(Error) where Bytes.Element == Byte {
            let regions = Self.regions([Byte](input), boundary: [Byte](boundary))
            var parts: [RFC_2046.BodyPart] = []
            for region in regions.parts {
                parts.append(try Self.bodyPart(fromRegion: region))
            }
            try self.init(
                subtype: subtype,
                parts: parts,
                boundary: boundary,
                preamble: regions.preamble.map { String(decoding: $0, as: UTF8.self) },
                epilogue: regions.epilogue.map { String(decoding: $0, as: UTF8.self) }
            )
        }

        static func regions(
            _ bytes: [Byte],
            boundary: [Byte]
        ) -> (preamble: [Byte]?, parts: [[Byte]], epilogue: [Byte]?) {
            var delimiter: [Byte] = [Byte](utf8: "--")
            delimiter.append(contentsOf: boundary)

            var finalDelimiter: [Byte] = delimiter
            finalDelimiter.append(contentsOf: [Byte](utf8: "--"))

            var parts: [[Byte]] = []
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
                        parts.append(region)
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
                parts.append([Byte](bytes[regionStart..<previousContentEnd]))
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

            return (preambleBytes, parts, epilogueBytes)
        }
    }
#endif
