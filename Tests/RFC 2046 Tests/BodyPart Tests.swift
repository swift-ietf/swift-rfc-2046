import Foundation
import RFC_2045
import RFC_2183
import RFC_5322
import Testing

@testable import RFC_2046

// MARK: - BodyPart Core Initialization

@Suite
struct `BodyPart - Core initialization` {
    @Test
    func `Initialize with headers and Content`() throws {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let content = RFC_2046.BodyPart.Content([72, 101, 108, 108, 111])  // "Hello"

        let part = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(part.headers == headers)
        #expect([UInt8](part.content) == [72, 101, 108, 108, 111])
    }

    @Test
    func `Initialize with empty Content`() throws {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let content = RFC_2046.BodyPart.Content([])

        let part = RFC_2046.BodyPart(headers: headers, content: content)

        #expect([UInt8](part.content).isEmpty)
    }

    @Test
    func `Content from text string`() throws {
        let content = try RFC_2046.BodyPart.Content("Hello, World!")

        #expect([UInt8](content) == Array("Hello, World!".utf8))
        #expect(content.description == "Hello, World!")
    }

    @Test
    func `Content from bytes`() throws {
        let bytes: [UInt8] = [72, 101, 108, 108, 111]
        let content = RFC_2046.BodyPart.Content(bytes)

        #expect([UInt8](content) == bytes)
        #expect(content.description == "Hello")
    }
}

// MARK: - Content Type

@Suite
struct `BodyPart Content - Serialization` {
    @Test
    func `Content serializes to bytes`() throws {
        let content = try RFC_2046.BodyPart.Content("Hello")
        let bytes = [UInt8](content)

        #expect(bytes == Array("Hello".utf8))
    }

    @Test
    func `Content text accessor returns string for valid UTF-8`() throws {
        let content = try RFC_2046.BodyPart.Content("Hello 🌍")

        #expect(content.description == "Hello 🌍")
    }

    @Test
    func `Content rawValue contains bytes`() throws {
        let bytes: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]
        let content = RFC_2046.BodyPart.Content(bytes)

        #expect(content.rawValue == bytes)
    }
}

// MARK: - BodyPart Serialization

@Suite
struct `BodyPart - Serialization` {
    @Test
    func `Serialize produces headers plus content`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = try RFC_2046.BodyPart.Content("Hello, World!")
        let part = RFC_2046.BodyPart(headers: headers, content: content)

        let serialized = [UInt8](part)
        let string = String(decoding: serialized, as: UTF8.self)

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
        let content = try RFC_2046.BodyPart.Content("Hello")
        let part = RFC_2046.BodyPart(headers: headers, content: content)

        let serialized = [UInt8](part)
        let string = String(decoding: serialized, as: UTF8.self)

        #expect(string.contains("Content-Transfer-Encoding: 7bit"))
        #expect(string.hasSuffix("Hello"))
    }

    @Test
    func `Serialize with base64 encoding applies encoding`() throws {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8,
            contentTransferEncoding: .base64
        )
        let content = try RFC_2046.BodyPart.Content("Hello, World!")
        let part = RFC_2046.BodyPart(headers: headers, content: content)

        let serialized = [UInt8](part)
        let string = String(decoding: serialized, as: UTF8.self)

        #expect(string.contains("Content-Transfer-Encoding: base64"))
        #expect(string.hasSuffix("SGVsbG8sIFdvcmxkIQ=="))
    }

    @Test
    func `Serialize empty content`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = RFC_2046.BodyPart.Content([])
        let part = RFC_2046.BodyPart(headers: headers, content: content)

        let serialized = [UInt8](part)
        let string = String(decoding: serialized, as: UTF8.self)

        #expect(string.contains("Content-Type:"))
        #expect(string.contains("\r\n\r\n"))
    }
}

// MARK: - BodyPart Parsing

@Suite
struct `BodyPart - Parsing` {
    @Test
    func `Parse body part from raw bytes`() throws {
        let bytes = Array("Content-Type: text/plain\r\n\r\nHello!".utf8)
        let part = try RFC_2046.BodyPart(ascii: bytes)

        #expect(part.contentType?.type == "text")
        #expect(part.contentType?.subtype == "plain")
        #expect(part.content.description == "Hello!")
    }

