#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_2046.Multipart.Subtype: ASCII.Parseable {

        public init<Bytes: Swift::Collection>(ascii bytes: Bytes) throws(Error)
        where Bytes.Element == Byte {
            try self.init(String(decoding: bytes, as: UTF8.self))
        }
    }

    extension RFC_2046.Multipart.Subtype: ASCII.Serializable,
        Binary.Serializable
    {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ subtype: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            Scan.append(subtype.rawValue, into: &buffer)
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ subtype: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            Scan.append(subtype.rawValue, into: &buffer)
        }
    }

    extension [Byte] {

        public init(_ subtype: RFC_2046.Multipart.Subtype) {
            self = []
            RFC_2046.Multipart.Subtype.serialize(subtype, into: &self)
        }
    }
#endif
