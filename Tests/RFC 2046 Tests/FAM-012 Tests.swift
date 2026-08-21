import Foundation
import RFC_2183
import Testing

@testable import RFC_2046

@Suite("RFC 2046 [FAM-012] ASCII==Binary Equivalence")
struct ASCIIBinaryEquivalenceTests {
    @Test func `Boundary verbs agree`() throws {
        let value = try RFC_2046.Boundary("----=_Part_12345_Custom")
        var ascii: [ASCII.Code] = []
        RFC_2046.Boundary.serialize(value, into: &ascii)
        var wire: [Byte] = []
        RFC_2046.Boundary.serialize(value, into: &wire)
        #expect(ascii.map(\.byte) == wire)
        #expect(String(decoding: wire, as: UTF8.self) == "----=_Part_12345_Custom")
    }

    @Test func `Multipart.Subtype verbs agree`() {
        let value = RFC_2046.Multipart.Subtype.alternative
        var ascii: [ASCII.Code] = []
        RFC_2046.Multipart.Subtype.serialize(value, into: &ascii)
        var wire: [Byte] = []
        RFC_2046.Multipart.Subtype.serialize(value, into: &wire)
        #expect(ascii.map(\.byte) == wire)
        #expect(String(decoding: wire, as: UTF8.self) == "alternative")
    }

    @Test func `BodyPart.Headers verbs agree`() {

        let value = RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textPlainUTF8,
            contentTransferEncoding: .base64
        )
        var ascii: [ASCII.Code] = []
        RFC_2046.BodyPart.Headers.serialize(value, into: &ascii)
        var wire: [Byte] = []
        RFC_2046.BodyPart.Headers.serialize(value, into: &wire)
        #expect(ascii.map(\.byte) == wire)
    }
}

@Suite("RFC 2046 [FAM-012] Binary-only Round-trips")
struct BinaryOnlyRoundTripTests {
    @Test func `Content round-trips (binary verb + init(binary:))`() {
        let bytes: [Byte] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]
        let original = RFC_2046.BodyPart.Content(bytes)
        var wire: [Byte] = []
        RFC_2046.BodyPart.Content.serialize(original, into: &wire)
        #expect(wire == bytes)
        let reparsed = RFC_2046.BodyPart.Content(binary: wire)
        #expect(reparsed == original)
        #expect(reparsed.rawValue == bytes)
    }

    @Test func `Headers round-trips (Byte verb + init(ascii:))`() throws {
        let original = RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8)
        var wire: [Byte] = []
        RFC_2046.BodyPart.Headers.serialize(original, into: &wire)
        let reparsed = try RFC_2046.BodyPart.Headers(ascii: wire)
        #expect(reparsed.contentType == original.contentType)
    }

    @Test func `BodyPart round-trips (Byte verb + init(binary:))`() throws {
        let original = RFC_2046.BodyPart(
            headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
            content: RFC_2046.BodyPart.Content("Hello, World!")
        )
        let wire = [Byte](original)
        let reparsed = try RFC_2046.BodyPart(binary: wire)
        #expect([Byte](reparsed.content) == [Byte](original.content))
        #expect(reparsed.contentType == original.contentType)
    }
}

extension RFC_2046.Multipart {
    @Suite("RFC 2046 [FAM-012] Multipart parser-witness")
    struct Test {
        @Test func `Multipart serializes then re-parses via the parser witness`() throws {
            let boundary = try RFC_2046.Boundary("----=_Part_12345")
            let part1 = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("Hello!")
            )
            let part2 = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("World!")
            )
            let original = try RFC_2046.Multipart(
                subtype: .alternative,
                parts: [part1, part2],
                boundary: boundary
            )

            let wire = [Byte](original)

            let parsed = try RFC_2046.Multipart.parse(
                from: wire,
                parser: RFC_2046.Multipart.Parser(boundary: boundary, subtype: .alternative)
            )

            #expect(parsed.parts.count == 2)
            #expect(parsed.boundary == boundary)
            #expect(parsed.parts.first?.content.description == "Hello!")
            #expect(parsed.parts.last?.content.description == "World!")
        }

        @Test func `Parser witness stores context and round-trips via the static entry`() throws {
            let boundary = try RFC_2046.Boundary("b0undary")
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("body")
            )
            let original = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [part],
                boundary: boundary
            )
            let wire = [Byte](original)

            let witness = RFC_2046.Multipart.Parser(boundary: boundary)
            #expect(witness.boundary == boundary)
            let parsed = try RFC_2046.Multipart.parse(from: wire, parser: witness)
            #expect(parsed.parts.count == 1)
            #expect(parsed.parts.first?.content.description == "body")
        }
    }
}
