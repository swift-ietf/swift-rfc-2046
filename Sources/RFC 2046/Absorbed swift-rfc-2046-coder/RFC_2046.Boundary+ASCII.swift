#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_2046.Boundary: ASCII.Parseable {

        public init<Bytes: Swift::Collection>(ascii bytes: Bytes) throws(Error)
        where Bytes.Element == Byte {
            for byte in bytes {
                guard byte.bitPattern < 0x80 else {
                    throw Error.notASCII(String(decoding: bytes, as: UTF8.self))
                }
            }
            try self.init(String(decoding: bytes, as: UTF8.self))
        }
    }

    extension RFC_2046.Boundary: ASCII.Serializable,
        Binary.Serializable
    {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ boundary: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            Scan.append(boundary.rawValue, into: &buffer)
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ boundary: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            Scan.append(boundary.rawValue, into: &buffer)
        }
    }

    extension [Byte] {

        public init(_ boundary: RFC_2046.Boundary) {
            self = []
            RFC_2046.Boundary.serialize(boundary, into: &self)
        }
    }
#endif
