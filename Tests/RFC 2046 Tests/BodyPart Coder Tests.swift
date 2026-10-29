#if Coder
    import Byte
    import RFC_2045
    import RFC_2046
    import Testing

    @Suite
    struct `BodyPart - Serialization` {
        @Test
        func `Serialize produces headers plus content`() throws {
            let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
            let content = RFC_2046.BodyPart.Content("Hello, World!")
            let part = RFC_2046.BodyPart(headers: headers, content: content)

            let string = String(decoding: [Byte](part), as: UTF8.self)

            #expect(string.contains("Content-Type: text/plain; charset=UTF-8"))
            #expect(string.contains("\r\n\r\n"))
            #expect(string.hasSuffix("Hello, World!"))
        }

        @Test
        func `Serialize with transfer encoding`() throws {
            let headers = RFC_2046.BodyPart.Headers(
                contentType: .textPlainUTF8,
                contentTransferEncoding: .sevenBit
            )
            let part = RFC_2046.BodyPart(
                headers: headers,
                content: RFC_2046.BodyPart.Content("Hello")
            )

            let string = String(decoding: [Byte](part), as: UTF8.self)

            #expect(string.contains("Content-Transfer-Encoding: 7bit"))
            #expect(string.hasSuffix("Hello"))
        }

        @Test
        func `Serialize with base64 encoding applies encoding`() throws {
            let headers = RFC_2046.BodyPart.Headers(
                contentType: .textPlainUTF8,
                contentTransferEncoding: .base64
            )
            let part = RFC_2046.BodyPart(
                headers: headers,
                content: RFC_2046.BodyPart.Content("Hello, World!")
            )

            let string = String(decoding: [Byte](part), as: UTF8.self)

            #expect(string.contains("Content-Transfer-Encoding: base64"))
            #expect(string.hasSuffix("SGVsbG8sIFdvcmxkIQ=="))
        }

        @Test
        func `Serialize empty content`() throws {
            let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
            let part = RFC_2046.BodyPart(headers: headers, content: RFC_2046.BodyPart.Content([]))

            let string = String(decoding: [Byte](part), as: UTF8.self)

            #expect(string.contains("Content-Type:"))
            #expect(string.contains("\r\n\r\n"))
        }
    }

    @Suite
    struct `BodyPart - Parsing` {
        @Test
        func `Parse body part from raw bytes`() throws {
            let part = try RFC_2046.BodyPart(
                binary: [Byte](utf8: "Content-Type: text/plain\r\n\r\nHello!")
            )

            #expect(part.contentType?.type == "text")
            #expect(part.contentType?.subtype == "plain")
            #expect(part.content.description == "Hello!")
        }

        @Test
        func `Parse body part with LF line endings`() throws {
            let part = try RFC_2046.BodyPart(
                binary: [Byte](utf8: "Content-Type: text/plain\n\nHello!")
            )

            #expect(part.content.description == "Hello!")
        }

        @Test
        func `Parse body part with headers only`() throws {
            let part = try RFC_2046.BodyPart(binary: [Byte](utf8: "Content-Type: text/plain"))

            #expect(part.contentType?.type == "text")
            #expect(part.content.rawValue.isEmpty)
        }

        @Test
        func `Parse decodes base64 transfer-encoded content to canonical bytes`() throws {
            let part = try RFC_2046.BodyPart(
                binary: [Byte](utf8: "Content-Transfer-Encoding: base64\r\n\r\nSGVsbG8sIFdvcmxkIQ==")
            )

            #expect(part.content.rawValue == [Byte](utf8: "Hello, World!"))
        }

        @Test
        func `Malformed base64 content throws a typed error`() throws {
            #expect(throws: RFC_2046.BodyPart.Error.self) {
                _ = try RFC_2046.BodyPart(
                    binary: [Byte](utf8: "Content-Transfer-Encoding: base64\r\n\r\nnot!!valid@@base64")
                )
            }
        }
    }

    @Suite
    struct `BodyPart - Round-trip` {
        @Test
        func `Round-trip preserves simple part`() throws {
            let original = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("Hello, World!")
            )

            let parsed = try RFC_2046.BodyPart(binary: [Byte](original))

            #expect(parsed.headers == original.headers)
            #expect(parsed.content.rawValue == original.content.rawValue)
        }

        @Test
        func `Round-trip preserves binary content`() throws {
            let original = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .applicationOctetStream),
                content: RFC_2046.BodyPart.Content([Byte](utf8: "Hello"))
            )

            let parsed = try RFC_2046.BodyPart(binary: [Byte](original))

            #expect(parsed.content.rawValue == original.content.rawValue)
        }

        @Test
        func `Round-trip preserves empty content`() throws {
            let original = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content([])
            )

            let parsed = try RFC_2046.BodyPart(binary: [Byte](original))

            #expect(parsed.content.rawValue.isEmpty)
        }

        @Test
        func `Base64 part round-trips without double encoding`() throws {
            let payload: [Byte] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10].map(Byte.init(bitPattern:))
            let original = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .imageJPEG,
                    contentTransferEncoding: .base64
                ),
                content: RFC_2046.BodyPart.Content(payload)
            )

            let wire = [Byte](original)
            let reparsed = try RFC_2046.BodyPart(binary: wire)

            #expect(reparsed.content.rawValue == payload)
            #expect([Byte](reparsed) == wire)
        }
    }
#endif
