public import RFC_2045
public import RFC_2183
public import RFC_5322

extension RFC_2046.BodyPart {

    public struct Headers: Hashable, Sendable {

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
