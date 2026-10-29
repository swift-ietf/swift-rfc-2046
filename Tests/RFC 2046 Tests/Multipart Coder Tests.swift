#if Coder
    import Byte
    import RFC_2045
    import RFC_2046
    import Testing

    @Suite
    struct `Multipart - Delimiter recognition` {
        @Test
        func `Delimiter lines with trailing transport padding are recognized`() throws {
            let raw =
                "--simple-boundary \t \r\n"
                + "Content-Type: text/plain\r\n"
                + "\r\n"
                + "Hello\r\n"
                + "--simple-boundary--  \r\n"
            let boundary = try RFC_2046.Boundary("simple-boundary")
            let multipart = try RFC_2046.Multipart(binary: [Byte](utf8: raw), boundary: boundary)

            #expect(multipart.parts.count == 1)
            #expect(multipart.parts[0].content.rawValue == [Byte](utf8: "Hello"))
        }

        @Test
        func `Dash-boundary prefix followed by non-whitespace is not a delimiter`() throws {
            let raw =
                "--b\r\n"
                + "\r\n"
                + "--bogus is content, not a delimiter\r\n"
                + "--b--\r\n"
            let boundary = try RFC_2046.Boundary("b")
            let multipart = try RFC_2046.Multipart(binary: [Byte](utf8: raw), boundary: boundary)

            #expect(multipart.parts.count == 1)
            #expect(
                multipart.parts[0].content.rawValue
                    == [Byte](utf8: "--bogus is content, not a delimiter")
            )
        }
    }

    @Suite
    struct `Multipart - Byte-exact content` {
        @Test
        func `Bare CR and LF bytes inside part content are preserved exactly`() throws {
            let payload: [Byte] = [Byte](utf8: "A\nB\rC")
            var raw: [Byte] = [Byte](utf8: "--b\r\nContent-Type: application/octet-stream\r\n\r\n")
            raw.append(contentsOf: payload)
            raw.append(contentsOf: [Byte](utf8: "\r\n--b--\r\n"))

            let boundary = try RFC_2046.Boundary("b")
            let multipart = try RFC_2046.Multipart(binary: raw, boundary: boundary)

            #expect(multipart.parts.count == 1)
            #expect(multipart.parts[0].content.rawValue == payload)
        }

        @Test
        func `Round-trip preserves binary content containing lone terminators`() throws {
            let payload: [Byte] = [0x00, 0x0A, 0x0D, 0x41, 0x0D, 0x0A, 0x42, 0x0A].map(
                Byte.init(bitPattern:)
            )
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .applicationOctetStream),
                content: RFC_2046.BodyPart.Content(payload)
            )
            let boundary = try RFC_2046.Boundary("xyz-boundary")
            let multipart = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [part],
                boundary: boundary
            )

            let wire = [Byte](multipart)
            let reparsed = try RFC_2046.Multipart(binary: wire, boundary: boundary)

            #expect(reparsed.parts.count == 1)
            #expect(reparsed.parts[0].content.rawValue == payload)
        }

        @Test
        func `Multipart round-trips transfer-encoded parts without double encoding`() throws {
            let binaryPayload: [Byte] = [0x00, 0x01, 0xFE, 0xFF].map(Byte.init(bitPattern:))
            let base64Part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .applicationOctetStream,
                    contentTransferEncoding: .base64
                ),
                content: RFC_2046.BodyPart.Content(binaryPayload)
            )
            let quotedPayload: [Byte] = [Byte](utf8: "a=b") + [Byte(bitPattern: 0x0F)]
            let quotedPart = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .textPlainUTF8,
                    contentTransferEncoding: .quotedPrintable
                ),
                content: RFC_2046.BodyPart.Content(quotedPayload)
            )
            let boundary = try RFC_2046.Boundary("rt-boundary")
            let original = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [base64Part, quotedPart],
                boundary: boundary
            )

            let wire = [Byte](original)
            let reparsed = try RFC_2046.Multipart(binary: wire, boundary: boundary)

            #expect(reparsed.parts.count == 2)
            #expect(reparsed.parts[0].content.rawValue == binaryPayload)
            #expect(reparsed.parts[1].content.rawValue == quotedPayload)
            #expect([Byte](reparsed) == wire)
        }
    }

    @Suite
    struct `Multipart - Coder witness` {
        @Test
        func `Coder round-trips a serialized multipart body`() throws {
            let boundary = try RFC_2046.Boundary("----=_Part_12345")
            let original = try RFC_2046.Multipart(
                subtype: .alternative,
                parts: [
                    RFC_2046.BodyPart(
                        headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                        content: RFC_2046.BodyPart.Content("Hello!")
                    ),
                    RFC_2046.BodyPart(
                        headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                        content: RFC_2046.BodyPart.Content("World!")
                    ),
                ],
                boundary: boundary
            )

            let coder = RFC_2046.Multipart.coder(boundary: boundary, subtype: .alternative)

            var wire: [Byte] = []
            try coder.serialize(original, into: &wire)

            var input = wire[...]
            let parsed = try coder.parse(&input)

            #expect(parsed.parts.count == 2)
            #expect(parsed.boundary == boundary)
            #expect(parsed.parts.first?.content.description == "Hello!")
            #expect(parsed.parts.last?.content.description == "World!")
        }

        @Test
        func `Coder carries the boundary and subtype it was built with`() throws {
            let boundary = try RFC_2046.Boundary("b0undary")
            let coder = RFC_2046.Multipart.coder(boundary: boundary, subtype: .related)

            #expect(coder.boundary == boundary)
            #expect(coder.subtype == .related)
        }
    }
#endif
