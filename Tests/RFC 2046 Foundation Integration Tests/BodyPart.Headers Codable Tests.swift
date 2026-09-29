import Foundation
import RFC_2045
import RFC_2046
import RFC_2046_Foundation_Integration
import RFC_2183
import RFC_5322
import Testing

@Suite
struct `BodyPart.Headers - Codable` {
    @Test
    func `Round-trip encoding preserves headers`() throws {
        let original = try RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textPlainUTF8,
            contentTransferEncoding: .base64,
            custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.Headers.self, from: data)

        #expect(decoded.contentDisposition == original.contentDisposition)
        #expect(decoded.contentType == original.contentType)
        #expect(decoded.contentTransferEncoding == original.contentTransferEncoding)
        #expect(decoded.custom == original.custom)
    }

    @Test
    func `Empty headers encode and decode correctly`() throws {
        let original = RFC_2046.BodyPart.Headers()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.Headers.self, from: data)

        #expect(decoded == original)
    }
}
