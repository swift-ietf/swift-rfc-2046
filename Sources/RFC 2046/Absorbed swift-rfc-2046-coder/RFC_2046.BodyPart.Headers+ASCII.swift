#if Coder
    public import ASCII
    public import Binary
    public import Byte
    import RFC_2045
    import RFC_2183
    public import RFC_5322

    extension RFC_2046.BodyPart.Headers: ASCII.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ headers: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            if let contentDisposition = headers.contentDisposition {
                Scan.append("Content-Disposition: ", into: &buffer)
                RFC_2183.ContentDisposition.serialize(contentDisposition, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }

            if let contentType = headers.contentType {
                Scan.append("Content-Type: ", into: &buffer)
                RFC_2045.ContentType.serialize(contentType, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }

            if let contentTransferEncoding = headers.contentTransferEncoding {
                Scan.append("Content-Transfer-Encoding: ", into: &buffer)
                RFC_2045.ContentTransferEncoding.serialize(contentTransferEncoding, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }

            for header in headers.custom {
                Scan.append(header.name.rawValue, into: &buffer)
                Scan.append(": ", into: &buffer)
                Scan.append(header.value.rawValue, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }
        }
    }

    extension RFC_2046.BodyPart.Headers: Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ headers: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            if let contentDisposition = headers.contentDisposition {
                Scan.append("Content-Disposition: ", into: &buffer)
                RFC_2183.ContentDisposition.serialize(contentDisposition, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }

            if let contentType = headers.contentType {
                Scan.append("Content-Type: ", into: &buffer)
                RFC_2045.ContentType.serialize(contentType, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }

            if let contentTransferEncoding = headers.contentTransferEncoding {
                Scan.append("Content-Transfer-Encoding: ", into: &buffer)
                RFC_2045.ContentTransferEncoding.serialize(contentTransferEncoding, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }

            for header in headers.custom {
                Scan.append(header.name.rawValue, into: &buffer)
                Scan.append(": ", into: &buffer)
                Scan.append(header.value.rawValue, into: &buffer)
                Scan.append("\r\n", into: &buffer)
            }
        }
    }

    extension RFC_2046.BodyPart.Headers: ASCII.Parseable {

        public init<Bytes: Swift::Collection>(ascii bytes: Bytes) throws(Error)
        where Bytes.Element == Byte {
            var contentDisposition: RFC_2183.ContentDisposition?
            var contentType: RFC_2045.ContentType?
            var contentTransferEncoding: RFC_2045.ContentTransferEncoding?
            var customHeaders: [RFC_5322.Header] = []

            let space = ASCII.Code.space.byte
            let htab = ASCII.Code.htab.byte
            var logicalLines: [[Byte]] = []
            for line in Lines.split([Byte](bytes)) where !line.isEmpty {
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

                let valueBytes: [Byte] = [Byte](utf8: header.value.rawValue)

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
            String(decoding: [Byte](self), as: UTF8.self)
        }
    }

    extension RFC_2046.BodyPart.Headers {

        public subscript(_ headerName: RFC_5322.Header.Name) -> String? {
            get {
                switch headerName {
                case .contentDisposition:
                    return contentDisposition.map { value in
                        var bytes: [Byte] = []
                        RFC_2183.ContentDisposition.serialize(value, into: &bytes)
                        return String(decoding: bytes, as: UTF8.self)
                    }

                case .contentType:
                    return contentType.map { value in
                        var bytes: [Byte] = []
                        RFC_2045.ContentType.serialize(value, into: &bytes)
                        return String(decoding: bytes, as: UTF8.self)
                    }

                case .contentTransferEncoding:
                    return contentTransferEncoding.map { value in
                        var bytes: [Byte] = []
                        RFC_2045.ContentTransferEncoding.serialize(value, into: &bytes)
                        return String(decoding: bytes, as: UTF8.self)
                    }

                default:
                    return custom[headerName]
                }
            }
            set {
                switch headerName {
                case .contentDisposition:
                    contentDisposition = newValue.flatMap { value in
                        do throws(RFC_2183.ContentDisposition.Error) {
                            return try RFC_2183.ContentDisposition(ascii: [Byte](utf8: value))
                        } catch {
                            return nil
                        }
                    }

                case .contentType:
                    contentType = newValue.flatMap { value in
                        do throws(RFC_2045.ContentType.Error) {
                            return try RFC_2045.ContentType(ascii: [Byte](utf8: value))
                        } catch {
                            return nil
                        }
                    }

                case .contentTransferEncoding:
                    contentTransferEncoding = newValue.flatMap { value in
                        do throws(RFC_2045.ContentTransferEncoding.Error) {
                            return try RFC_2045.ContentTransferEncoding(ascii: [Byte](utf8: value))
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
#endif
