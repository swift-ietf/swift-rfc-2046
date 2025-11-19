import Testing
import Foundation
import RFC_2045
import RFC_2183
@testable import RFC_2046

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
    func `Initialization with all parameters`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textPlainUTF8,
            contentTransferEncoding: .sevenBit,
            custom: ["X-Custom": "value"]
        )

        #expect(headers.contentDisposition == .inline())
        #expect(headers.contentType == .textPlainUTF8)
        #expect(headers.contentTransferEncoding == .sevenBit)
        #expect(headers.custom["X-Custom"] == "value")
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
    func `Initialization with custom headers only`() {
        let headers = RFC_2046.BodyPart.Headers(
            custom: [
                "X-Custom-1": "value1",
                "X-Custom-2": "value2"
            ]
        )

        #expect(headers.contentDisposition == nil)
        #expect(headers.contentType == nil)
        #expect(headers.contentTransferEncoding == nil)
        #expect(headers.custom.count == 2)
    }
}

// MARK: - Headers Parsing

@Suite
struct `BodyPart.Headers - Parsing from dictionary` {

    @Test
    func `Parse empty dictionary`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [:])

        #expect(headers.contentDisposition == nil)
        #expect(headers.contentType == nil)
        #expect(headers.contentTransferEncoding == nil)
        #expect(headers.custom.isEmpty)
    }

    @Test
    func `Parse Content-Type header`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [
            "Content-Type": "text/plain; charset=UTF-8"
        ])

        #expect(headers.contentType?.type == "text")
        #expect(headers.contentType?.subtype == "plain")
    }

    @Test
    func `Parse Content-Disposition header`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [
            "Content-Disposition": "attachment; filename=\"document.pdf\""
        ])

        #expect(headers.contentDisposition != nil)
    }

    @Test
    func `Parse Content-Transfer-Encoding header`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [
            "Content-Transfer-Encoding": "base64"
        ])

        #expect(headers.contentTransferEncoding == .base64)
    }

    @Test
    func `Parse all standard headers`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [
            "Content-Type": "text/plain; charset=UTF-8",
            "Content-Disposition": "inline",
            "Content-Transfer-Encoding": "7bit"
        ])

        #expect(headers.contentType != nil)
        #expect(headers.contentDisposition != nil)
        #expect(headers.contentTransferEncoding != nil)
    }

    @Test
    func `Parse custom headers`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [
            "X-Custom-Header": "custom-value",
            "X-Another": "another-value"
        ])

        #expect(headers.custom["X-Custom-Header"] == "custom-value")
        #expect(headers.custom["X-Another"] == "another-value")
    }

    @Test
    func `Parse mixed standard and custom headers`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [
            "Content-Type": "text/plain",
            "X-Custom": "value"
        ])

        #expect(headers.contentType != nil)
        #expect(headers.custom["X-Custom"] == "value")
        #expect(headers.custom["Content-Type"] == nil) // Should not be in custom
    }

    @Test
    func `Invalid Content-Type is ignored`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [
            "Content-Type": "invalid syntax"
        ])

        // Invalid content type should be ignored, not crash
        #expect(headers.contentType == nil)
    }

    @Test
    func `Invalid Content-Transfer-Encoding is ignored`() {
        let headers = RFC_2046.BodyPart.Headers(parsing: [
            "Content-Transfer-Encoding": "invalid-encoding"
        ])

        #expect(headers.contentTransferEncoding == nil)
    }
}

// MARK: - Headers to Dictionary

@Suite
struct `BodyPart.Headers - Converting to dictionary` {

    @Test
    func `Empty headers produce empty dictionary`() {
        let headers = RFC_2046.BodyPart.Headers()
        let dict = [String: String](headers)
        #expect(dict.isEmpty)
    }

