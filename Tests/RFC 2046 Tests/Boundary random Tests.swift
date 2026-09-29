import RFC_2045
import RFC_2046
import Testing

@Suite
struct `Boundary.random` {
    @Suite
    struct `Generated boundaries` {
        @Test
        func `Random boundary has the ----Part_ prefix`() {
            let boundary = RFC_2046.Boundary.random()
            let value = String(describing: boundary)
            #expect(value.hasPrefix("----Part_"))
        }

        @Test
        func `Random boundary is 41 characters`() {
            let boundary = RFC_2046.Boundary.random()
            let value = String(describing: boundary)
            #expect(value.count == 41)
        }

        @Test
        func `Random boundary hex suffix is 32 lowercase hex characters`() {
            let boundary = RFC_2046.Boundary.random()
            let value = String(describing: boundary)
            let hex = value.dropFirst("----Part_".count)
            #expect(hex.count == 32)
            #expect(hex.allSatisfy { "0123456789abcdef".contains($0) })
        }

        @Test
        func `Random boundary revalidates through the validating initializer`()
            throws(RFC_2046.Boundary.Error)
        {
            let boundary = RFC_2046.Boundary.random()
            let revalidated = try RFC_2046.Boundary(String(describing: boundary))
            #expect(revalidated == boundary)
        }

        @Test
        func `Random boundary is an unquotable Content-Type parameter value`()
            throws(RFC_2046.Multipart.Error)
        {
            let boundary = RFC_2046.Boundary.random()
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("x")
            )
            let multipart = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [part],
                boundary: boundary
            )

            #expect(multipart.contentType.parameters[.boundary] == boundary.rawValue)
            #expect(!boundary.rawValue.contains("\""))
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

    @Suite
    struct `Extreme entropy` {
        @Test
        func `All-zero entropy still produces a valid boundary`()
            throws(RFC_2046.Boundary.Error)
        {
            var generator = Constant(value: 0)
            let boundary = RFC_2046.Boundary.random(using: &generator)
            let value = String(describing: boundary)
            #expect(value == "----Part_" + String(repeating: "0", count: 32))
            _ = try RFC_2046.Boundary(value)
        }

        @Test
        func `All-ones entropy still produces a valid boundary`()
            throws(RFC_2046.Boundary.Error)
        {
            var generator = Constant(value: .max)
            let boundary = RFC_2046.Boundary.random(using: &generator)
            let value = String(describing: boundary)
            #expect(value == "----Part_" + String(repeating: "f", count: 32))
            _ = try RFC_2046.Boundary(value)
        }

        @Test
        func `Random boundary never ends with whitespace`() {
            for _ in 0..<100 {
                let boundary = RFC_2046.Boundary.random()
                #expect(String(describing: boundary).last != " ")
            }
        }

        @Test
        func `Successive random boundaries are distinct`() {
            let boundaries = (0..<100).map { _ in
                String(describing: RFC_2046.Boundary.random())
            }
            #expect(Set(boundaries).count == boundaries.count)
        }
    }
}

private struct Counting {
    var state: UInt64 = 0
}

extension Counting: RandomNumberGenerator {
    mutating func next() -> UInt64 {
        defer { state &+= 1 }
        return state
    }
}

private struct Constant {
    let value: UInt64
}

extension Constant: RandomNumberGenerator {
    mutating func next() -> UInt64 { value }
}
