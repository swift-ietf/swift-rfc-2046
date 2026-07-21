import Testing

@testable import RFC_2046

// MARK: - Unit

@Suite
struct `Boundary.random - Unit` {
    @Test
    func `Random boundary has the ----=_Part_ prefix`() {
        let boundary = RFC_2046.Boundary.random()
        #expect(boundary.rawValue.hasPrefix("----=_Part_"))
    }

    @Test
    func `Random boundary is 43 characters`() {
        let boundary = RFC_2046.Boundary.random()
        #expect(boundary.rawValue.count == 43)
    }

    @Test
    func `Random boundary hex suffix is 32 lowercase hex characters`() {
        let boundary = RFC_2046.Boundary.random()
        let hex = boundary.rawValue.dropFirst("----=_Part_".count)
        #expect(hex.count == 32)
        #expect(hex.allSatisfy { "0123456789abcdef".contains($0) })
    }

    @Test
    func `Random boundary revalidates through the validating initializer`() throws {
        let boundary = RFC_2046.Boundary.random()
        let revalidated = try RFC_2046.Boundary(boundary.rawValue)
        #expect(revalidated == boundary)
    }

    @Test
    func `Deterministic generator yields reproducible boundary`() {
        var a = Counting()
        var b = Counting()
        let first = RFC_2046.Boundary.random(using: &a)
        let second = RFC_2046.Boundary.random(using: &b)
        #expect(first == second)
    }
}

// MARK: - Edge Case

@Suite
struct `Boundary.random - Edge cases` {
    @Test
    func `All-zero entropy still produces a valid boundary`() throws {
        var generator = Constant(value: 0)
        let boundary = RFC_2046.Boundary.random(using: &generator)
        #expect(boundary.rawValue == "----=_Part_" + String(repeating: "0", count: 32))
        _ = try RFC_2046.Boundary(boundary.rawValue)
    }

    @Test
    func `All-ones entropy still produces a valid boundary`() throws {
        var generator = Constant(value: .max)
        let boundary = RFC_2046.Boundary.random(using: &generator)
        #expect(boundary.rawValue == "----=_Part_" + String(repeating: "f", count: 32))
        _ = try RFC_2046.Boundary(boundary.rawValue)
    }

    @Test
    func `Random boundary never ends with whitespace`() {
        for _ in 0..<100 {
            let boundary = RFC_2046.Boundary.random()
            #expect(boundary.rawValue.last != " ")
        }
    }

    @Test
    func `Successive random boundaries are distinct`() {
        let boundaries = (0..<100).map { _ in RFC_2046.Boundary.random().rawValue }
        #expect(Set(boundaries).count == boundaries.count)
    }
}

// MARK: - Integration

@Suite
struct `Boundary.random - Integration` {
    @Test
    func `Random boundary serializes and round-trips through bytes`() throws {
        let boundary = RFC_2046.Boundary.random()
        let bytes = [Byte](boundary)
        let parsed = try RFC_2046.Boundary(ascii: bytes)
        #expect(parsed == boundary)
    }
}

// MARK: - Test generators

/// Deterministic generator counting upward from zero.
private struct Counting: RandomNumberGenerator {
    var state: UInt64 = 0
    mutating func next() -> UInt64 {
        defer { state &+= 1 }
        return state
    }
}

/// Generator returning a constant word.
private struct Constant: RandomNumberGenerator {
    let value: UInt64
    mutating func next() -> UInt64 { value }
}
