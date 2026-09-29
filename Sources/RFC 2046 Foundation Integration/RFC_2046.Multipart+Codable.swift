public import RFC_2046
import RFC_2045
import RFC_2045_Foundation_Integration

extension RFC_2046.Multipart: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case subtype
        case parts
        case boundary
        case preamble
        case epilogue
        case additionalParameters
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let subtype = try container.decode(RFC_2046.Multipart.Subtype.self, forKey: .subtype)
        let parts = try container.decode([RFC_2046.BodyPart].self, forKey: .parts)
        let boundary = try container.decode(RFC_2046.Boundary.self, forKey: .boundary)
        let preamble = try container.decodeIfPresent(String.self, forKey: .preamble)
        let epilogue = try container.decodeIfPresent(String.self, forKey: .epilogue)
        let additionalParameters =
            try container.decodeIfPresent(
                [RFC_2045.Parameter.Name: String].self,
                forKey: .additionalParameters
            ) ?? [:]

        do throws(RFC_2046.Multipart.Error) {
            try self.init(
                subtype: subtype,
                parts: parts,
                boundary: boundary,
                preamble: preamble,
                epilogue: epilogue,
                additionalParameters: additionalParameters
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: String(describing: error)
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(subtype, forKey: .subtype)
        try container.encode(parts, forKey: .parts)
        try container.encode(boundary, forKey: .boundary)
        try container.encodeIfPresent(preamble, forKey: .preamble)
        try container.encodeIfPresent(epilogue, forKey: .epilogue)
        try container.encode(additionalParameters, forKey: .additionalParameters)
    }
}
