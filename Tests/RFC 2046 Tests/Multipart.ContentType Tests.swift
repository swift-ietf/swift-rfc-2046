import RFC_2045
import RFC_2046
import Testing

extension RFC_2046.Multipart {
    @Suite
    struct `Content-Type of a multipart body` {

        @Test
        func `Init rejects additional parameter values that cannot be represented`() throws {
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
                content: RFC_2046.BodyPart.Content("x")
            )
            let boundary = try RFC_2046.Boundary("b")
            let start = try RFC_2045.Parameter.Name("start")
            #expect(throws: RFC_2046.Multipart.Error.self) {
                _ = try RFC_2046.Multipart(
                    subtype: .related,
                    parts: [part],
                    boundary: boundary,
                    additionalParameters: [start: "x\r\nX-Injected: evil"]
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
            let typeParameter = try RFC_2045.Parameter.Name("type")
            let multipart = try RFC_2046.Multipart(
                subtype: .related,
                parts: [part],
                boundary: boundary,
                additionalParameters: [typeParameter: "text/plain; not really"]
            )
            let contentType = multipart.contentType
            #expect(contentType.type == "multipart")
            #expect(contentType.subtype == "related")
            #expect(contentType.parameters[.boundary] == "simple boundary")
            #expect(contentType.parameters[typeParameter] == "text/plain; not really")
        }
    }
}
