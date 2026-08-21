import Foundation
import Testing

@testable import RFC_2046

@Suite
struct `Boundary - Valid boundaries` {
    @Test(arguments: [
        "simple",
        "----=_Part_Custom",
        "a",
        String(repeating: "x", count: 70),
        "boundary-with-dashes",
        "boundary_with_underscores",
        "boundary.with.dots",
        "AlphaNumeric123",
        "with spaces inside",
        "ends-with-dash-",
        "ends_with_underscore_",
    ])
    func `Valid boundary strings are accepted`(value: String) throws {
        let boundary = try RFC_2046.Boundary(value)
        #expect(boundary.rawValue == value)
    }
}

@Suite
struct `Boundary - Invalid boundaries` {
    @Test
    func `Empty string is rejected`() {
        #expect(throws: Error.self) {
            _ = try RFC_2046.Boundary("")
        }
    }

    @Test
    func `Boundary ending with space is rejected`() {
        #expect(throws: Error.self) {
            _ = try RFC_2046.Boundary("test ")
        }
    }

    @Test
    func `Boundary ending with multiple spaces is rejected`() {
        #expect(throws: Error.self) {
            _ = try RFC_2046.Boundary("test  ")
        }
    }

    @Test(arguments: [71, 100, 200])
    func `Boundary exceeding 70 characters is rejected`(length: Int) {
        let value = String(repeating: "x", count: length)
        #expect(throws: Error.self) {
            _ = try RFC_2046.Boundary(value)
        }
    }
}

@Suite
struct `Boundary - Edge cases` {
    @Test
    func `Single character boundary is valid`() throws {
        let boundary = try RFC_2046.Boundary("x")
        #expect(boundary.rawValue == "x")
    }

    @Test
    func `Exactly 70 characters is valid`() throws {
        let value = String(repeating: "x", count: 70)
        let boundary = try RFC_2046.Boundary(value)
        #expect(boundary.rawValue == value)
        #expect(boundary.rawValue.count == 70)
    }

    @Test
    func `Boundary with leading space is valid`() throws {
        let boundary = try RFC_2046.Boundary(" test")
        #expect(boundary.rawValue == " test")
    }

    @Test
    func `Boundary with space in middle is valid`() throws {
        let boundary = try RFC_2046.Boundary("test test")
        #expect(boundary.rawValue == "test test")
    }
}

@Suite
struct `Boundary - Hashable and Equatable` {
    @Test
    func `Same boundaries are equal`() throws {
        let a = try RFC_2046.Boundary("test")
        let b = try RFC_2046.Boundary("test")
        #expect(a == b)
    }

    @Test
    func `Different boundaries are not equal`() throws {
        let a = try RFC_2046.Boundary("test1")
        let b = try RFC_2046.Boundary("test2")
        #expect(a != b)
    }

    @Test
    func `Same boundaries have same hash`() throws {
        let a = try RFC_2046.Boundary("test")
        let b = try RFC_2046.Boundary("test")
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `Boundaries work in Set`() throws {
        let boundaries: Set = try [
            RFC_2046.Boundary("test1"),
            RFC_2046.Boundary("test2"),
            RFC_2046.Boundary("test1"),
        ]
        #expect(boundaries.count == 2)
    }

    @Test
    func `Boundaries work as Dictionary keys`() throws {
        var dict: [RFC_2046.Boundary: String] = [:]
        let boundary = try RFC_2046.Boundary("test")
        dict[boundary] = "value"
        #expect(dict[boundary] == "value")
    }
}

@Suite
struct `Boundary - CustomStringConvertible` {
    @Test
    func `Description returns the boundary value`() throws {
        let boundary = try RFC_2046.Boundary("test-boundary")
        #expect(boundary.description == "test-boundary")
    }

    @Test
    func `String interpolation works`() throws {
        let boundary = try RFC_2046.Boundary("test")
        let message = "Boundary: \(boundary)"
        #expect(message == "Boundary: test")
    }
}

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

        #expect(throws: Error.self) {
            try decoder.decode(RFC_2046.Boundary.self, from: Data(json.utf8))
        }
    }

    @Test
    func `Decoding boundary ending with space throws`() throws {
        let json = "\"test \""
        let decoder = JSONDecoder()

        #expect(throws: Error.self) {
            try decoder.decode(RFC_2046.Boundary.self, from: Data(json.utf8))
        }
    }

    @Test
    func `Decoding boundary too long throws`() throws {
        let longBoundary = String(repeating: "x", count: 71)
        let json = "\"\(longBoundary)\""
        let decoder = JSONDecoder()

        #expect(throws: Error.self) {
            try decoder.decode(RFC_2046.Boundary.self, from: Data(json.utf8))
        }
    }
}

@Suite
struct `Boundary - Sendable conformance` {
    @Test
    func `Boundary can be sent across concurrency domains`() async throws {
        let boundary = try RFC_2046.Boundary("test")

        let result = await Task {
            boundary.rawValue
        }.value

        #expect(result == "test")
    }
}
