import Testing

@testable import RFC_2046

extension RFC_2046.Multipart.Parser {
    @Suite
    struct `Edge Case` {

        @Test
        func `Delimiter lines with trailing transport padding are recognized`() throws {
            let raw =
                "--simple-boundary \t \r\n"
                + "Content-Type: text/plain\r\n"
                + "\r\n"
                + "Hello\r\n"
                + "--simple-boundary--  \r\n"
            let boundary = try RFC_2046.Boundary("simple-boundary")
            let multipart = try RFC_2046.Multipart.parse(
                from: [Byte](raw.utf8),
                parser: RFC_2046.Multipart.Parser(boundary: boundary)
            )
            #expect(multipart.parts.count == 1)
            #expect(multipart.parts[0].content.rawValue == [Byte]("Hello".utf8))
        }

        @Test
        func `Dash-boundary prefix followed by non-whitespace is not a delimiter`() throws {
            let raw =
                "--b\r\n"
                + "\r\n"
                + "--bogus is content, not a delimiter\r\n"
                + "--b--\r\n"
            let boundary = try RFC_2046.Boundary("b")
            let multipart = try RFC_2046.Multipart.parse(
                from: [Byte](raw.utf8),
                parser: RFC_2046.Multipart.Parser(boundary: boundary)
            )
            #expect(multipart.parts.count == 1)
            #expect(
                multipart.parts[0].content.rawValue
                    == [Byte]("--bogus is content, not a delimiter".utf8)
            )
        }
    }
}

extension RFC_2046.Multipart.Parser {
    @Suite
    struct Unit {

        @Test
        func `Bare CR and LF bytes inside part content are preserved exactly`() throws {
            let payload: [Byte] = [Byte]("A\nB\rC".utf8)
            var raw: [Byte] = [Byte]("--b\r\nContent-Type: application/octet-stream\r\n\r\n".utf8)
            raw.append(contentsOf: payload)
            raw.append(contentsOf: [Byte]("\r\n--b--\r\n".utf8))

            let boundary = try RFC_2046.Boundary("b")
            let multipart = try RFC_2046.Multipart.parse(
                from: raw,
                parser: RFC_2046.Multipart.Parser(boundary: boundary)
            )
            #expect(multipart.parts.count == 1)
            #expect(multipart.parts[0].content.rawValue == payload)
        }

        @Test
        func `Round-trip preserves binary content containing lone terminators`() throws {
            let payload: [Byte] = [0x00, 0x0A, 0x0D, 0x41, 0x0D, 0x0A, 0x42, 0x0A]
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .init(
                        __unchecked: (),
                        type: "application",
                        subtype: "octet-stream"
                    )
                ),
                content: RFC_2046.BodyPart.Content(payload)
            )
            let boundary = try RFC_2046.Boundary("xyz-boundary")
            let multipart = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [part],
                boundary: boundary
            )
            let wire = [Byte](multipart)
            let reparsed = try RFC_2046.Multipart.parse(
                from: wire,
                parser: RFC_2046.Multipart.Parser(boundary: boundary)
            )
            #expect(reparsed.parts.count == 1)
            #expect(reparsed.parts[0].content.rawValue == payload)
        }
    }
}
