import Foundation
import RFC_2045
@testable import RFC_2046
import RFC_2183
import RFC_5322
import Testing

// MARK: - Headers Initialization

@Suite
struct `BodyPart.Headers - Initialization` {
    @Test
    func `Default initialization creates empty headers`() {
        let headers = RFC_2046.BodyPart.Headers()
        #expect(headers.contentDisposition == nil)
        #expect(headers.contentType == nil)
        #expect(headers.contentTransferEncoding == nil)
        #expect(headers.custom.isEmpty)
    }

    @Test
    func `Initialization with all parameters`() throws {
        let headers = try RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textPlainUTF8,
            contentTransferEncoding: .sevenBit,
            custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
        )

        #expect(headers.contentDisposition == .inline())
        #expect(headers.contentType == .textPlainUTF8)
        #expect(headers.contentTransferEncoding == .sevenBit)
        #expect(try headers[.init("X-Custom")] == "value")
    }

    @Test
    func `Initialization with only content type`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textHTMLUTF8
        )

        #expect(headers.contentDisposition == nil)
        #expect(headers.contentType == .textHTMLUTF8)
        #expect(headers.contentTransferEncoding == nil)
        #expect(headers.custom.isEmpty)
    }

    @Test
    func `Initialization with custom headers only`() throws {
        let headers = try RFC_2046.BodyPart.Headers(
            custom: [
                RFC_5322.Header(name: .init("X-Custom-1"), value: .init("value1")),
                RFC_5322.Header(name: .init("X-Custom-2"), value: .init("value2")),
            ]
        )

        #expect(headers.contentDisposition == nil)
        #expect(headers.contentType == nil)
        #expect(headers.contentTransferEncoding == nil)
        #expect(headers.custom.count == 2)
    }
}

// MARK: - Headers Parsing from Bytes

@Suite
struct `BodyPart.Headers - Parsing from bytes` {
    @Test
    func `Parse empty bytes`() throws {
        let headers = try RFC_2046.BodyPart.Headers(ascii: [UInt8]())

        #expect(headers.contentDisposition == nil)
        #expect(headers.contentType == nil)
        #expect(headers.contentTransferEncoding == nil)
        #expect(headers.custom.isEmpty)
    }

    @Test
    func `Parse Content-Type header`() throws {
        let bytes = Array("Content-Type: text/plain; charset=UTF-8".utf8)
        let headers = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(headers.contentType?.type == "text")
        #expect(headers.contentType?.subtype == "plain")
    }

    @Test
    func `Parse Content-Disposition header`() throws {
        let bytes = Array("Content-Disposition: attachment; filename=\"document.pdf\"".utf8)
        let headers = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(headers.contentDisposition != nil)
    }

    @Test
    func `Parse Content-Transfer-Encoding header`() throws {
        let bytes = Array("Content-Transfer-Encoding: base64".utf8)
        let headers = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(headers.contentTransferEncoding == .base64)
    }

    @Test
    func `Parse all standard headers with CRLF`() throws {
        let headerString = "Content-Type: text/plain; charset=UTF-8\r\nContent-Disposition: inline\r\nContent-Transfer-Encoding: 7bit"
        let bytes = Array(headerString.utf8)
        let headers = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(headers.contentType != nil)
        #expect(headers.contentDisposition != nil)
        #expect(headers.contentTransferEncoding != nil)
    }

    @Test
    func `Parse custom headers`() throws {
        let headerString = "X-Custom-Header: custom-value\r\nX-Another: another-value"
        let bytes = Array(headerString.utf8)
        let headers = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(try headers[.init("X-Custom-Header")] == "custom-value")
        #expect(try headers[.init("X-Another")] == "another-value")
    }

    @Test
    func `Parse mixed standard and custom headers`() throws {
        let headerString = "Content-Type: text/plain\r\nX-Custom: value"
        let bytes = Array(headerString.utf8)
        let headers = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(headers.contentType != nil)
        #expect(try headers[.init("X-Custom")] == "value")
    }

    @Test
    func `Invalid Content-Type is ignored`() throws {
        let bytes = Array("Content-Type: invalid syntax".utf8)
        let headers = try RFC_2046.BodyPart.Headers(ascii: bytes)

        // Invalid content type should be ignored, not crash
        #expect(headers.contentType == nil)
    }

    @Test
    func `Invalid Content-Transfer-Encoding is ignored`() throws {
        let bytes = Array("Content-Transfer-Encoding: invalid-encoding".utf8)
        let headers = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(headers.contentTransferEncoding == nil)
    }

    @Test
    func `Invalid header line without colon throws`() {
        #expect(throws: RFC_2046.BodyPart.Headers.Error.self) {
            _ = try RFC_2046.BodyPart.Headers(ascii: Array("invalid header line".utf8))
        }
    }

    @Test
    func `Empty header name throws`() {
        #expect(throws: RFC_2046.BodyPart.Headers.Error.self) {
            _ = try RFC_2046.BodyPart.Headers(ascii: Array(": value".utf8))
        }
    }
}

// MARK: - Headers from RFC_5322.Header Array

