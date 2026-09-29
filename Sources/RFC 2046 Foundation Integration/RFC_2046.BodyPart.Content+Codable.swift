import Byte
public import RFC_2046

extension RFC_2046.BodyPart.Content: Encodable, Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let octets = try container.decode([UInt8].self)
        self.init(octets.map(Byte.init(bitPattern:)))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.map(\.bitPattern))
    }
}
