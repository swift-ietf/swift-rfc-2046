import RFC_2045
import RFC_2046
import Testing

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
struct `Multipart.Error - Error cases` {
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
struct `Subtype.Error - Error cases` {
    @Test
    func `empty subtype throws empty error`() {
        #expect(throws: RFC_2046.Multipart.Subtype.Error.self) {
            _ = try RFC_2046.Multipart.Subtype("")
        }
    }

    @Test
    func `valid subtype succeeds`() throws {
        let subtype = try RFC_2046.Multipart.Subtype("alternative")
        #expect(subtype.rawValue == "alternative")
    }

    @Test
    func `subtype normalizes to lowercase`() throws {
        let subtype = try RFC_2046.Multipart.Subtype("ALTERNATIVE")
        #expect(subtype.rawValue == "alternative")
    }
}

@Suite
struct `Error - Integration` {
    @Test
    func `Valid multipart can be created`() throws {
        let headers = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        let content = RFC_2046.BodyPart.Content("Hello!")
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
        let content = RFC_2046.BodyPart.Content("test")
        let part = RFC_2046.BodyPart(headers: headers, content: content)

        #expect(throws: RFC_2046.Boundary.Error.self) {
            _ = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [part],
                boundary: .init("")
            )
        }
    }
}
