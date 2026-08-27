public import ASCII_Serializer
public import Binary_Serializable
import INCITS_4_1986
public import Parseable_ASCII
public import RFC_2045
public import RFC_2183
public import RFC_5322

private typealias Code = ASCII.Code

extension RFC_2046.BodyPart {

    public struct Headers: Hashable, Sendable, Codable {

        public var contentDisposition: RFC_2183.ContentDisposition?

        public var contentType: RFC_2045.ContentType?

        public var contentTransferEncoding: RFC_2045.ContentTransferEncoding?

        public var custom: [RFC_5322.Header]

        public init(
            contentDisposition: RFC_2183.ContentDisposition? = nil,
            contentType: RFC_2045.ContentType? = nil,
            contentTransferEncoding: RFC_2045.ContentTransferEncoding? = nil,
            custom: [RFC_5322.Header] = []
        ) {
            self.contentDisposition = contentDisposition
            self.contentType = contentType
            self.contentTransferEncoding = contentTransferEncoding
            self.custom = custom
        }
    }
}

extension RFC_2046.BodyPart.Headers: ASCII.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ headers: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        if let contentDisposition = headers.contentDisposition {
            for byte in "Content-Disposition".utf8 { buffer.append(ASCII.Code(byte)) }
            buffer.append(Code.colon)
            buffer.append(Code.space)
            RFC_2183.ContentDisposition.serialize(contentDisposition, into: &buffer)
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        if let contentType = headers.contentType {
            for byte in "Content-Type".utf8 { buffer.append(ASCII.Code(byte)) }
            buffer.append(Code.colon)
            buffer.append(Code.space)
            RFC_2045.ContentType.serialize(contentType, into: &buffer)
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        if let contentTransferEncoding = headers.contentTransferEncoding {
            for byte in "Content-Transfer-Encoding".utf8 { buffer.append(ASCII.Code(byte)) }
            buffer.append(Code.colon)
            buffer.append(Code.space)
            RFC_2045.ContentTransferEncoding.serialize(contentTransferEncoding, into: &buffer)
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }

        for header in headers.custom {
            RFC_5322.Header.Name.serialize(header.name, into: &buffer)
            buffer.append(Code.colon)
            buffer.append(Code.space)
            RFC_5322.Header.Value.serialize(header.value, into: &buffer)
            buffer.append(Code.cr)
            buffer.append(Code.lf)
        }
    }
}

extension RFC_2046.BodyPart.Headers: Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ headers: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        if let contentDisposition = headers.contentDisposition {
            buffer.append(contentsOf: [Byte]("Content-Disposition".utf8))
            buffer.append(Code.colon.byte)
            buffer.append(Code.space.byte)
            RFC_2183.ContentDisposition.serialize(contentDisposition, into: &buffer)
            buffer.append(Code.cr.byte)
            buffer.append(Code.lf.byte)
        }

        if let contentType = headers.contentType {
            buffer.append(contentsOf: [Byte]("Content-Type".utf8))
            buffer.append(Code.colon.byte)
            buffer.append(Code.space.byte)
            RFC_2045.ContentType.serialize(contentType, into: &buffer)
            buffer.append(Code.cr.byte)
            buffer.append(Code.lf.byte)
        }

        if let contentTransferEncoding = headers.contentTransferEncoding {
            buffer.append(contentsOf: [Byte]("Content-Transfer-Encoding".utf8))
            buffer.append(Code.colon.byte)
            buffer.append(Code.space.byte)
            RFC_2045.ContentTransferEncoding.serialize(contentTransferEncoding, into: &buffer)
            buffer.append(Code.cr.byte)
            buffer.append(Code.lf.byte)
        }

        for header in headers.custom {
            RFC_5322.Header.Name.serialize(header.name, into: &buffer)
            buffer.append(Code.colon.byte)
            buffer.append(Code.space.byte)
            RFC_5322.Header.Value.serialize(header.value, into: &buffer)
            buffer.append(Code.cr.byte)
            buffer.append(Code.lf.byte)
        }
    }
}

