import Testing
import RFC_2045
import RFC_2183
@testable import RFC_2046
import Foundation

// MARK: - BodyPart Initialization

@Suite
struct `BodyPart - Initialization with typed headers` {

    @Test
    func `Initialize with headers and binary content`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let content: [UInt8] = [72, 101, 108, 108, 111] // "Hello"

        let part = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(part.typedHeaders == headers)
        #expect(part.content == content)
    }

    @Test
    func `Initialize with headers and text content`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let text = "Hello, World!"

        let part = RFC_2046.BodyPart(headers: headers, text: text)

        #expect(part.typedHeaders == headers)
        #expect(part.textContent == text)
    }

    @Test
    func `Initialize with empty text content`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )

        let part = RFC_2046.BodyPart(headers: headers, text: "")

        #expect(part.textContent == "")
        #expect(part.content.isEmpty)
    }

    @Test
    func `Initialize with empty binary content`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )

        let part = RFC_2046.BodyPart(headers: headers, content: [])

        #expect(part.content.isEmpty)
    }
}

@Suite
struct `BodyPart - Initialization with content type` {

    @Test
    func `Initialize with content type and text`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        #expect(part.contentType == .textPlainUTF8)
        #expect(part.textContent == "Hello")
    }

    @Test
    func `Initialize with content type and binary content`() {
        let content: [UInt8] = [0x48, 0x65, 0x6c, 0x6c, 0x6f]
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            content: content
        )

        #expect(part.contentType == .textPlainUTF8)
        #expect(part.content == content)
    }

    @Test
    func `Initialize with transfer encoding`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .base64,
            text: "Hello"
        )

        #expect(part.contentType == .textPlainUTF8)
        #expect(part.transferEncoding == .base64)
    }

    @Test
    func `Initialize with additional headers`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            additionalHeaders: ["X-Custom": "value"],
            text: "Hello"
        )

        #expect(part.contentType == .textPlainUTF8)
        #expect(part.headers["X-Custom"] == "value")
    }

    @Test
    func `Initialize with all parameters`() {
        let part = RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            transferEncoding: .quotedPrintable,
            additionalHeaders: ["X-Custom": "value"],
            text: "<h1>Hello</h1>"
        )

        #expect(part.contentType == .textHTMLUTF8)
        #expect(part.transferEncoding == .quotedPrintable)
        #expect(part.headers["X-Custom"] == "value")
        #expect(part.textContent == "<h1>Hello</h1>")
    }
}

// MARK: - BodyPart Content Access

@Suite
struct `BodyPart - Content access` {

    @Test
    func `Text content is accessible`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello, World!"
        )

        #expect(part.textContent == "Hello, World!")
    }

    @Test
    func `Binary content is accessible`() {
        let content: [UInt8] = [72, 101, 108, 108, 111]
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            content: content
        )

        #expect(part.content == content)
    }

    @Test
    func `UTF-8 text can be decoded from binary content`() {
        let text = "Hello, World! 🌍"
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: text
        )

        #expect(part.textContent == text)
    }

    @Test
    func `Multiline text is preserved`() {
        let text = """
        Line 1
        Line 2
        Line 3
        """

        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: text
        )

        #expect(part.textContent == text)
    }

    @Test
    func `Empty text content returns empty string`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: ""
        )

        #expect(part.textContent == "")
    }
}

// MARK: - BodyPart Header Access

@Suite
struct `BodyPart - Header access` {

    @Test
    func `Content-Type is accessible`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        #expect(part.contentType == .textPlainUTF8)
    }

    @Test
    func `Transfer encoding is accessible`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .base64,
            text: "Hello"
        )

        #expect(part.transferEncoding == .base64)
    }

    @Test
    func `Headers dictionary contains all headers`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .sevenBit,
            additionalHeaders: ["X-Custom": "value"],
            text: "Hello"
        )

        #expect(part.headers["Content-Type"] != nil)
        #expect(part.headers["Content-Transfer-Encoding"] != nil)
        #expect(part.headers["X-Custom"] == "value")
    }

    @Test
    func `Missing transfer encoding returns nil`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        #expect(part.transferEncoding == nil)
    }
}

// MARK: - BodyPart Rendering

@Suite
struct `BodyPart - Rendering headers` {

