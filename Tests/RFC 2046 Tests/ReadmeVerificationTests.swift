import Foundation
import RFC_2045
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
            headers: [
                "Content-Type": "application/pdf; name=\"document.pdf\"",
                "Content-Transfer-Encoding": "base64",
                "Content-Disposition": "attachment; filename=\"document.pdf\"",
            ],
            text: "<base64-encoded-pdf-content>"
        )

        let multipart = try RFC_2046.Multipart.mixed(
            parts: [contentPart, attachmentPart]
        )

        #expect(multipart.subtype == .mixed)
        #expect(multipart.parts.count == 2)
    }

    @Test("Example from README: Multipart/Form-Data (HTTP File Upload)")
    func exampleFormData() throws {
        // From README lines 157-179
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])  // Minimal JPEG header

        let formData = try RFC_2046.Multipart.formData(
            fields: [
                "username": "john_doe",
                "email": "john@example.com",
            ],
            files: [
                try .init(
                    fieldName: "avatar",
                    filename: "photo.jpg",
                    contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
                    transferEncoding: .base64,
                    content: imageData
                )
            ]
        )

        let contentType = formData.contentType.headerValue
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))

        let body = formData.render()
        #expect(body.contains("john_doe"))
        #expect(body.contains("john@example.com"))
        #expect(body.contains("photo.jpg"))
    }
}