extension RFC_2046.BodyPart.Headers: ASCII.Parseable {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        var contentDisposition: RFC_2183.ContentDisposition?
        var contentType: RFC_2045.ContentType?
        var contentTransferEncoding: RFC_2045.ContentTransferEncoding?
        var customHeaders: [RFC_5322.Header] = []

        let space = ASCII.Code.space.byte
        let htab = ASCII.Code.htab.byte
        var logicalLines: [[Byte]] = []
        for line in RFC_2046.lines(of: [Byte](bytes)) where !line.isEmpty {
            if let first = line.first, first == space || first == htab,
                !logicalLines.isEmpty
            {
                logicalLines[logicalLines.count - 1].append(contentsOf: line)
            } else {
                logicalLines.append([Byte](line))
            }
        }

        for line in logicalLines {

            let header: RFC_5322.Header
            do throws(RFC_5322.Header.Error) {
                header = try RFC_5322.Header(ascii: line)
            } catch {
                throw Error.invalidHeaderLine(String(decoding: line, as: UTF8.self))
            }

            var valueBytes: [Byte] = []
            RFC_5322.Header.Value.serialize(header.value, into: &valueBytes)

            switch header.name {
            case .contentDisposition:
                do throws(RFC_2183.ContentDisposition.Error) {
                    contentDisposition = try RFC_2183.ContentDisposition(ascii: valueBytes)
                } catch {
                    contentDisposition = nil
                }

            case .contentType:
                do throws(RFC_2045.ContentType.Error) {
                    contentType = try RFC_2045.ContentType(ascii: valueBytes)
                } catch {
                    contentType = nil
                }

            case .contentTransferEncoding:
                do throws(RFC_2045.ContentTransferEncoding.Error) {
                    contentTransferEncoding = try RFC_2045.ContentTransferEncoding(
                        ascii: valueBytes
                    )
                } catch {
                    contentTransferEncoding = nil
                }

            default:
                customHeaders.append(header)
            }
        }

        self.init(
            contentDisposition: contentDisposition,
            contentType: contentType,
            contentTransferEncoding: contentTransferEncoding,
            custom: customHeaders
        )
    }
}

extension [Byte] {

    public init(_ headers: RFC_2046.BodyPart.Headers) {
        self = []
        RFC_2046.BodyPart.Headers.serialize(headers, into: &self)
    }
}

extension RFC_2046.BodyPart.Headers: CustomStringConvertible {

    public var description: String {
        var bytes: [Byte] = []
        RFC_2046.BodyPart.Headers.serialize(self, into: &bytes)
        return String(decoding: bytes, as: UTF8.self)
    }
}

extension RFC_2046.BodyPart.Headers {

    public subscript(_ headerName: RFC_5322.Header.Name) -> String? {
        get {
            switch headerName {
            case .contentDisposition:
                return contentDisposition.map(\.description)

            case .contentType:
                return contentType.map(\.description)

            case .contentTransferEncoding:
                return contentTransferEncoding.map(\.description)

            default:
                return custom[headerName]
            }
        }
        set {
            switch headerName {
            case .contentDisposition:
                contentDisposition = newValue.flatMap { value in
                    do throws(RFC_2183.ContentDisposition.Error) {
                        return try RFC_2183.ContentDisposition(ascii: [Byte](value.utf8))
                    } catch {
                        return nil
                    }
                }

            case .contentType:
                contentType = newValue.flatMap { value in
                    do throws(RFC_2045.ContentType.Error) {
                        return try RFC_2045.ContentType(ascii: [Byte](value.utf8))
                    } catch {
                        return nil
                    }
                }

            case .contentTransferEncoding:
                contentTransferEncoding = newValue.flatMap { value in
                    do throws(RFC_2045.ContentTransferEncoding.Error) {
                        return try RFC_2045.ContentTransferEncoding(ascii: [Byte](value.utf8))
                    } catch {
                        return nil
                    }
                }

            default:
                custom[headerName] = newValue
            }
        }
    }
}
