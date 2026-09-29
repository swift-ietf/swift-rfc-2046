public import RFC_2046
import RFC_2045
import RFC_2183
import RFC_5322
import RFC_2045_Foundation_Integration
import RFC_2183_Foundation_Integration
import RFC_5322_Foundation_Integration

extension RFC_2046.BodyPart.Headers: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case contentDisposition
        case contentType
        case contentTransferEncoding
        case custom
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            contentDisposition: try container.decodeIfPresent(
                RFC_2183.ContentDisposition.self,
                forKey: .contentDisposition
            ),
            contentType: try container.decodeIfPresent(
                RFC_2045.ContentType.self,
                forKey: .contentType
            ),
            contentTransferEncoding: try container.decodeIfPresent(
                RFC_2045.ContentTransferEncoding.self,
                forKey: .contentTransferEncoding
            ),
            custom: try container.decodeIfPresent([RFC_5322.Header].self, forKey: .custom) ?? []
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(contentDisposition, forKey: .contentDisposition)
        try container.encodeIfPresent(contentType, forKey: .contentType)
        try container.encodeIfPresent(contentTransferEncoding, forKey: .contentTransferEncoding)
        try container.encode(custom, forKey: .custom)
    }
}
