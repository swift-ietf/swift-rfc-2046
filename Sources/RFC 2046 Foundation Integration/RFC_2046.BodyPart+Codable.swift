public import RFC_2046

extension RFC_2046.BodyPart: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case headers
        case content
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            headers: try container.decode(RFC_2046.BodyPart.Headers.self, forKey: .headers),
            content: try container.decode(RFC_2046.BodyPart.Content.self, forKey: .content)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(headers, forKey: .headers)
        try container.encode(content, forKey: .content)
    }
}
