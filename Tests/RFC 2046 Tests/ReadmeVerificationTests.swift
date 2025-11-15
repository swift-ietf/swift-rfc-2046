import Foundation
import RFC_2045
import RFC_2183
import Testing

@testable import RFC_2046

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("Example from README: Multipart/Alternative (Text + HTML)")
    func exampleMultipartAlternative() throws {
        // From README lines 50-62
        let multipart = try RFC_2046.Multipart.alternative(
            textContent: "Hello, World!",
            htmlContent: "<h1>Hello, World!</h1>"
        )

        let contentType = multipart.contentType.headerValue
        #expect(contentType.hasPrefix("multipart/alternative; boundary="))

        let body = multipart.render()
        #expect(body.contains("Hello, World!"))
        #expect(body.contains("<h1>Hello, World!</h1>"))
    }

    @Test("Example from README: Custom Multipart Messages")
    func exampleCustomMultipart() throws {
        // From README lines 66-86
        let textPart = RFC_2046.BodyPart(
            contentType: .textPlainUTF8,
            transferEncoding: .sevenBit,
            text: "Plain text version"
        )

        let htmlPart = RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            transferEncoding: .sevenBit,
            text: "<p>HTML version</p>"
        )

        let multipart = try RFC_2046.Multipart(
            subtype: .alternative,
            parts: [textPart, htmlPart],
            boundary: "my-custom-boundary"
        )

        #expect(multipart.boundary == "my-custom-boundary")
        #expect(multipart.parts.count == 2)
    }

    @Test("Example from README: Multipart/Mixed (With Attachments)")
    func exampleMultipartMixed() throws {
        // From README lines 88-111
        let contentPart = RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            text: "<h1>Email with attachment</h1>"
        )

        let attachmentPart = RFC_2046.BodyPart(
            headers: RFC_2046.BodyPart.Headers(
                contentDisposition: .attachment(filename: "document.pdf"),
                contentType: .applicationPDF(name: "document.pdf"),
                contentTransferEncoding: .base64
            ),
            text: "<base64-encoded-pdf-content>"
        )

        let multipart = try RFC_2046.Multipart.mixed(
            parts: [contentPart, attachmentPart]
        )

        #expect(multipart.subtype == RFC_2046.Multipart.Subtype.mixed)
        #expect(multipart.parts.count == 2)
    }

    @Test("Example from README: Rendering Messages")
    func exampleRendering() throws {
        // From README - rendering multipart message
        let multipart = try RFC_2046.Multipart.alternative(
            textContent: "Hello",
            htmlContent: "<h1>Hello</h1>"
        )

        let contentType = multipart.contentType.headerValue
        #expect(contentType.hasPrefix("multipart/alternative; boundary="))

        let body = multipart.render()
        #expect(body.contains("Hello"))
        #expect(body.contains("<h1>Hello</h1>"))
        #expect(body.contains("--"))  // Contains boundary markers
    }
}
