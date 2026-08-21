import RFC_2045
import Testing

@testable import RFC_2046

extension RFC_2046.Multipart {
    @Suite
    struct Unit {

        @Test
        func `Init rejects additional parameter values that cannot be represented`() throws {
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("x")
            )
            let boundary = try RFC_2046.Boundary("b")
            #expect(throws: RFC_2046.Multipart.Error.self) {
                _ = try RFC_2046.Multipart(
                    subtype: .related,
                    parts: [part],
                    boundary: boundary,
                    additionalParameters: [
                        .init(rawValue: "start"): "x\r\nX-Injected: evil"
                    ]
                )
            }
        }

        @Test
        func `ContentType is built structurally with parameters intact`() throws {
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("x")
            )
            let boundary = try RFC_2046.Boundary("simple boundary")
            let multipart = try RFC_2046.Multipart(
                subtype: .related,
                parts: [part],
                boundary: boundary,
                additionalParameters: [.init(rawValue: "type"): "text/plain; not really"]
            )
            let contentType = multipart.contentType
            #expect(contentType.type == "multipart")
            #expect(contentType.subtype == "related")
            #expect(contentType.parameters[.boundary] == "simple boundary")
            #expect(contentType.parameters[.init(rawValue: "type")] == "text/plain; not really")
        }
    }
}