    @Test
    func `Render headers produces sorted output`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .sevenBit,
            text: "Hello"
        )

        let rendered = part.renderHeaders()

        // Headers should be sorted alphabetically
        #expect(rendered.contains("Content-Transfer-Encoding: 7bit"))
        #expect(rendered.contains("Content-Type: text/plain; charset=UTF-8"))
    }

    @Test
    func `Render headers includes custom headers`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            additionalHeaders: ["X-Custom": "value"],
            text: "Hello"
        )

        let rendered = part.renderHeaders()

        #expect(rendered.contains("X-Custom: value"))
    }

    @Test
    func `Render headers uses CRLF separator`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .sevenBit,
            text: "Hello"
        )

        let rendered = part.renderHeaders()

        #expect(rendered.contains("\r\n"))
    }

    @Test
    func `Empty headers render as empty string`() {
        let headers = RFC_2046.BodyPart.Headers()
        let part = RFC_2046.BodyPart(headers: headers, text: "Hello")

        let rendered = part.renderHeaders()

        #expect(rendered.isEmpty)
    }
}

@Suite
struct `BodyPart - Rendering content` {

    @Test
    func `Render plain text content`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello, World!"
        )

        let rendered = part.renderContent()

        #expect(rendered == "Hello, World!")
    }

    @Test
    func `Render 7bit encoded content`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .sevenBit,
            text: "Hello"
        )

        let rendered = part.renderContent()

        #expect(rendered == "Hello")
    }

    @Test
    func `Render base64 encoded content`() {
        let text = "Hello, World!"
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .base64,
            text: text
        )

        let rendered = part.renderContent()

        // Should be base64 encoded
        #expect(rendered != text)
        #expect(rendered == "SGVsbG8sIFdvcmxkIQ==")
    }

    @Test
    func `Render empty content`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: ""
        )

        let rendered = part.renderContent()

        #expect(rendered.isEmpty)
    }

    @Test
    func `Render content with no transfer encoding`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let part = RFC_2046.BodyPart(headers: headers, text: "Hello")

        let rendered = part.renderContent()

        #expect(rendered == "Hello")
    }

    @Test
    func `Render binary content without encoding`() {
        let content: [UInt8] = [72, 101, 108, 108, 111] // "Hello"
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            content: content
        )

        let rendered = part.renderContent()

        #expect(rendered == "Hello")
    }

    @Test
    func `Render multiline text preserves line breaks`() {
        let text = "Line 1\r\nLine 2\r\nLine 3"
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: text
        )

        let rendered = part.renderContent()

        #expect(rendered == text)
    }
}

// MARK: - BodyPart Protocol Conformance

@Suite
struct `BodyPart - Hashable and Equatable` {

    @Test
    func `Same parts are equal`() {
        let a = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )
        let b = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        #expect(a == b)
    }

    @Test
    func `Different content makes parts not equal`() {
        let a = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )
        let b = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "World"
        )

        #expect(a != b)
    }

    @Test
    func `Different headers make parts not equal`() {
        let a = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )
        let b = RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            text: "Hello"
        )

        #expect(a != b)
    }

    @Test
    func `Same parts have same hash`() {
        let a = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )
        let b = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        #expect(a.hashValue == b.hashValue)
    }
}

@Suite
struct `BodyPart - Codable` {

    @Test
    func `Round-trip encoding preserves part`() throws {
        let original = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .base64,
            additionalHeaders: ["X-Custom": "value"],
            text: "Hello, World!"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.self, from: data)

        #expect(decoded == original)
        #expect(decoded.textContent == original.textContent)
        #expect(decoded.contentType == original.contentType)
        #expect(decoded.transferEncoding == original.transferEncoding)
    }

    @Test
    func `Encoding preserves binary content`() throws {
        let content: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0] // JPEG header
        let original = RFC_2046.BodyPart(
            contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
            content: content
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.self, from: data)

        #expect(decoded.content == original.content)
    }

    @Test
    func `Encoding preserves empty content`() throws {
        let original = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: ""
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.self, from: data)

        #expect(decoded.content.isEmpty)
    }
}

@Suite
struct `BodyPart - Sendable conformance` {

    @Test
    func `BodyPart can be sent across concurrency domains`() async {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let result = await Task {
            part.textContent
        }.value

        #expect(result == "Hello")
    }
}

// MARK: - BodyPart Edge Cases

@Suite
struct `BodyPart - Edge cases` {

    @Test
    func `Unicode content is preserved`() {
        let text = "Hello 世界 🌍"
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: text
        )

        #expect(part.textContent == text)
    }

    @Test
    func `Large text content is handled`() {
        let text = String(repeating: "Hello, World! ", count: 1000)
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: text
        )

        #expect(part.textContent == text)
        #expect(part.content.count > 10000)
    }

    @Test
    func `Binary content with null bytes`() {
        let content: [UInt8] = [0x00, 0x01, 0x02, 0x00, 0xFF]
        let part = RFC_2046.BodyPart(
            contentType: RFC_2045.ContentType(type: "application", subtype: "octet-stream"),
            content: content
        )

        #expect(part.content == content)
    }

    @Test
    func `Content with only whitespace`() {
        let text = "   \t\n\r\n   "
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: text
        )

        #expect(part.textContent == text)
    }
}
