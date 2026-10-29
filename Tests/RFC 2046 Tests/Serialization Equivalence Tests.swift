#if Coder
    import ASCII
    import Binary
    import Byte
    import RFC_2045
    import RFC_2046
    import RFC_2183
    import Testing

    @Suite
    struct `ASCII and binary serialization agree` {
        @Test func `Boundary verbs agree`() throws {
            let value = try RFC_2046.Boundary("----=_Part_12345_Custom")
            var ascii: [ASCII.Code] = []
            RFC_2046.Boundary.serialize(value, into: &ascii)
            var wire: [Byte] = []
            RFC_2046.Boundary.serialize(value, into: &wire)

            #expect(ascii.map(\.byte) == wire)
            #expect(String(decoding: wire, as: UTF8.self) == "----=_Part_12345_Custom")
        }

        @Test func `Multipart.Subtype verbs agree`() {
            let value = RFC_2046.Multipart.Subtype.alternative
            var ascii: [ASCII.Code] = []
            RFC_2046.Multipart.Subtype.serialize(value, into: &ascii)
            var wire: [Byte] = []
            RFC_2046.Multipart.Subtype.serialize(value, into: &wire)

            #expect(ascii.map(\.byte) == wire)
            #expect(String(decoding: wire, as: UTF8.self) == "alternative")
        }

        @Test func `BodyPart.Headers verbs agree`() {
            let value = RFC_2046.BodyPart.Headers(
                contentDisposition: .inline(),
                contentType: .textPlainUTF8,
                contentTransferEncoding: .base64
            )
            var ascii: [ASCII.Code] = []
            RFC_2046.BodyPart.Headers.serialize(value, into: &ascii)
            var wire: [Byte] = []
            RFC_2046.BodyPart.Headers.serialize(value, into: &wire)

            #expect(ascii.map(\.byte) == wire)
        }
    }

    @Suite
    struct `Binary serialization round-trips` {
        @Test func `Content round-trips through the binary verb`() {
            let bytes: [Byte] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10].map(Byte.init(bitPattern:))
            let original = RFC_2046.BodyPart.Content(bytes)
            var wire: [Byte] = []
            RFC_2046.BodyPart.Content.serialize(original, into: &wire)

            #expect(wire == bytes)
            #expect(RFC_2046.BodyPart.Content(binary: wire) == original)
        }

        @Test func `Boundary round-trips through the ASCII verbs`() throws {
            let original = try RFC_2046.Boundary("----=_Part_12345")

            #expect(try RFC_2046.Boundary(ascii: [Byte](original)) == original)
        }

        @Test func `Multipart.Subtype round-trips through the ASCII verbs`() throws {
            let original = RFC_2046.Multipart.Subtype.formData

            #expect(try RFC_2046.Multipart.Subtype(ascii: [Byte](original)) == original)
        }

        @Test func `Headers round-trip through the byte verb`() throws {
            let original = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
            var wire: [Byte] = []
            RFC_2046.BodyPart.Headers.serialize(original, into: &wire)

            #expect(try RFC_2046.BodyPart.Headers(ascii: wire).contentType == original.contentType)
        }

        @Test func `BodyPart round-trips through the byte verb`() throws {
            let original = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("Hello, World!")
            )
            let reparsed = try RFC_2046.BodyPart(binary: [Byte](original))

            #expect(reparsed.content.rawValue == original.content.rawValue)
            #expect(reparsed.contentType == original.contentType)
        }
    }
#endif
