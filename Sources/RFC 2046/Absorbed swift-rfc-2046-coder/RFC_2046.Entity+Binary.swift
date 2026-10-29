#if Coder
    import ASCII
    public import Byte
    import RFC_2045

    extension RFC_2046.Entity {

        public init<Bytes: Swift::Collection>(binary input: Bytes) where Bytes.Element == Byte {
            self.init(bytes: [Byte](input), default: .textPlain, depth: 0)
        }

        static let depthLimit = 32

        init(bytes: [Byte], default type: RFC_2045.ContentType, depth: Int) {
            let (header, content) = Self.split(bytes)
            let fields = Self.fields(header)
            let contentType = Self.contentType(fields, default: type)
            self.init(
                fields: fields,
                contentType: contentType,
                body: Self.body(content, contentType: contentType, depth: depth)
            )
        }

        static func split(_ bytes: [Byte]) -> (header: [ArraySlice<Byte>], content: [Byte]) {
            let cr = ASCII.Code.cr.byte
            let lf = ASCII.Code.lf.byte
            var header: [ArraySlice<Byte>] = []
            var index = bytes.startIndex
            while index < bytes.endIndex {
                let lineEnd = bytes[index...].firstIndex { $0 == cr || $0 == lf } ?? bytes.endIndex
                let next =
                    lineEnd < bytes.endIndex && bytes[lineEnd] == cr
                        && lineEnd + 1 < bytes.endIndex && bytes[lineEnd + 1] == lf
                    ? lineEnd + 2 : min(lineEnd + 1, bytes.endIndex)
                guard lineEnd > index else {
                    return (header, [Byte](bytes[next...]))
                }
                header.append(bytes[index..<lineEnd])
                index = next
            }
            return (header, [])
        }

        static func fields(_ lines: [ArraySlice<Byte>]) -> [RFC_2046.Entity.Field] {
            let colon = ASCII.Code.colon.byte
            var fields: [(name: [Byte], value: [Byte])] = []
            for line in lines {
                switch (line.first.map(isSpace), fields.isEmpty) {
                case (true?, false):
                    fields[fields.count - 1].value += line
                default:
                    guard let separator = line.firstIndex(of: colon) else { continue }
                    fields.append((name: [Byte](line[..<separator]), value: [Byte](line[(separator + 1)...])))
                }
            }
            return fields.map { field in
                RFC_2046.Entity.Field(
                    name: String(decoding: trimmed(field.name).map(\.bitPattern), as: UTF8.self),
                    value: trimmed(field.value)
                )
            }
        }

        static func contentType(
            _ fields: [RFC_2046.Entity.Field],
            default type: RFC_2045.ContentType
        ) -> RFC_2045.ContentType {
            guard let value = fields.first(where: { $0.name.lowercased() == "content-type" })?.value else {
                return type
            }
            do throws(RFC_2045.ContentType.Error) {
                return try RFC_2045.ContentType(ascii: value)
            } catch {
                return .textPlain
            }
        }

        static func body(
            _ content: [Byte],
            contentType: RFC_2045.ContentType,
            depth: Int
        ) -> RFC_2046.Entity.Body {
            guard depth < depthLimit else { return .discrete(content) }
            switch (contentType.type.lowercased(), contentType.subtype.lowercased(), contentType.boundary) {
            case ("multipart", let subtype, let boundary?):
                let regions = RFC_2046.Multipart.regions(content, boundary: [Byte](utf8: boundary))
                let inner: RFC_2045.ContentType = subtype == "digest" ? message : .textPlain
                return .multipart(
                    RFC_2046.Entity.Body.Multipart(
                        subtype: Self.subtype(subtype),
                        preamble: regions.preamble ?? [],
                        parts: regions.parts.map { RFC_2046.Entity(bytes: $0, default: inner, depth: depth + 1) },
                        epilogue: regions.epilogue ?? []
                    )
                )
            case ("message", "rfc822", _):
                return .message(RFC_2046.Entity(bytes: content, default: .textPlain, depth: depth + 1))
            default:
                return .discrete(content)
            }
        }

        static let message = RFC_2045.ContentType(__unchecked: (), type: "message", subtype: "rfc822")

        static func subtype(_ name: String) -> RFC_2046.Multipart.Subtype {
            do throws(RFC_2046.Multipart.Subtype.Error) {
                return try RFC_2046.Multipart.Subtype(name)
            } catch {
                return .mixed
            }
        }

        static func isSpace(_ byte: Byte) -> Bool {
            byte == ASCII.Code.space.byte || byte == ASCII.Code.htab.byte
        }

        static func trimmed(_ bytes: [Byte]) -> [Byte] {
            let isWhitespace: (Byte) -> Bool = { isSpace($0) || $0 == ASCII.Code.cr.byte || $0 == ASCII.Code.lf.byte }
            let start = bytes.firstIndex { !isWhitespace($0) } ?? bytes.endIndex
            let end = bytes.lastIndex { !isWhitespace($0) }.map { $0 + 1 } ?? start
            return start < end ? [Byte](bytes[start..<end]) : []
        }
    }
#endif