    @Test
    func `Content-Type is included in dictionary`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )
        let dict = [String: String](headers)

        #expect(dict["Content-Type"] != nil)
        #expect(dict["Content-Type"]?.contains("text/plain") == true)
    }

    @Test
    func `Content-Disposition is included in dictionary`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentDisposition: .inline()
        )
        let dict = [String: String](headers)

        #expect(dict["Content-Disposition"] != nil)
    }

    @Test
    func `Content-Transfer-Encoding is included in dictionary`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentTransferEncoding: .base64
        )
        let dict = [String: String](headers)

        #expect(dict["Content-Transfer-Encoding"] == "base64")
    }

    @Test
    func `All headers are included in dictionary`() {
        let headers = RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textPlainUTF8,
            contentTransferEncoding: .sevenBit,
            custom: ["X-Custom": "value"]
        )
        let dict = [String: String](headers)

        #expect(dict["Content-Type"] != nil)
        #expect(dict["Content-Disposition"] != nil)
        #expect(dict["Content-Transfer-Encoding"] != nil)
        #expect(dict["X-Custom"] == "value")
        #expect(dict.count == 4)
    }

    @Test
    func `Custom headers are included in dictionary`() {
        let headers = RFC_2046.BodyPart.Headers(
            custom: [
                "X-Header-1": "value1",
                "X-Header-2": "value2"
            ]
        )
        let dict = [String: String](headers)

        #expect(dict["X-Header-1"] == "value1")
        #expect(dict["X-Header-2"] == "value2")
        #expect(dict.count == 2)
    }
}

// MARK: - Headers Round-trip

@Suite
struct `BodyPart.Headers - Round-trip conversion` {

    @Test
    func `Round-trip preserves Content-Type`() {
        let original = RFC_2046.BodyPart.Headers(
            contentType: .textPlainUTF8
        )

        let dict = [String: String](original)
        let parsed = RFC_2046.BodyPart.Headers(parsing: dict)

        #expect(parsed.contentType?.type == "text")
        #expect(parsed.contentType?.subtype == "plain")
    }

    @Test
    func `Round-trip preserves Content-Transfer-Encoding`() {
        let original = RFC_2046.BodyPart.Headers(
            contentTransferEncoding: .base64
        )

        let dict = [String: String](original)
        let parsed = RFC_2046.BodyPart.Headers(parsing: dict)

        #expect(parsed.contentTransferEncoding == .base64)
    }

    @Test
    func `Round-trip preserves custom headers`() {
        let original = RFC_2046.BodyPart.Headers(
            custom: [
                "X-Custom": "value"
            ]
        )

        let dict = [String: String](original)
        let parsed = RFC_2046.BodyPart.Headers(parsing: dict)

        #expect(parsed.custom["X-Custom"] == "value")
    }

    @Test
    func `Round-trip preserves all headers`() {
        let original = RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textHTMLUTF8,
            contentTransferEncoding: .quotedPrintable,
            custom: ["X-Custom": "value"]
        )

        let dict = [String: String](original)
        let parsed = RFC_2046.BodyPart.Headers(parsing: dict)

        #expect(parsed.contentDisposition != nil)
        #expect(parsed.contentType != nil)
        #expect(parsed.contentTransferEncoding == .quotedPrintable)
        #expect(parsed.custom["X-Custom"] == "value")
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
    func `Form data file creates correct headers`() {
        let headers = RFC_2046.BodyPart.Headers.formDataFile(
            name: "avatar",
            filename: "photo.jpg"
        )

        #expect(headers.contentDisposition != nil)
        #expect(headers.contentType == nil) // No default content type
    }

    @Test
    func `Form data file with content type`() {
        let contentType = RFC_2045.ContentType(type: "image", subtype: "jpeg")
        let headers = RFC_2046.BodyPart.Headers.formDataFile(
            name: "avatar",
            filename: "photo.jpg",
            contentType: contentType
        )

        #expect(headers.contentDisposition != nil)
        #expect(headers.contentType != nil)
        #expect(headers.contentType?.type == "image")
        #expect(headers.contentType?.subtype == "jpeg")
    }

    @Test
    func `Form data file with filename containing spaces`() {
        let headers = RFC_2046.BodyPart.Headers.formDataFile(
            name: "document",
            filename: "my document.pdf"
        )

        #expect(headers.contentDisposition != nil)
    }

    @Test
    func `Form data file with special characters in filename`() {
        let headers = RFC_2046.BodyPart.Headers.formDataFile(
            name: "file",
            filename: "document-v1.2.pdf"
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
    func `Headers with different custom values are not equal`() {
        let a = RFC_2046.BodyPart.Headers(custom: ["X-A": "1"])
        let b = RFC_2046.BodyPart.Headers(custom: ["X-A": "2"])
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
        let original = RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textPlainUTF8,
            contentTransferEncoding: .base64,
            custom: ["X-Custom": "value"]
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