    @Test
    func `Parse body part with LF line endings`() throws {
        let bytes = Array("Content-Type: text/plain\n\nHello!".utf8)
        let part = try RFC_2046.BodyPart(ascii: bytes)

        #expect(part.content.description == "Hello!")
    }

    @Test
    func `Parse body part with headers only`() throws {
        let bytes = Array("Content-Type: text/plain".utf8)
        let part = try RFC_2046.BodyPart(ascii: bytes)

        #expect(part.contentType?.type == "text")
        #expect([UInt8](part.content).isEmpty)
    }
}

// MARK: - Round-Trip (Isomorphism)

@Suite
struct `BodyPart - Round-trip` {
    @Test
    func `Round-trip preserves simple part`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = try RFC_2046.BodyPart.Content("Hello, World!")
        let original = RFC_2046.BodyPart(headers: headers, content: content)

        let serialized = [UInt8](original)
        let parsed = try RFC_2046.BodyPart(ascii: serialized)

        #expect(parsed.headers == original.headers)
        #expect([UInt8](parsed.content) == [UInt8](original.content))
    }

    @Test
    func `Round-trip preserves binary content`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .applicationOctetStream)
        let content = RFC_2046.BodyPart.Content([0x48, 0x65, 0x6C, 0x6C, 0x6F])
        let original = RFC_2046.BodyPart(headers: headers, content: content)

        let serialized = [UInt8](original)
        let parsed = try RFC_2046.BodyPart(ascii: serialized)

        #expect([UInt8](parsed.content) == [UInt8](original.content))
    }

    @Test
    func `Round-trip preserves empty content`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = RFC_2046.BodyPart.Content([])
        let original = RFC_2046.BodyPart(headers: headers, content: content)

        let serialized = [UInt8](original)
        let parsed = try RFC_2046.BodyPart(ascii: serialized)

        #expect([UInt8](parsed.content).isEmpty)
    }
}

// MARK: - Protocol Conformance

@Suite
struct `BodyPart - Hashable and Equatable` {
    @Test
    func `Same parts are equal`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = try RFC_2046.BodyPart.Content("Hello")

        let a = RFC_2046.BodyPart(headers: headers, content: content)
        let b = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(a == b)
    }

    @Test
    func `Different content makes parts not equal`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)

        let a = try RFC_2046.BodyPart(headers: headers, content: RFC_2046.BodyPart.Content("Hello"))
        let b = try RFC_2046.BodyPart(headers: headers, content: RFC_2046.BodyPart.Content("World"))

        #expect(a != b)
    }

    @Test
    func `Same parts have same hash`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = try RFC_2046.BodyPart.Content("Hello")

        let a = RFC_2046.BodyPart(headers: headers, content: content)
        let b = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(a.hashValue == b.hashValue)
    }
}

@Suite
struct `BodyPart - Codable` {
    @Test
    func `Round-trip encoding preserves part`() throws {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8,
            contentTransferEncoding: .base64
        )
        let content = try RFC_2046.BodyPart.Content("Hello, World!")
        let original = RFC_2046.BodyPart(headers: headers, content: content)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.self, from: data)

        #expect(decoded == original)
        #expect(decoded.content.description == original.content.description)
        #expect(decoded.contentType == original.contentType)
        #expect(decoded.transferEncoding == original.transferEncoding)
    }

    @Test
    func `Encoding preserves binary content`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .imageJPEG)
        let content = RFC_2046.BodyPart.Content([0xFF, 0xD8, 0xFF, 0xE0])
        let original = RFC_2046.BodyPart(headers: headers, content: content)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.self, from: data)

        #expect([UInt8](decoded.content) == [UInt8](original.content))
    }
}

@Suite
struct `BodyPart - Sendable` {
    @Test
    func `BodyPart can be sent across concurrency domains`() async throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = try RFC_2046.BodyPart.Content("Hello")
        let part = RFC_2046.BodyPart(headers: headers, content: content)

        let result = await Task {
            part.content.description
        }.value

        #expect(result == "Hello")
    }
}
