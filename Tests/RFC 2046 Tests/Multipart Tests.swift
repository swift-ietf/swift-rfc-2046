import Foundation
import RFC_2045
@testable import RFC_2046
import RFC_2183
import Testing

// MARK: - Multipart Initialization

@Suite
struct `Multipart - Valid initialization` {
    @Test
    func `Initialize with minimum parameters`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary"
        )

        #expect(multipart.subtype == .mixed)
        #expect(multipart.parts.count == 1)
        #expect(multipart.boundary.rawValue == "test-boundary")
        #expect(multipart.preamble == nil)
        #expect(multipart.epilogue == nil)
        #expect(multipart.additionalParameters.isEmpty)
    }

    @Test
    func `Initialize with preamble and epilogue`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary",
            preamble: "This is the preamble",
            epilogue: "This is the epilogue"
        )

        #expect(multipart.preamble == "This is the preamble")
        #expect(multipart.epilogue == "This is the epilogue")
    }

    @Test
    func `Initialize with additional parameters`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary",
            additionalParameters: [
                .init("type"): "text/html",
                .init("start"): "<part1>",
            ]
        )

        #expect(try multipart.additionalParameters[.init("type")] == "text/html")
        #expect(try multipart.additionalParameters[.init("start")] == "<part1>")
    }

    @Test
    func `Initialize with multiple parts`() throws {
        let parts = [
            RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Part 1"),
            RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Part 2</p>"),
            RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Part 3"),
        ]

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: parts,
            boundary: "test-boundary"
        )

        #expect(multipart.parts.count == 3)
    }

    @Test
    func `Initialize with Boundary type`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )
        let boundary = try RFC_2046.Boundary("test-boundary")

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: boundary
        )

        #expect(multipart.boundary == boundary)
    }
}

@Suite
struct `Multipart - Invalid initialization` {
    @Test
    func `Empty parts array throws error`() {
        #expect(throws: RFC_2046.Multipart.Error.emptyParts) {
            try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [],
                boundary: "test-boundary"
            )
        }
    }

    @Test
    func `Invalid boundary string throws error`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        #expect(throws: Error.self) {
            try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [part],
                boundary: "" // Empty boundary
            )
        }
    }

    @Test
    func `Boundary ending with space throws error`() {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        #expect(throws: Error.self) {
            try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [part],
                boundary: "test " // Ends with space
            )
        }
    }
}

// MARK: - Multipart Subtypes

@Suite
struct `Multipart.Subtype - Standard subtypes` {
    @Test(arguments: [
        ("mixed", RFC_2046.Multipart.Subtype.mixed),
        ("alternative", .alternative),
        ("digest", .digest),
        ("parallel", .parallel),
    ])
    func `Standard subtype raw values`(rawValue: String, subtype: RFC_2046.Multipart.Subtype) {
        #expect(subtype.rawValue == rawValue)
    }

    @Test
    func `Custom subtype can be created`() {
        let custom = RFC_2046.Multipart.Subtype(rawValue: "x-custom")
        #expect(custom.rawValue == "x-custom")
    }

    @Test
    func `Subtype is case-insensitive`() {
        let upper = RFC_2046.Multipart.Subtype(rawValue: "MIXED")
        let lower = RFC_2046.Multipart.Subtype(rawValue: "mixed")
        #expect(upper == lower)
        #expect(upper.rawValue == "mixed") // Normalized to lowercase
    }

    @Test
    func `Form-data subtype for RFC 7578`() {
        let formData = RFC_2046.Multipart.Subtype(rawValue: "form-data")
        #expect(formData.rawValue == "form-data")
    }

    @Test
    func `Related subtype for RFC 2387`() {
        let related = RFC_2046.Multipart.Subtype(rawValue: "related")
        #expect(related.rawValue == "related")
    }
}

@Suite
struct `Multipart.Subtype - Protocol conformance` {
    @Test
    func `Subtypes are equatable`() {
        #expect(RFC_2046.Multipart.Subtype.mixed == .mixed)
        #expect(RFC_2046.Multipart.Subtype.mixed != .alternative)
    }

    @Test
    func `Subtypes are hashable`() {
        let set: Set = [
            RFC_2046.Multipart.Subtype.mixed,
            .alternative,
            .mixed, // Duplicate
        ]
        #expect(set.count == 2)
    }

    @Test
    func `Subtypes are codable`() throws {
        let original = RFC_2046.Multipart.Subtype.alternative

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.Multipart.Subtype.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - Multipart Content-Type

@Suite
struct `Multipart - Content-Type generation` {
    @Test
    func `Content-Type includes boundary parameter`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary"
        )

        let contentType = multipart.contentType

        #expect(contentType.type == "multipart")
        #expect(contentType.subtype == "mixed")
        #expect(try contentType.parameters[.init("boundary")] == "test-boundary")
    }

