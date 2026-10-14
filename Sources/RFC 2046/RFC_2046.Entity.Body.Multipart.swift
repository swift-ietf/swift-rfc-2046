public import Byte

extension RFC_2046.Entity.Body {

    public struct Multipart: Sendable, Hashable {

        public let subtype: RFC_2046.Multipart.Subtype

        public let preamble: [Byte]

        public let parts: [RFC_2046.Entity]

        public let epilogue: [Byte]

        public init(
            subtype: RFC_2046.Multipart.Subtype,
            preamble: [Byte],
            parts: [RFC_2046.Entity],
            epilogue: [Byte]
        ) {
            self.subtype = subtype
            self.preamble = preamble
            self.parts = parts
            self.epilogue = epilogue
        }
    }
}
