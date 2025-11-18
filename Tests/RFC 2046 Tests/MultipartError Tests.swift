import Testing
@testable import RFC_2046

// MARK: - MultipartError Types

@Suite
struct `MultipartError - Error cases` {

    @Test
    func `invalidBoundary error is created`() {
        let value: String = "test "
        let error = RFC_2046.MultipartError.invalidBoundary(value)

        switch error {
        case .invalidBoundary(let value):
            #expect(value == "test ")
        default:
            Issue.record("Expected invalidBoundary error")
        }
    }

    @Test
    func `boundaryTooLong error is created`() {
        let longBoundary = String(repeating: "x", count: 100)
        let error = RFC_2046.MultipartError.boundaryTooLong(longBoundary, length: 100)

        switch error {
        case .boundaryTooLong(let value, let length):
            #expect(value == longBoundary)
            #expect(length == 100)
        default:
            Issue.record("Expected boundaryTooLong error")
        }
    }

    @Test
    func `missingBoundary error is created`() {
        let error = RFC_2046.MultipartError.missingBoundary

        switch error {
        case .missingBoundary:
            break // Success
        default:
            Issue.record("Expected missingBoundary error")
        }
    }

    @Test
    func `emptyParts error is created`() {
        let error = RFC_2046.MultipartError.emptyParts

        switch error {
        case .emptyParts:
            break // Success
        default:
            Issue.record("Expected emptyParts error")
        }
    }

    @Test
    func `invalidSubtype error is created`() {
        let value: String = "invalid"
        let error = RFC_2046.MultipartError.invalidSubtype(value)

        switch error {
        case .invalidSubtype(let value):
            #expect(value == "invalid")
        default:
            Issue.record("Expected invalidSubtype error")
        }
    }
}

// MARK: - MultipartError Protocol Conformance

@Suite
struct `MultipartError - Equatable` {

    @Test
    func `Same invalidBoundary errors are equal`() {
        let value: String = "test"
        let a = RFC_2046.MultipartError.invalidBoundary(value)
        let b = RFC_2046.MultipartError.invalidBoundary(value)
        #expect(a == b)
    }

    @Test
    func `Different invalidBoundary errors are not equal`() {
        let a = RFC_2046.MultipartError.invalidBoundary("test1" as String)
        let b = RFC_2046.MultipartError.invalidBoundary("test2" as String)
        #expect(a != b)
    }

    @Test
    func `Same boundaryTooLong errors are equal`() {
        let value: String = "test"
        let a = RFC_2046.MultipartError.boundaryTooLong(value, length: 100)
        let b = RFC_2046.MultipartError.boundaryTooLong(value, length: 100)
        #expect(a == b)
    }

    @Test
    func `Different boundaryTooLong errors are not equal`() {
        let value: String = "test"
        let a = RFC_2046.MultipartError.boundaryTooLong(value, length: 100)
        let b = RFC_2046.MultipartError.boundaryTooLong(value, length: 200)
        #expect(a != b)
    }

    @Test
    func `missingBoundary errors are equal`() {
        let a = RFC_2046.MultipartError.missingBoundary
        let b = RFC_2046.MultipartError.missingBoundary
        #expect(a == b)
    }

    @Test
    func `emptyParts errors are equal`() {
        let a = RFC_2046.MultipartError.emptyParts
        let b = RFC_2046.MultipartError.emptyParts
        #expect(a == b)
    }

    @Test
    func `Different error types are not equal`() {
        let a = RFC_2046.MultipartError.emptyParts
        let b = RFC_2046.MultipartError.missingBoundary
        #expect(a != b)
    }

    @Test
    func `invalidSubtype errors are equal`() {
        let value: String = "test"
        let a = RFC_2046.MultipartError.invalidSubtype(value)
        let b = RFC_2046.MultipartError.invalidSubtype(value)
        #expect(a == b)
    }
}

@Suite
struct `MultipartError - Hashable` {

