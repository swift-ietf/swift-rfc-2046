import Byte
import Byte
import RFC_2045
import RFC_2046
import Testing

@Suite
struct `BodyPart - Core initialization` {
    @Test
    func `Initialize with headers and Content`() throws {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let content = RFC_2046.BodyPart.Content([Byte](utf8: "Hello"))

        let part = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(part.headers == headers)
        #expect(part.content.rawValue == [Byte](utf8: "Hello"))
    }

    @Test
    func `Initialize with empty Content`() throws {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let content = RFC_2046.BodyPart.Content([])

        let part = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(part.content.rawValue.isEmpty)
    }

    @Test
    func `Initialize from a content type and text`() throws {
        let part = RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Hello, World!")

        #expect(part.contentType == .textPlainUTF8)
        #expect(part.transferEncoding == .eightBit)
        #expect(part.content.rawValue == [Byte](utf8: "Hello, World!"))
    }
}

@Suite
struct `BodyPart Content - Value semantics` {
    @Test
    func `Content from text string`() throws {
        let content = RFC_2046.BodyPart.Content("Hello, World!")

        #expect(content.rawValue == [Byte](utf8: "Hello, World!"))
        #expect(content.description == "Hello, World!")
    }

    @Test
    func `Content from bytes`() throws {
        let bytes: [Byte] = [Byte](utf8: "Hello")
        let content = RFC_2046.BodyPart.Content(bytes)

        #expect(content.rawValue == bytes)
        #expect(content.description == "Hello")
    }

    @Test
    func `Content from any byte collection`() throws {
        let bytes: [Byte] = [Byte](utf8: "Hello")
        let content = RFC_2046.BodyPart.Content(binary: bytes[...])

        #expect(content.rawValue == bytes)
    }

    @Test
    func `Content text accessor returns string for valid UTF-8`() throws {
        let content = RFC_2046.BodyPart.Content("Hello 🌍")

        #expect(content.description == "Hello 🌍")
    }
}

@Suite
struct `BodyPart - Hashable and Equatable` {
    @Test
    func `Same parts are equal`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = RFC_2046.BodyPart.Content("Hello")

        let a = RFC_2046.BodyPart(headers: headers, content: content)
        let b = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(a == b)
    }

    @Test
    func `Different content makes parts not equal`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)

        let a = RFC_2046.BodyPart(headers: headers, content: RFC_2046.BodyPart.Content("Hello"))
        let b = RFC_2046.BodyPart(headers: headers, content: RFC_2046.BodyPart.Content("World"))

        #expect(a != b)
    }
}
