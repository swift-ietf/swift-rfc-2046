public import Binary_Serializable
import Byte_Collection_Standard_Library_Integration
import INCITS_4_1986
import RFC_4648
import RFC_5322

extension RFC_2046 {

    public struct BodyPart: Hashable, Sendable, Codable {

        public let headers: Headers

        public let content: Content

        public init(headers: Headers, content: Content) {
            self.headers = headers
            self.content = content
        }
    }
}

extension RFC_2046.BodyPart: Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ bodyPart: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {

        RFC_2046.BodyPart.Headers.serialize(bodyPart.headers, into: &buffer)

        buffer.append(ASCII.Code.cr.byte)
        buffer.append(ASCII.Code.lf.byte)

        let contentBytes: [Byte] = bodyPart.content.rawValue
        if let encoding = bodyPart.transferEncoding {
            switch encoding {
            case .base64:

                buffer.append(contentsOf: RFC_4648.Base64.encode(contentBytes).map(\.byte))

            case .quotedPrintable:

                buffer.append(contentsOf: RFC_2046.QuotedPrintable.encode(contentBytes))

            default:

                buffer.append(contentsOf: contentBytes)
            }
        } else {

            buffer.append(contentsOf: contentBytes)
        }
    }
}

extension RFC_2046.BodyPart {

    public init<Bytes: Swift.Collection>(binary bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        let byteArray = [Byte](bytes)

        let doubleCrlf: [Byte] = [
            ASCII.Code.cr.byte, ASCII.Code.lf.byte,
            ASCII.Code.cr.byte, ASCII.Code.lf.byte,
        ]
        let doubleLf: [Byte] = [ASCII.Code.lf.byte, ASCII.Code.lf.byte]

        var headerEndIndex: Int?
        var contentStartIndex: Int?

        if let idx = byteArray.firstIndex(of: doubleCrlf) {
            headerEndIndex = idx
            contentStartIndex = idx + doubleCrlf.count
        }

        else if let idx = byteArray.firstIndex(of: doubleLf) {
            headerEndIndex = idx
            contentStartIndex = idx + doubleLf.count
        }

        guard let headerEnd = headerEndIndex, let contentStart = contentStartIndex else {

            let headerBytes = byteArray
            let headers: Headers
            do throws(Headers.Error) {
                headers = try Headers(ascii: headerBytes)
            } catch {
                throw Error.invalidHeaders("\(error)")
            }
            self.init(headers: headers, content: Content([]))
            return
        }

        let headerBytes = Array(byteArray[..<headerEnd])
        let headers: Headers
        do throws(Headers.Error) {
            headers = try Headers(ascii: headerBytes)
        } catch {
            throw Error.invalidHeaders("\(error)")
        }

        let contentBytes: [Byte]
        if contentStart < byteArray.count {
            contentBytes = Array(byteArray[contentStart...])
        } else {
            contentBytes = []
        }

        guard
            let decoded = Content.decoding(
                contentBytes,
                transferEncoding: headers.contentTransferEncoding
            )
        else {
            throw Error.invalidTransferEncodedContent(
                "content is not valid \(headers.contentTransferEncoding?.rawValue ?? "raw")"
            )
        }

        self.init(headers: headers, content: Content(decoded))
    }
}

extension RFC_2046.BodyPart {

    public init(
        contentType: RFC_2045.ContentType,
        text: some StringProtocol
    ) throws(Headers.Error) {
        var headers = try Headers(ascii: [] as [Byte])
        headers.contentType = contentType

        headers.contentTransferEncoding = .eightBit

        self.init(
            headers: headers,
            content: Content(text)
        )
    }
}

extension RFC_2046.BodyPart {

    public var contentType: RFC_2045.ContentType? {
        headers.contentType
    }

    public var transferEncoding: RFC_2045.ContentTransferEncoding? {
        headers.contentTransferEncoding
    }
}

extension [Byte] {

    init(_ bodyPart: RFC_2046.BodyPart) {
        self = []
        RFC_2046.BodyPart.serialize(bodyPart, into: &self)
    }
}
