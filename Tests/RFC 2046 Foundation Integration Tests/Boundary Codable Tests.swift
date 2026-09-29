import Foundation
import RFC_2046
import RFC_2046_Foundation_Integration
import Testing

@Suite
struct `Boundary - Codable` {
    @Test
    func `Encoding produces valid JSON`() throws {
        let boundary = try RFC_2046.Boundary("test-boundary")
        let encoder = JSONEncoder()
        let data = try encoder.encode(boundary)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json == "\"test-boundary\"")
    }

    @Test
    func `Decoding valid JSON succeeds`() throws {
        let json = "\"test-boundary\""
        let decoder = JSONDecoder()
        let boundary = try decoder.decode(RFC_2046.Boundary.self, from: Data(json.utf8))
        #expect(boundary.rawValue == "test-boundary")
    }

    @Test
    func `Round-trip encoding preserves value`() throws {
        let original = try RFC_2046.Boundary("----=_Part_Custom")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RFC_2046.Boundary.self, from: data)

        #expect(decoded == original)
        #expect(decoded.rawValue == original.rawValue)
    }

    @Test
    func `Decoding invalid boundary throws`() throws {
        let json = "\"\""
        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            try decoder.decode(RFC_2046.Boundary.self, from: Data(json.utf8))
        }
    }

    @Test
    func `Decoding boundary ending with space throws`() throws {
        let json = "\"test \""
        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            try decoder.decode(RFC_2046.Boundary.self, from: Data(json.utf8))
        }
    }

    @Test
    func `Decoding boundary too long throws`() throws {
        let longBoundary = String(repeating: "x", count: 71)
        let json = "\"\(longBoundary)\""
        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            try decoder.decode(RFC_2046.Boundary.self, from: Data(json.utf8))
        }
    }
}