@Suite
struct `BodyPart.Headers - Initialization from header array` {
    @Test
    func `Empty array creates empty headers`() throws {
        let headers = try RFC_2046.BodyPart.Headers([])

        #expect(headers.contentDisposition == nil)
        #expect(headers.contentType == nil)
        #expect(headers.contentTransferEncoding == nil)
        #expect(headers.custom.isEmpty)
    }

    @Test
    func `Content-Type header is recognized`() throws {
        let headerArray: [RFC_5322.Header] = try [
            RFC_5322.Header(name: .contentType, value: .init("text/plain; charset=UTF-8")),
        ]
        let headers = try RFC_2046.BodyPart.Headers(headerArray)

        #expect(headers.contentType?.type == "text")
        #expect(headers.contentType?.subtype == "plain")
    }

    @Test
    func `Content-Disposition header is recognized`() throws {
        let headerArray: [RFC_5322.Header] = try [
            RFC_5322.Header(name: .contentDisposition, value: .init("attachment; filename=\"document.pdf\"")),
        ]
        let headers = try RFC_2046.BodyPart.Headers(headerArray)

        #expect(headers.contentDisposition != nil)
    }

    @Test
    func `Content-Transfer-Encoding header is recognized`() throws {
        let headerArray: [RFC_5322.Header] = try [
            RFC_5322.Header(name: .contentTransferEncoding, value: .init("base64")),
        ]
        let headers = try RFC_2046.BodyPart.Headers(headerArray)

        #expect(headers.contentTransferEncoding == .base64)
    }

    @Test
    func `Custom headers are preserved`() throws {
        let headerArray: [RFC_5322.Header] = try [
            RFC_5322.Header(name: .init("X-Custom-Header"), value: .init("custom-value")),
            RFC_5322.Header(name: .init("X-Another"), value: .init("another-value")),
        ]
        let headers = try RFC_2046.BodyPart.Headers(headerArray)

        #expect(try headers[.init("X-Custom-Header")] == "custom-value")
        #expect(try headers[.init("X-Another")] == "another-value")
    }

    @Test
    func `Mixed standard and custom headers`() throws {
        let headerArray: [RFC_5322.Header] = try [
            RFC_5322.Header(name: .contentType, value: .init("text/plain")),
            RFC_5322.Header(name: .init("X-Custom"), value: .init("value")),
        ]
        let headers = try RFC_2046.BodyPart.Headers(headerArray)

        #expect(headers.contentType != nil)
        #expect(try headers[.init("X-Custom")] == "value")
    }
}

// MARK: - Headers Serialization

@Suite
struct `BodyPart.Headers - Byte serialization` {
    @Test
    func `Empty headers produce empty bytes`() {
        let headers = RFC_2046.BodyPart.Headers()
        let bytes = [UInt8](headers)
        #expect(bytes.isEmpty)
    }

    @Test
    func `Content-Type is serialized`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let bytes = [UInt8](headers)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("Content-Type:"))
        #expect(string.contains("text/plain"))
    }

    @Test
    func `Content-Disposition is serialized`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentDisposition: .inline()
        )
        let bytes = [UInt8](headers)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("Content-Disposition:"))
    }

    @Test
    func `Content-Transfer-Encoding is serialized`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentTransferEncoding: .base64
        )
        let bytes = [UInt8](headers)
        let string = String(decoding: bytes, as: UTF8.self)

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
        let bytes = [UInt8](headers)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("Content-Type:"))
        #expect(string.contains("Content-Disposition:"))
        #expect(string.contains("Content-Transfer-Encoding:"))
        #expect(string.contains("X-Custom:"))
    }

    @Test
    func `Custom headers are serialized`() throws {
        let headers = try RFC_2046.BodyPart.Headers(
            custom: [
                RFC_5322.Header(name: .init("X-Header-1"), value: .init("value1")),
                RFC_5322.Header(name: .init("X-Header-2"), value: .init("value2")),
            ]
        )
        let bytes = [UInt8](headers)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("X-Header-1:"))
        #expect(string.contains("value1"))
        #expect(string.contains("X-Header-2:"))
        #expect(string.contains("value2"))
    }

    @Test
    func `Headers use CRLF line endings`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8,
            contentTransferEncoding: .base64
        )
        let bytes = [UInt8](headers)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("\r\n"))
    }
}

// MARK: - Headers Round-trip

@Suite
struct `BodyPart.Headers - Round-trip serialization` {
    @Test
    func `Round-trip preserves Content-Type`() throws {
        let original = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )

        let bytes = [UInt8](original)
        let parsed = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(parsed.contentType?.type == "text")
        #expect(parsed.contentType?.subtype == "plain")
    }

    @Test
    func `Round-trip preserves Content-Transfer-Encoding`() throws {
        let original = RFC_2046.BodyPart.Headers(
            contentTransferEncoding: .base64
        )

        let bytes = [UInt8](original)
        let parsed = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(parsed.contentTransferEncoding == .base64)
    }

    @Test
    func `Round-trip preserves custom headers`() throws {
        let original = try RFC_2046.BodyPart.Headers(
            custom: [
                RFC_5322.Header(name: .init("X-Custom"), value: .init("value")),
            ]
        )

        let bytes = [UInt8](original)
        let parsed = try RFC_2046.BodyPart.Headers(ascii: bytes)

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

        let bytes = [UInt8](original)
        let parsed = try RFC_2046.BodyPart.Headers(ascii: bytes)

        #expect(parsed.contentDisposition != nil)
        #expect(parsed.contentType != nil)
        #expect(parsed.contentTransferEncoding == .quotedPrintable)
        #expect(try parsed[.init("X-Custom")] == "value")
    }
}

