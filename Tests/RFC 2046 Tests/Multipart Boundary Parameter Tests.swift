import RFC_2045
import RFC_2046
import Testing

@Suite
struct `Multipart boundary parameter` {
    private static let part = RFC_2046.BodyPart(
        headers: RFC_2046.BodyPart.Headers(contentType: .textPlainUTF8),
        content: RFC_2046.BodyPart.Content("x")
    )

    @Test
    func `an additional boundary parameter is refused`() throws {
        let boundary = try RFC_2046.Boundary("real")
        #expect(throws: RFC_2046.Multipart.Error.self) {
            try RFC_2046.Multipart(
                subtype: .mixed,
                parts: [Self.part],
                boundary: boundary,
                additionalParameters: [.boundary: "other"]
            )
        }
    }

    @Test
    func `the content type always names the boundary that separates the parts`() throws {
        let multipart = RFC_2046.Multipart(
            __unchecked: (),
            subtype: .mixed,
            parts: [Self.part],
            boundary: try RFC_2046.Boundary("real"),
            preamble: nil,
            epilogue: nil,
            additionalParameters: [.boundary: "other"]
        )
        #expect(multipart.contentType.parameters[.boundary] == "real")
    }
}
