public import RFC_2045

extension RFC_2046 {

    public struct Entity: Sendable, Hashable {

        public let fields: [RFC_2046.Entity.Field]

        public let contentType: RFC_2045.ContentType

        public let body: RFC_2046.Entity.Body

        public init(
            fields: [RFC_2046.Entity.Field],
            contentType: RFC_2045.ContentType,
            body: RFC_2046.Entity.Body
        ) {
            self.fields = fields
            self.contentType = contentType
            self.body = body
        }
    }
}
