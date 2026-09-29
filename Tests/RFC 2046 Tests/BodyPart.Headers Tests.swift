import RFC_2045
import RFC_2046
import RFC_2183
import RFC_5322
import Testing

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
    func `Initialization with all parameters`() throws {
        let headers = try RFC_2046.BodyPart.Headers(
            contentDisposition: .inline(),
            contentType: .textPlainUTF8,
            contentTransferEncoding: .sevenBit,
            custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
        )

        #expect(headers.contentDisposition == .inline())
        #expect(headers.contentType == .textPlainUTF8)
        #expect(headers.contentTransferEncoding == .sevenBit)
        #expect(headers.custom.count == 1)
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
    func `Initialization with custom headers only`() throws {
        let headers = try RFC_2046.BodyPart.Headers(
            custom: [
                RFC_5322.Header(name: .init("X-Custom-1"), value: .init("value1")),
                RFC_5322.Header(name: .init("X-Custom-2"), value: .init("value2")),
            ]
        )

        #expect(headers.contentDisposition == nil)
        #expect(headers.contentType == nil)
        #expect(headers.contentTransferEncoding == nil)
        #expect(headers.custom.count == 2)
    }

    @Test
    func `Custom headers are addressable by name`() throws {
        let headers = try RFC_2046.BodyPart.Headers(
            custom: [RFC_5322.Header(name: .init("X-Custom"), value: .init("value"))]
        )

        #expect(try headers.custom[.init("X-Custom")] == "value")
    }
}

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
    func `Headers with different custom values are not equal`() throws {
        let a = try RFC_2046.BodyPart.Headers(custom: [
            RFC_5322.Header(name: .init("X-A"), value: .init("1"))
        ])
        let b = try RFC_2046.BodyPart.Headers(custom: [
            RFC_5322.Header(name: .init("X-A"), value: .init("2"))
        ])
        #expect(a != b)
    }
}
