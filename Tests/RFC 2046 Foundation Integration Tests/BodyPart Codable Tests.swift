import Byte
import Byte
import Foundation
import RFC_2045
import RFC_2046
import RFC_2046_Foundation_Integration
import Testing

@Suite
struct `BodyPart - Codable` {
    @Test
    func `Round-trip encoding preserves part`() throws {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8,
            contentTransferEncoding: .base64
        )
        let content = RFC_2046.BodyPart.Content("Hello, World!")
        let original = RFC_2046.BodyPart(headers: headers, content: content)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.self, from: data)

        #expect(decoded == original)
        #expect(decoded.content.description == original.content.description)
        #expect(decoded.contentType == original.contentType)
        #expect(decoded.transferEncoding == original.transferEncoding)
    }

    @Test
    func `Encoding preserves binary content`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .imageJPEG)
        let content = RFC_2046.BodyPart.Content(
            [0xFF, 0xD8, 0xFF, 0xE0].map(Byte.init(bitPattern:))
        )
        let original = RFC_2046.BodyPart(headers: headers, content: content)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.self, from: data)

        #expect(decoded.content.rawValue == original.content.rawValue)
    }
}