// MARK: - Subscript Access

@Suite
struct `BodyPart.Headers - Subscript access` {
    @Test
    func `Get Content-Type via subscript`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )

        #expect(headers[.contentType] != nil)
        #expect(headers[.contentType]?.contains("text/plain") == true)
    }

    @Test
    func `Get Content-Disposition via subscript`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentDisposition: .inline()
        )

        #expect(headers[.contentDisposition] != nil)
    }

    @Test
    func `Get Content-Transfer-Encoding via subscript`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentTransferEncoding: .base64
        )

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
        try headers[.init("X-Custom")] = "value"

        #expect(try headers[.init("X-Custom")] == "value")
    }

    @Test
    func `Remove header via subscript`() {
        var headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        headers[.contentType] = nil

        #expect(headers.contentType == nil)
    }
}

// MARK: - Convenience Constructors

@Suite
struct `BodyPart.Headers - Form data text field` {
    @Test
    func `Form data text field creates correct headers`() {
        let headers = RFC_2046.BodyPart.Headers.formDataTextField(name: "username")

        #expect(headers.contentDisposition != nil)
        #expect(headers.contentType == nil)
        #expect(headers.contentTransferEncoding == nil)
    }

    @Test
    func `Form data text field with special characters`() {
        let headers = RFC_2046.BodyPart.Headers.formDataTextField(name: "user-name")

        #expect(headers.contentDisposition != nil)
    }
}

@Suite
struct `BodyPart.Headers - Form data file` {
    @Test
    func `Form data file creates correct headers`() throws {
        let headers = try RFC_2046.BodyPart.Headers.formDataFile(
            name: "avatar",
            filename: .init("photo.jpg")
        )

        #expect(headers.contentDisposition != nil)
        #expect(headers.contentType == nil) // No default content type
    }

    @Test
    func `Form data file with content type`() throws {
        let headers = try RFC_2046.BodyPart.Headers.formDataFile(
            name: "avatar",
            filename: .init("photo.jpg"),
            contentType: .imageJPEG
        )

        #expect(headers.contentDisposition != nil)
        #expect(headers.contentType != nil)
        #expect(headers.contentType?.type == "image")
        #expect(headers.contentType?.subtype == "jpeg")
    }

    @Test
    func `Form data file with filename containing spaces`() throws {
        let headers = try RFC_2046.BodyPart.Headers.formDataFile(
            name: "document",
            filename: .init("my document.pdf")
        )

        #expect(headers.contentDisposition != nil)
    }

    @Test
    func `Form data file with special characters in filename`() throws {
        let headers = try RFC_2046.BodyPart.Headers.formDataFile(
            name: "file",
            filename: .init("document-v1.2.pdf")
        )

        #expect(headers.contentDisposition != nil)
    }
}

// MARK: - Headers Protocol Conformance

@Suite
struct `BodyPart.Headers - Hashable and Equatable` {
    @Test
    func `Same headers are equal`() {
        let a = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let b = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        #expect(a == b)
    }

    @Test
    func `Different headers are not equal`() {
        let a = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let b = RFC_2046.BodyPart.Headers(contentType: .textHTMLUTF8)
        #expect(a != b)
    }

    @Test
    func `Headers with different custom values are not equal`() throws {
        let a = try RFC_2046.BodyPart.Headers(custom: [RFC_5322.Header(name: .init("X-A"), value: .init("1"))])
        let b = try RFC_2046.BodyPart.Headers(custom: [RFC_5322.Header(name: .init("X-A"), value: .init("2"))])
        #expect(a != b)
    }

    @Test
    func `Same headers have same hash`() {
        let a = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let b = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        #expect(a.hashValue == b.hashValue)
    }
}

@Suite
struct `BodyPart.Headers - Codable` {
    @Test
    func `Round-trip encoding preserves headers`() throws {
        let original = try RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textPlainUTF8,
            contentTransferEncoding: .base64,
            custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.Headers.self, from: data)

        #expect(decoded.contentDisposition == original.contentDisposition)
        #expect(decoded.contentType == original.contentType)
        #expect(decoded.contentTransferEncoding == original.contentTransferEncoding)
        #expect(decoded.custom == original.custom)
    }

    @Test
    func `Empty headers encode and decode correctly`() throws {
        let original = RFC_2046.BodyPart.Headers()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.BodyPart.Headers.self, from: data)

        #expect(decoded == original)
    }
}

@Suite
struct `BodyPart.Headers - Sendable conformance` {
    @Test
    func `Headers can be sent across concurrency domains`() async {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )

        let result = await Task {
            headers.contentType
        }.value

        #expect(result == .textPlainUTF8)
    }
}
