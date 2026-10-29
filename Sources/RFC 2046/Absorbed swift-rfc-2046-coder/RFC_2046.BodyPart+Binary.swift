#if Coder
    import ASCII
    public import Binary
    public import Byte
    import RFC_2045

    extension RFC_2046.BodyPart: Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ bodyPart: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {

            RFC_2046.BodyPart.Headers.serialize(bodyPart.headers, into: &buffer)

            Scan.append("\r\n", into: &buffer)

            buffer.append(
                contentsOf: RFC_2046.BodyPart.Content.encoding(
                    bodyPart.content.rawValue,
                    transferEncoding: bodyPart.transferEncoding
                )
            )
        }
    }

    extension [Byte] {

        public init(_ bodyPart: RFC_2046.BodyPart) {
            self = []
            RFC_2046.BodyPart.serialize(bodyPart, into: &self)
        }
    }

    extension RFC_2046.BodyPart {

        public init<Bytes: Swift::Collection>(binary bytes: Bytes) throws(Error)
        where Bytes.Element == Byte {
            let byteArray = [Byte](bytes)

            let doubleCrlf: [Byte] = [
                ASCII.Code.cr.byte, ASCII.Code.lf.byte,
                ASCII.Code.cr.byte, ASCII.Code.lf.byte,
            ]
            let doubleLf: [Byte] = [ASCII.Code.lf.byte, ASCII.Code.lf.byte]

            var headerEndIndex: Int?
            var contentStartIndex: Int?

            if let index = Lines.firstIndex(of: doubleCrlf, in: byteArray) {
                headerEndIndex = index
                contentStartIndex = index + doubleCrlf.count
            } else if let index = Lines.firstIndex(of: doubleLf, in: byteArray) {
                headerEndIndex = index
                contentStartIndex = index + doubleLf.count
            }

            guard let headerEnd = headerEndIndex, let contentStart = contentStartIndex else {

                let headers: Headers
                do throws(Headers.Error) {
                    headers = try Headers(ascii: byteArray)
                } catch {
                    throw Error.invalidHeaders("\(error)")
                }
                self.init(headers: headers, content: Content([]))
                return
            }

            let headers: Headers
            do throws(Headers.Error) {
                headers = try Headers(ascii: [Byte](byteArray[..<headerEnd]))
            } catch {
                throw Error.invalidHeaders("\(error)")
            }

            let contentBytes: [Byte] =
                contentStart < byteArray.count
                ? [Byte](byteArray[contentStart...])
                : []

            guard
                let decoded = Content.decoding(
                    contentBytes,
                    transferEncoding: headers.contentTransferEncoding
                )
            else {
                throw Error.invalidTransferEncodedContent(
                    "content is not valid \(headers.contentTransferEncoding.map { String(decoding: [Byte]($0), as: UTF8.self) } ?? "raw")"
                )
            }

            self.init(headers: headers, content: Content(decoded))
        }
    }
#endif