    @Test
    func `Same errors have same hash`() {
        let value: String = "test"
        let a = RFC_2046.MultipartError.invalidBoundary(value)
        let b = RFC_2046.MultipartError.invalidBoundary(value)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `Errors work in Set`() {
        let errors: Set = [
            RFC_2046.MultipartError.emptyParts,
            RFC_2046.MultipartError.missingBoundary,
            RFC_2046.MultipartError.emptyParts  // Duplicate
        ]
        #expect(errors.count == 2)
    }

    @Test
    func `Errors work as Dictionary keys`() {
        var dict: [RFC_2046.MultipartError: String] = [:]
        dict[.emptyParts] = "Empty parts"
        dict[.missingBoundary] = "Missing boundary"

        #expect(dict[.emptyParts] == "Empty parts")
        #expect(dict[.missingBoundary] == "Missing boundary")
    }
}

@Suite
struct `MultipartError - Sendable conformance` {

    @Test
    func `Errors can be sent across concurrency domains`() async {
        let error = RFC_2046.MultipartError.emptyParts

        let result = await Task {
            error
        }.value

        #expect(result == .emptyParts)
    }

    @Test
    func `Errors with associated values can be sent`() async {
        let value: String = "test"
        let error = RFC_2046.MultipartError.invalidBoundary(value)

        let result = await Task {
            error
        }.value

        #expect(result == RFC_2046.MultipartError.invalidBoundary(value))
    }
}

// MARK: - Error Throwing

@Suite
struct `MultipartError - Error throwing in practice` {

    @Test
    func `Boundary initialization throws invalidBoundary`() {
        #expect(throws: Error.self) {
            _ = try RFC_2046.Boundary("")
        }
    }

    @Test
    func `Boundary initialization throws boundaryTooLong`() {
        let longValue = String(repeating: "x", count: 71)
        #expect(throws: Error.self) {
            _ = try RFC_2046.Boundary(longValue)
        }
    }

    @Test
    func `Multipart initialization throws emptyParts`() {
        #expect(throws: Error.self) {
            _ = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [],
                boundary: "test"
            )
        }
    }

    @Test
    func `Catching specific error type`() {
        do {
            _ = try RFC_2046.Boundary("")
            Issue.record("Expected error to be thrown")
        } catch RFC_2046.MultipartError.invalidBoundary(let value) {
            #expect(value == "")
        } catch {
            Issue.record("Expected RFC_2046.MultipartError.invalidBoundary")
        }
    }

    @Test
    func `Catching any MultipartError`() {
        do {
            _ = try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [],
                boundary: "test"
            )
            Issue.record("Expected error to be thrown")
        } catch let error as RFC_2046.MultipartError {
            #expect(error == .emptyParts)
        } catch {
            Issue.record("Expected RFC_2046.MultipartError")
        }
    }
}

// MARK: - Error Messages and Debugging

@Suite
struct `MultipartError - Error information` {

    @Test
    func `invalidBoundary error contains boundary value`() {
        let value: String = "bad boundary "
        let error = RFC_2046.MultipartError.invalidBoundary(value)
        let description = String(describing: error)

        // The error should contain information about the invalid boundary
        #expect(description.contains("invalidBoundary"))
    }

    @Test
    func `boundaryTooLong error contains length information`() {
        let value: String = "test"
        let error = RFC_2046.MultipartError.boundaryTooLong(value, length: 100)
        let description = String(describing: error)

        #expect(description.contains("boundaryTooLong"))
    }

    @Test
    func `Error can be pattern matched`() {
        let error: RFC_2046.MultipartError = .emptyParts

        let message: String
        switch error {
        case .emptyParts:
            message = "Parts array is empty"
        case .missingBoundary:
            message = "Boundary is missing"
        case .invalidBoundary:
            message = "Boundary is invalid"
        case .boundaryTooLong:
            message = "Boundary is too long"
        case .invalidSubtype:
            message = "Subtype is invalid"
        }

        #expect(message == "Parts array is empty")
    }

    @Test
    func `All error cases are covered`() {
        let value: String = "test"
        let errors: [RFC_2046.MultipartError] = [
            .emptyParts,
            .missingBoundary,
            .invalidBoundary(value),
            .boundaryTooLong(value, length: 100),
            .invalidSubtype(value)
        ]

        #expect(errors.count == 5)
    }
}
