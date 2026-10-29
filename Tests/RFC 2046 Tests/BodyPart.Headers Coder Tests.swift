#if Coder
    import Byte
    import RFC_2045
    import RFC_2046
    import RFC_2183
    import RFC_5322
    import Testing

    @Suite
    struct `BodyPart.Headers - Parsing from bytes` {
        @Test
        func `Parse empty bytes`() throws {
            let headers = try RFC_2046.BodyPart.Headers(ascii: [Byte]())

            #expect(headers.contentDisposition == nil)
            #expect(headers.contentType == nil)
            #expect(headers.contentTransferEncoding == nil)
            #expect(headers.custom.isEmpty)
        }

        @Test
        func `Parse Content-Type header`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](utf8: "Content-Type: text/plain; charset=UTF-8")
            )

            #expect(headers.contentType?.type == "text")
            #expect(headers.contentType?.subtype == "plain")
        }

        @Test
        func `Parse Content-Disposition header`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](utf8: "Content-Disposition: attachment; filename=\"document.pdf\"")
            )

            #expect(headers.contentDisposition != nil)
        }

        @Test
        func `Parse Content-Transfer-Encoding header`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](utf8: "Content-Transfer-Encoding: base64")
            )

            #expect(headers.contentTransferEncoding == .base64)
        }

        @Test
        func `Parse all standard headers with CRLF`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](
                    utf8: "Content-Type: text/plain; charset=UTF-8\r\n"
                        + "Content-Disposition: inline\r\n"
                        + "Content-Transfer-Encoding: 7bit"
                )
            )

            #expect(headers.contentType != nil)
            #expect(headers.contentDisposition != nil)
            #expect(headers.contentTransferEncoding != nil)
        }

        @Test
        func `Parse custom headers`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](utf8: "X-Custom-Header: custom-value\r\nX-Another: another-value")
            )

            try #expect(headers[.init("X-Custom-Header")] == "custom-value")
            try #expect(headers[.init("X-Another")] == "another-value")
        }

        @Test
        func `Invalid Content-Type is ignored`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](utf8: "Content-Type: invalid syntax")
            )

            #expect(headers.contentType == nil)
        }

        @Test
        func `Invalid Content-Transfer-Encoding is ignored`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](utf8: "Content-Transfer-Encoding: invalid-encoding")
            )

            #expect(headers.contentTransferEncoding == nil)
        }

        @Test
        func `Invalid header line without colon throws`() {
            #expect(throws: RFC_2046.BodyPart.Headers.Error.self) {
                _ = try RFC_2046.BodyPart.Headers(ascii: [Byte](utf8: "invalid header line"))
            }
        }

        @Test
        func `Empty header name throws`() {
            #expect(throws: RFC_2046.BodyPart.Headers.Error.self) {
                _ = try RFC_2046.BodyPart.Headers(ascii: [Byte](utf8: ": value"))
            }
        }
    }

    @Suite
    struct `BodyPart.Headers - Folded header lines` {
        @Test
        func `Folded Content-Type header is unfolded and parsed`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](utf8: "Content-Type: multipart/mixed;\r\n boundary=abc123\r\n")
            )

            #expect(headers.contentType?.type == "multipart")
            #expect(headers.contentType?.subtype == "mixed")
            #expect(headers.contentType?.parameters[.boundary] == "abc123")
        }

        @Test
        func `Tab-folded custom header unfolds into one header`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                ascii: [Byte](
                    utf8: "X-Custom: first\r\n\tsecond\r\nContent-Transfer-Encoding: 7bit\r\n"
                )
            )

            #expect(headers.contentTransferEncoding == .sevenBit)
            #expect(headers.custom.count == 1)
        }
    }

    @Suite
    struct `BodyPart.Headers - Byte serialization` {
        @Test
        func `Empty headers produce empty bytes`() {
            #expect([Byte](RFC_2046.BodyPart.Headers()).isEmpty)
        }

        @Test
        func `Content-Type is serialized`() {
            let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
            let string = String(decoding: [Byte](headers), as: UTF8.self)

            #expect(string.contains("Content-Type:"))
            #expect(string.contains("text/plain"))
        }

        @Test
        func `Content-Disposition is serialized`() {
            let headers = RFC_2046.BodyPart.Headers(contentDisposition: .inline())
            let string = String(decoding: [Byte](headers), as: UTF8.self)

            #expect(string.contains("Content-Disposition:"))
        }

        @Test
        func `Content-Transfer-Encoding is serialized`() {
            let headers = RFC_2046.BodyPart.Headers(contentTransferEncoding: .base64)
            let string = String(decoding: [Byte](headers), as: UTF8.self)

            #expect(string.contains("Content-Transfer-Encoding:"))
            #expect(string.contains("base64"))
        }

        @Test
        func `All headers are serialized`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                contentDisposition: .inline(),
                contentType: .textPlainUTF8,
                contentTransferEncoding: .sevenBit,
                custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
            )
            let string = String(decoding: [Byte](headers), as: UTF8.self)

            #expect(string.contains("Content-Type:"))
            #expect(string.contains("Content-Disposition:"))
            #expect(string.contains("Content-Transfer-Encoding:"))
            #expect(string.contains("X-Custom:"))
        }

        @Test
        func `Headers use CRLF line endings`() {
            let headers = RFC_2046.BodyPart.Headers(
                contentType: .textPlainUTF8,
                contentTransferEncoding: .base64
            )
            let string = String(decoding: [Byte](headers), as: UTF8.self)

            #expect(string.contains("\r\n"))
        }

        @Test
        func `Description renders the serialized headers`() {
            let headers = RFC_2046.BodyPart.Headers(contentTransferEncoding: .base64)

            #expect(headers.description == "Content-Transfer-Encoding: base64\r\n")
        }
    }

    @Suite
    struct `BodyPart.Headers - Round-trip serialization` {
        @Test
        func `Round-trip preserves Content-Type`() throws {
            let original = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
            let parsed = try RFC_2046.BodyPart.Headers(ascii: [Byte](original))

            #expect(parsed.contentType?.type == "text")
            #expect(parsed.contentType?.subtype == "plain")
        }

        @Test
        func `Round-trip preserves Content-Transfer-Encoding`() throws {
            let original = RFC_2046.BodyPart.Headers(contentTransferEncoding: .base64)
            let parsed = try RFC_2046.BodyPart.Headers(ascii: [Byte](original))

            #expect(parsed.contentTransferEncoding == .base64)
        }

        @Test
        func `Round-trip preserves custom headers`() throws {
            let original = try RFC_2046.BodyPart.Headers(
                custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
            )
            let parsed = try RFC_2046.BodyPart.Headers(ascii: [Byte](original))

            #expect(try parsed[.init("X-Custom")] == "value")
        }

        @Test
        func `Round-trip preserves all headers`() throws {
            let original = try RFC_2046.BodyPart.Headers(
                contentDisposition: .inline(),
                contentType: .textHTMLUTF8,
                contentTransferEncoding: .quotedPrintable,
                custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
            )
            let parsed = try RFC_2046.BodyPart.Headers(ascii: [Byte](original))

            #expect(parsed.contentDisposition != nil)
            #expect(parsed.contentType != nil)
            #expect(parsed.contentTransferEncoding == .quotedPrintable)
        }
    }

    @Suite
    struct `BodyPart.Headers - Subscript access` {
        @Test
        func `Get Content-Type via subscript`() {
            let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)

            #expect(headers[.contentType]?.contains("text/plain") == true)
        }

        @Test
        func `Get Content-Disposition via subscript`() {
            let headers = RFC_2046.BodyPart.Headers(contentDisposition: .inline())

            #expect(headers[.contentDisposition] != nil)
        }

        @Test
        func `Get Content-Transfer-Encoding via subscript`() {
            let headers = RFC_2046.BodyPart.Headers(contentTransferEncoding: .base64)

            #expect(headers[.contentTransferEncoding] == "base64")
        }

        @Test
        func `Get custom header via subscript`() throws {
            let headers = try RFC_2046.BodyPart.Headers(
                custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
            )

            #expect(try headers[.init("X-Custom")] == "value")
        }

        @Test
        func `Set Content-Type via subscript`() {
            var headers = RFC_2046.BodyPart.Headers()
            headers[.contentType] = "text/html"

            #expect(headers.contentType?.type == "text")
            #expect(headers.contentType?.subtype == "html")
        }

        @Test
        func `Set custom header via subscript`() throws {
            var headers = RFC_2046.BodyPart.Headers()
            headers[try .init("X-Custom")] = "value"

            #expect(headers[try .init("X-Custom")] == "value")
        }

        @Test
        func `Remove header via subscript`() {
            var headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
            headers[.contentType] = nil

            #expect(headers.contentType == nil)
        }
    }
#endif
