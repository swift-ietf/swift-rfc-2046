#if Coder
    import Binary
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_2046.Multipart {

        public struct Coder<
            Input: Cursor.`Protocol`<Byte, Never>,
            Buffer: RangeReplaceableCollection<Byte>
        >: Coding {

            public typealias Output = RFC_2046.Multipart

            public typealias Failure = RFC_2046.Multipart.Error

            public let boundary: RFC_2046.Boundary

            public let subtype: RFC_2046.Multipart.Subtype

            public init(
                boundary: RFC_2046.Boundary,
                subtype: RFC_2046.Multipart.Subtype = .mixed
            ) {
                self.boundary = boundary
                self.subtype = subtype
            }

            public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
                let start = input.checkpoint
                let bytes = Scan.rest(&input)
                do throws(Failure) {
                    return try RFC_2046.Multipart(
                        binary: bytes,
                        boundary: boundary,
                        subtype: subtype
                    )
                } catch {
                    input.seek(to: start)
                    throw error
                }
            }

            public borrowing func serialize(
                _ output: Output,
                into buffer: inout Buffer
            ) throws(Failure) {
                RFC_2046.Multipart.serialize(output, into: &buffer)
            }
        }

        public static func coder(
            boundary: RFC_2046.Boundary,
            subtype: RFC_2046.Multipart.Subtype = .mixed
        ) -> Coder<ArraySlice<Byte>, [Byte]> {
            .init(boundary: boundary, subtype: subtype)
        }
    }
#endif
