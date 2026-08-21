import Testing

@testable import RFC_2046

extension RFC_2046.BodyPart.Content {
    @Suite
    struct Unit {

        @Test
        func `Parse decodes base64 transfer-encoded content to canonical bytes`() throws {
            let raw = [Byte](
                "Content-Transfer-Encoding: base64\r\n\r\nSGVsbG8sIFdvcmxkIQ==".utf8
            )
            let part = try RFC_2046.BodyPart(binary: raw)
            #expect(part.content.rawValue == [Byte]("Hello, World!".utf8))
        }

        @Test
        func `Base64 part round-trips without double encoding`() throws {
            let payload: [Byte] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]
            let original = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .init(__unchecked: (), type: "image", subtype: "jpeg"),
                    contentTransferEncoding: .base64
                ),
                content: RFC_2046.BodyPart.Content(payload)
            )
            let wire = [Byte](original)
            let reparsed = try RFC_2046.BodyPart(binary: wire)
            #expect(reparsed.content.rawValue == payload)
            #expect([Byte](reparsed) == wire)
        }

        @Test
        func `Multipart round-trips transfer-encoded parts without double encoding`() throws {
            let binaryPayload: [Byte] = [0x00, 0x01, 0xFE, 0xFF]
            let base64Part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .init(
                        __unchecked: (),
                        type: "application",
                        subtype: "octet-stream"
                    ),
                    contentTransferEncoding: .base64
                ),
                content: RFC_2046.BodyPart.Content(binaryPayload)
            )
            let quotedPart = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .textPlainUTF8,
                    contentTransferEncoding: .quotedPrintable
                ),
                content: RFC_2046.BodyPart.Content([Byte]("a=b".utf8) + [0x0F])
            )
            let boundary = try RFC_2046.Boundary("rt-boundary")
            let original = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [base64Part, quotedPart],
                boundary: boundary
            )
            let wire = [Byte](original)
            let reparsed = try RFC_2046.Multipart.parse(
                from: wire,
                parser: RFC_2046.Multipart.Parser(boundary: boundary)
            )
            #expect(reparsed.parts.count == 2)
            #expect(reparsed.parts[0].content.rawValue == binaryPayload)
            #expect(reparsed.parts[1].content.rawValue == [Byte]("a=b".utf8) + [0x0F])
            #expect([Byte](reparsed) == wire)
        }

        @Test
        func `Malformed base64 content throws a typed error`() throws {
            let raw = [Byte](
                "Content-Transfer-Encoding: base64\r\n\r\nnot!!valid@@base64".utf8
            )
            #expect(throws: RFC_2046.BodyPart.Error.self) {
                _ = try RFC_2046.BodyPart(binary: raw)
            }
        }
    }
}
