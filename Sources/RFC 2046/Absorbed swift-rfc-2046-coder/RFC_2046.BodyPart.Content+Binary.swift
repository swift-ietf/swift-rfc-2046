#if Coder
    import ASCII
    public import Binary
    public import Byte
    import RFC_2045
    import RFC_4648

    extension RFC_2046.BodyPart.Content: Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ content: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            buffer.append(contentsOf: content.rawValue)
        }
    }

    extension [Byte] {

        public init(_ content: RFC_2046.BodyPart.Content) {
            self = []
            RFC_2046.BodyPart.Content.serialize(content, into: &self)
        }
    }

    extension RFC_2046.BodyPart.Content {

        static func decoding(
            _ bytes: [Byte],
            transferEncoding: RFC_2045.ContentTransferEncoding?
        ) -> [Byte]? {
            switch transferEncoding {
            case .base64:
                var codes: [ASCII.Code] = []
                codes.reserveCapacity(bytes.count)
                for byte in bytes {
                    guard byte.bitPattern < 0x80 else { return nil }
                    codes.append(ASCII.Code(unchecked: byte))
                }
                return RFC_4648.Base64.decode(codes)

            case .quotedPrintable:
                return RFC_2046.QuotedPrintable.decode(bytes)

            default:
                return bytes
            }
        }

        static func encoding(
            _ bytes: [Byte],
            transferEncoding: RFC_2045.ContentTransferEncoding?
        ) -> [Byte] {
            switch transferEncoding {
            case .base64:
                return RFC_4648.Base64.encode(bytes).map(\.byte)

            case .quotedPrintable:
                return RFC_2046.QuotedPrintable.encode(bytes)

            default:
                return bytes
            }
        }
    }
#endif
