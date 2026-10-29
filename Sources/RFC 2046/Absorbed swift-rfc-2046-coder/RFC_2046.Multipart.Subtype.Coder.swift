#if Coder
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_2046.Multipart.Subtype {

        public struct Coder<
            Input: Cursor.`Protocol`<Byte, Never>,
            Buffer: RangeReplaceableCollection<Byte>
        >: Coding {

            public typealias Output = RFC_2046.Multipart.Subtype

            public typealias Failure = RFC_2046.Multipart.Subtype.Error

            public init() {}

            public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
                let start = input.checkpoint
                let bytes = Scan.run(&input) { byte in
                    let code = byte.bitPattern
                    return code > 0x20 && code != 0x3B
                }
                do throws(Failure) {
                    return try RFC_2046.Multipart.Subtype(ascii: bytes)
                } catch {
                    input.seek(to: start)
                    throw error
                }
            }

            public borrowing func serialize(
                _ output: Output,
                into buffer: inout Buffer
            ) throws(Failure) {
                Scan.append(output.rawValue, into: &buffer)
            }
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }
#endif
