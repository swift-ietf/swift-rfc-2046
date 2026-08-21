import RFC_2045
import Testing

@testable import RFC_2046

extension RFC_2046.BodyPart.Headers {
    @Suite
    struct `Edge Case` {

        @Test
        func `Folded Content-Type header is unfolded and parsed`() throws {
            let raw = [Byte](
                "Content-Type: multipart/mixed;\r\n boundary=abc123\r\n".utf8
            )
            let headers = try RFC_2046.BodyPart.Headers(ascii: raw)
            #expect(headers.contentType?.type == "multipart")
            #expect(headers.contentType?.subtype == "mixed")
            #expect(headers.contentType?.parameters[.boundary] == "abc123")
        }

        @Test
        func `Tab-folded custom header unfolds into one header`() throws {
            let raw = [Byte](
                "X-Custom: first\r\n\tsecond\r\nContent-Transfer-Encoding: 7bit\r\n".utf8
            )
            let headers = try RFC_2046.BodyPart.Headers(ascii: raw)
            #expect(headers.contentTransferEncoding == .sevenBit)
            #expect(headers.custom.count == 1)
        }
    }
}
