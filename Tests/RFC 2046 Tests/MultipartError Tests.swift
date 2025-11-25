@testable import RFC_2046
import Testing

// MARK: - Boundary.Error Tests

@Suite
struct `Boundary.Error - Error cases` {
    @Test
    func `empty boundary throws empty error`() {
        #expect(throws: RFC_2046.Boundary.Error.self) {
            _ = try RFC_2046.Boundary("")
        }
    }

    @Test
    func `too long boundary throws tooLong error`() {
        let longBoundary = String(repeating: "x", count: 71)
        #expect(throws: RFC_2046.Boundary.Error.self) {
            _ = try RFC_2046.Boundary(longBoundary)
        }
    }

    @Test
    func `boundary with trailing space throws endsWithWhitespace error`() {
        #expect(throws: RFC_2046.Boundary.Error.self) {
            _ = try RFC_2046.Boundary("test ")
        }
    }

    @Test
    func `boundary with invalid character throws invalidCharacter error`() {
        #expect(throws: RFC_2046.Boundary.Error.self) {
            _ = try RFC_2046.Boundary("test\u{00}")
        }
    }

    @Test
    func `valid boundary succeeds`() throws {
        let boundary = try RFC_2046.Boundary("----=_Part_12345")
        #expect(boundary.rawValue == "----=_Part_12345")
    }

    @Test
    func `maximum length boundary succeeds`() throws {
        let maxBoundary = String(repeating: "x", count: 70)
        let boundary = try RFC_2046.Boundary(maxBoundary)
        #expect(boundary.rawValue == maxBoundary)
    }
}

@Suite
struct `Boundary.Error - Equatable` {
    @Test
    func `empty errors are equal`() {
        let a = RFC_2046.Boundary.Error.empty
        let b = RFC_2046.Boundary.Error.empty
        #expect(a == b)
    }

    @Test
    func `same tooLong errors are equal`() {
        let a = RFC_2046.Boundary.Error.tooLong(100)
        let b = RFC_2046.Boundary.Error.tooLong(100)
        #expect(a == b)
    }

    @Test
    func `different tooLong errors are not equal`() {
        let a = RFC_2046.Boundary.Error.tooLong(100)
        let b = RFC_2046.Boundary.Error.tooLong(200)
        #expect(a != b)
    }

    @Test
    func `different error types are not equal`() {
        let a = RFC_2046.Boundary.Error.empty
        let b = RFC_2046.Boundary.Error.tooLong(100)
        #expect(a != b)
    }
}

// MARK: - Multipart.Error Tests

@Suite
struct `Multipart.Error - Error cases` {
    @Test
    func `emptyParts error is created`() {
        let error = RFC_2046.Multipart.Error.emptyParts
        #expect(error == .emptyParts)
    }

    @Test
    func `Multipart initialization throws emptyParts`() {
        #expect(throws: RFC_2046.Multipart.Error.self) {
            _ = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [],
                boundary: .init("test")
            )
        }
    }

    @Test
    func `Catching emptyParts error`() {
        do {
            _ = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [],
                boundary: .init("test")
            )
            Issue.record("Expected error to be thrown")
        } catch let error as RFC_2046.Multipart.Error {
            #expect(error == .emptyParts)
        } catch {
            Issue.record("Expected RFC_2046.Multipart.Error")
        }
    }
}

@Suite
struct `Multipart.Error - Equatable` {
    @Test
    func `emptyParts errors are equal`() {
        let a = RFC_2046.Multipart.Error.emptyParts
        let b = RFC_2046.Multipart.Error.emptyParts
        #expect(a == b)
    }
}

@Suite
struct `Multipart.Error - Sendable conformance` {
    @Test
    func `Errors can be sent across concurrency domains`() async {
        let error = RFC_2046.Multipart.Error.emptyParts

        let result = await Task {
            error
        }.value

        #expect(result == .emptyParts)
    }
}

// MARK: - Subtype.Error Tests

@Suite
struct `Subtype.Error - Error cases` {
    @Test
    func `empty subtype throws empty error`() {
        #expect(throws: RFC_2046.Multipart.Subtype.Error.self) {
            _ = try RFC_2046.Multipart.Subtype(ascii: Array("".utf8))
        }
    }

    @Test
    func `valid subtype succeeds`() throws {
        let subtype = try RFC_2046.Multipart.Subtype(ascii: Array("alternative".utf8))
        #expect(subtype.rawValue == "alternative")
    }

    @Test
    func `subtype normalizes to lowercase`() throws {
        let subtype = try RFC_2046.Multipart.Subtype(ascii: Array("ALTERNATIVE".utf8))
        #expect(subtype.rawValue == "alternative")
    }
}

// MARK: - Headers.Error Tests

@Suite
struct `Headers.Error - Error cases` {
    @Test
    func `invalid header line throws error`() {
        #expect(throws: RFC_2046.BodyPart.Headers.Error.self) {
            _ = try RFC_2046.BodyPart.Headers(ascii: Array("invalid header without colon".utf8))
        }
    }

    @Test
    func `empty header name throws error`() {
        #expect(throws: RFC_2046.BodyPart.Headers.Error.self) {
            _ = try RFC_2046.BodyPart.Headers(ascii: Array(": value".utf8))
        }
    }

    @Test
    func `valid header parses correctly`() throws {
        let headers = try RFC_2046.BodyPart.Headers(ascii: Array("Content-Type: text/plain".utf8))
        #expect(headers.contentType != nil)
    }
}

// MARK: - Integration Tests

@Suite
struct `Error - Integration` {
    @Test
    func `Valid multipart can be created`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = try RFC_2046.BodyPart.Content("Hello!")
        let part = RFC_2046.BodyPart(headers: headers, content: content)

        let multipart = try RFC_2046.Multipart(
            subtype: .mixed,
            parts: [part],
            boundary: .init("----=_Part_12345")
        )

        #expect(multipart.parts.count == 1)
        #expect(multipart.boundary.rawValue == "----=_Part_12345")
    }

    @Test
    func `Boundary errors propagate through Multipart init`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = try RFC_2046.BodyPart.Content("test")
        let part = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(throws: Error.self) {
            _ = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [part],
                boundary: .init("") // Invalid boundary
            )
        }
    }
}
