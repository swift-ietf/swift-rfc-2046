#if Coder
    public import Byte

    extension RFC_2046.Entity {

        public var content: [Byte]? {
            switch body {
            case .discrete(let bytes):
                RFC_2046.BodyPart.Content.decoding(bytes, transferEncoding: transferEncoding)
            case .multipart, .message:
                nil
            }
        }
    }
#endif