    @Test
    func `Content-Type includes additional parameters`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary",
            additionalParameters: [.init("type"): "text/html"]
        )

        let contentType = multipart.contentType

        #expect(try contentType.parameters[.init("boundary")] == "test-boundary")
        #expect(try contentType.parameters[.init("type")] == "text/html")
    }

    @Test
    func `Content-Type header value is formatted correctly`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .alternative,
            parts: [part],
            boundary: "test-boundary"
        )

        let headerValue = multipart.contentType.headerValue

        #expect(headerValue.contains("multipart/alternative"))
        #expect(headerValue.contains("boundary="))
    }
}

// MARK: - Multipart Rendering

@Suite
struct `Multipart - Rendering basic structure` {
    @Test
    func `Render includes boundary delimiters`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("--test-boundary"))
        #expect(rendered.contains("--test-boundary--")) // Final boundary
    }

    @Test
    func `Render includes part content`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello, World!"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("Hello, World!"))
    }

    @Test
    func `Render includes part headers`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .sevenBit,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("Content-Type: text/plain"))
        #expect(rendered.contains("Content-Transfer-Encoding: 7bit"))
    }

    @Test
    func `Render uses CRLF line endings`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("\r\n"))
    }

    @Test
    func `Render ends with CRLF`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.hasSuffix("\r\n"))
    }
}

@Suite
struct `Multipart - Rendering multiple parts` {
    @Test
    func `Render multiple parts with boundaries`() throws {
        let parts = [
            RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Part 1"),
            RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Part 2"),
        ]

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: parts,
            boundary: "test-boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        // Should have two occurrences of the boundary (one per part)
        let boundaryCount = rendered.components(separatedBy: "--test-boundary\r\n").count - 1
        #expect(boundaryCount == 2)

        #expect(rendered.contains("Part 1"))
        #expect(rendered.contains("Part 2"))
    }

    @Test
    func `Render alternative parts (text and HTML)`() throws {
        let textPart = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Plain text version"
        )

        let htmlPart = RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            text: "<p>HTML version</p>"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .alternative,
            parts: [textPart, htmlPart],
            boundary: "test-boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("Plain text version"))
        #expect(rendered.contains("<p>HTML version</p>"))
    }
}

@Suite
struct `Multipart - Rendering with preamble and epilogue` {
    @Test
    func `Render includes preamble`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary",
            preamble: "This is the preamble"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("This is the preamble"))

        // Preamble should come before first boundary
        let preambleIndex = rendered.range(of: "This is the preamble")?.lowerBound
        let boundaryIndex = rendered.range(of: "--test-boundary")?.lowerBound
        #expect(preambleIndex != nil && boundaryIndex != nil)
        if let p = preambleIndex, let b = boundaryIndex {
            #expect(p < b)
        }
    }

    @Test
    func `Render includes epilogue`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary",
            epilogue: "This is the epilogue"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("This is the epilogue"))

        // Epilogue should come after final boundary
        let epilogueIndex = rendered.range(of: "This is the epilogue")?.lowerBound
        let finalBoundaryIndex = rendered.range(of: "--test-boundary--")?.lowerBound
        #expect(epilogueIndex != nil && finalBoundaryIndex != nil)
        if let e = epilogueIndex, let b = finalBoundaryIndex {
            #expect(e > b)
        }
    }

    @Test
    func `Render with both preamble and epilogue`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test-boundary",
            preamble: "Preamble text",
            epilogue: "Epilogue text"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("Preamble text"))
        #expect(rendered.contains("Epilogue text"))
    }
}

// MARK: - Multipart Parsing

@Suite
struct `Multipart - Parsing basic structure` {
    @Test
    func `Parse simple multipart message`() throws {
        let message = """
        --test-boundary\r
        Content-Type: text/plain\r
        \r
        Hello\r
        --test-boundary--\r

        """

        let boundary = try RFC_2046.Boundary("test-boundary")
        let context = RFC_2046.Multipart.Context(boundary: boundary, subtype: .mixed)
        let multipart = try RFC_2046.Multipart(ascii: Array(message.utf8), in: context)

        #expect(multipart.parts.count == 1)
        #expect(multipart.parts[0].textContent?.contains("Hello") == true)
    }

    @Test
    func `Parse multipart with multiple parts`() throws {
        let message = """
        --boundary\r
        Content-Type: text/plain\r
        \r
        Part 1\r
        --boundary\r
        Content-Type: text/plain\r
        \r
        Part 2\r
        --boundary--\r

        """

        let boundary = try RFC_2046.Boundary("boundary")
        let context = RFC_2046.Multipart.Context(boundary: boundary)
        let multipart = try RFC_2046.Multipart(ascii: Array(message.utf8), in: context)

        #expect(multipart.parts.count == 2)
    }

    @Test
    func `Parse with preamble`() throws {
        let message = """
        This is the preamble\r
        \r
        --boundary\r
        Content-Type: text/plain\r
        \r
        Hello\r
        --boundary--\r

        """

        let boundary = try RFC_2046.Boundary("boundary")
        let context = RFC_2046.Multipart.Context(boundary: boundary)
        let multipart = try RFC_2046.Multipart(ascii: Array(message.utf8), in: context)

        #expect(multipart.preamble?.contains("This is the preamble") == true)
    }

