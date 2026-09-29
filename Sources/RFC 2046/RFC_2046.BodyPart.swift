public import RFC_2045

extension RFC_2046 {

    public struct BodyPart: Hashable, Sendable {

        public let headers: Headers

        public let content: Content

        public init(headers: Headers, content: Content) {
            self.headers = headers
            self.content = content
        }
    }
}

extension RFC_2046.BodyPart {

    public init(
        contentType: RFC_2045.ContentType,
        text: some StringProtocol
    ) {
        self.init(
            headers: Headers(
                contentType: contentType,
                contentTransferEncoding: .eightBit
            ),
            content: Content(text)
        )
    }
}

extension RFC_2046.BodyPart {

    public var contentType: RFC_2045.ContentType? {
        headers.contentType
    }

    public var transferEncoding: RFC_2045.ContentTransferEncoding? {
        headers.contentTransferEncoding
    }
}
