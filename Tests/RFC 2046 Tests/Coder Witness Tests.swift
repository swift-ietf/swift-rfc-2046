#if Coder
    import Byte
    import Coder
    import Cursor
    import RFC_2045
    import RFC_2046
    import Testing

    @Suite
    struct `Boundary - Coder witness` {
        @Test
        func `Coder parses a boundary up to the line terminator`() throws {
            var input = [Byte](utf8: "----=_Part_12345\r\nrest")[...]
            let boundary = try RFC_2046.Boundary.coder.parse(&input)

            #expect(boundary.rawValue == "----=_Part_12345")
        }

        @Test
        func `Coder serializes a boundary verbatim`() throws {
            let boundary = try RFC_2046.Boundary("----=_Part_12345")
            var buffer: [Byte] = []
            try RFC_2046.Boundary.coder.serialize(boundary, into: &buffer)

            #expect(String(decoding: buffer, as: UTF8.self) == "----=_Part_12345")
        }

        @Test
        func `Coder rejects an empty boundary`() {
            var input = [Byte](utf8: "\r\n")[...]

            #expect(throws: RFC_2046.Boundary.Error.self) {
                _ = try RFC_2046.Boundary.coder.parse(&input)
            }
        }
    }

    @Suite
    struct `Multipart.Subtype - Coder witness` {
        @Test
        func `Coder round-trips a subtype`() throws {
            var buffer: [Byte] = []
            try RFC_2046.Multipart.Subtype.coder.serialize(.formData, into: &buffer)

            var input = buffer[...]
            #expect(try RFC_2046.Multipart.Subtype.coder.parse(&input) == .formData)
        }
    }

    @Suite
    struct `BodyPart.Headers - Coder witness` {
        @Test
        func `Coder round-trips a header block`() throws {
            let headers = RFC_2046.BodyPart.Headers(
                contentType: .textPlainUTF8,
                contentTransferEncoding: .base64
            )

            var buffer: [Byte] = []
            try RFC_2046.BodyPart.Headers.coder.serialize(headers, into: &buffer)

            var input = buffer[...]
            let parsed = try RFC_2046.BodyPart.Headers.coder.parse(&input)

            #expect(parsed.contentType == headers.contentType)
            #expect(parsed.contentTransferEncoding == headers.contentTransferEncoding)
        }
    }

    @Suite
    struct `BodyPart - Coder witness` {
        @Test
        func `Coder round-trips a body part`() throws {
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("Hello, World!")
            )

            var buffer: [Byte] = []
            try RFC_2046.BodyPart.coder.serialize(part, into: &buffer)

            var input = buffer[...]
            let parsed = try RFC_2046.BodyPart.coder.parse(&input)

            #expect(parsed.content.rawValue == part.content.rawValue)
            #expect(parsed.contentType == part.contentType)
        }
    }
#endif