    @Test
    func `Parse with epilogue`() throws {
        let message = """
        --boundary\r
        Content-Type: text/plain\r
        \r
        Hello\r
        --boundary--\r
        \r
        This is the epilogue\r

        """

        let boundary = try RFC_2046.Boundary("boundary")
        let context = RFC_2046.Multipart.Context(boundary: boundary)
        let multipart = try RFC_2046.Multipart(ascii: Array(message.utf8), in: context)

        #expect(multipart.epilogue?.contains("This is the epilogue") == true)
    }
}

@Suite
struct `Multipart - Round-trip serialization and parsing` {
    @Test
    func `Round-trip simple message`() throws {
        let original = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [
                RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Hello"),
            ],
            boundary: "test-boundary"
        )

        // Serialize to bytes (canonical)
        let bytes = [UInt8](original)

        // Parse back from bytes
        let context = RFC_2046.Multipart.Context(boundary: original.boundary, subtype: original.subtype)
        let parsed = try RFC_2046.Multipart(ascii: bytes, in: context)

        #expect(parsed.parts.count == 1)
        #expect(parsed.boundary == original.boundary)
    }

    @Test
    func `Round-trip with multiple parts`() throws {
        let original = try RFC_2046.Multipart(
            subtype: .alternative,
            parts: [
                RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Text"),
                RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>HTML</p>"),
            ],
            boundary: "boundary"
        )

        // Serialize to bytes (canonical)
        let bytes = [UInt8](original)

        // Parse back from bytes
        let context = RFC_2046.Multipart.Context(boundary: original.boundary, subtype: original.subtype)
        let parsed = try RFC_2046.Multipart(ascii: bytes, in: context)

        #expect(parsed.parts.count == 2)
    }
}

// MARK: - Multipart Protocol Conformance

@Suite
struct `Multipart - Hashable and Equatable` {
    @Test
    func `Same multipart messages are equal`() throws {
        let part = RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Hello")

        let a = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test"
        )

        let b = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test"
        )

        #expect(a == b)
    }

    @Test
    func `Different boundaries make messages not equal`() throws {
        let part = RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Hello")

        let a = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "boundary1"
        )

        let b = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "boundary2"
        )

        #expect(a != b)
    }

    @Test
    func `Different subtypes make messages not equal`() throws {
        let part = RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Hello")

        let a = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "test"
        )

        let b = try RFC_2046.Multipart(
            subtype: .alternative,
            parts: [part],
            boundary: "test"
        )

        #expect(a != b)
    }

    @Test
    func `Different parts make messages not equal`() throws {
        let a = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "A")],
            boundary: "test"
        )

        let b = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "B")],
            boundary: "test"
        )

        #expect(a != b)
    }
}

@Suite
struct `Multipart - Codable` {
    @Test
    func `Round-trip encoding preserves multipart`() throws {
        let original = try RFC_2046.Multipart(
            subtype: .alternative,
            parts: [
                RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Hello"),
            ],
            boundary: "test-boundary",
            preamble: "Preamble",
            epilogue: "Epilogue",
            additionalParameters: [.init("type"): "text/html"]
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.Multipart.self, from: data)

        #expect(decoded.subtype == original.subtype)
        #expect(decoded.boundary == original.boundary)
        #expect(decoded.parts == original.parts)
        #expect(decoded.preamble == original.preamble)
        #expect(decoded.epilogue == original.epilogue)
        #expect(decoded.additionalParameters == original.additionalParameters)
    }
}

@Suite
struct `Multipart - Sendable conformance` {
    @Test
    func `Multipart can be sent across concurrency domains`() async throws {
        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [
                RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Hello"),
            ],
            boundary: "test"
        )

        let result = await Task {
            multipart.parts.count
        }.value

        #expect(result == 1)
    }
}

// MARK: - Multipart Edge Cases

@Suite
struct `Multipart - Edge cases` {
    @Test
    func `Boundary appearing in content is preserved`() throws {
        // Note: In real usage, this would be invalid, but we should handle it gracefully
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "This contains --boundary inside"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("This contains --boundary inside"))
    }

    @Test
    func `Large multipart message with many parts`() throws {
        let parts = (1 ... 100).map { i in
            RFC_2046.BodyPart(
                contentType: .textPlainUTF8,
                text: "Part \(i)"
            )
        }

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: parts,
            boundary: "boundary"
        )

        #expect(multipart.parts.count == 100)

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)
        #expect(rendered.contains("Part 1"))
        #expect(rendered.contains("Part 100"))
    }

    @Test
    func `Multipart with empty part content`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: ""
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("--boundary"))
        #expect(rendered.contains("--boundary--"))
    }

    @Test
    func `Multipart with Unicode content`() throws {
        let part = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            text: "Hello 世界 🌍"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: "boundary"
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains("Hello 世界 🌍"))
    }

    @Test
    func `Long preamble and epilogue`() throws {
        let longText = String(repeating: "This is a long text. ", count: 100)

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [
                RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Content"),
            ],
            boundary: "boundary",
            preamble: longText,
            epilogue: longText
        )

        let rendered = String(decoding: [UInt8](multipart), as: UTF8.self)

        #expect(rendered.contains(longText))
    }
}
